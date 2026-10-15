// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title FluxoraPerps
/// @notice Experimental isolated-margin perpetuals sandbox. NOT audited or production-ready.
/// @dev Uses a trusted publisher for mark prices; no matching engine or decentralized oracle.
///      Funding is a simple admin-published cumulative index. Test with mock collateral only.
interface IERC20Fluxora {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract FluxoraPerps {
    uint256 public constant WAD = 1e18;
    uint256 public constant BPS = 10_000;
    address public immutable admin;
    address public publisher;
    IERC20Fluxora public immutable collateralToken;
    uint256 public maxLeverageBps = 50_000;
    uint256 public maxNotionalUsdE6 = 50_000e6;
    uint256 public maxPriceAge = 90;
    uint256 public maxDeviationBps = 500;
    uint256 public maintenanceMarginBps = 500;
    uint256 public nextPositionId = 1;
    uint256 public nextReceiptId = 1;
    mapping(address => uint256) public collateral;
    mapping(bytes32 => Price) public prices;
    mapping(bytes32 => int256) public cumulativeFundingBps;
    mapping(uint256 => Position) public positions;
    mapping(address => uint256[]) private traderPositions;

    struct Price { uint192 valueE6; uint64 updatedAt; }
    struct Position {
        address trader; bytes32 market; bool isLong; bool open;
        uint128 quantityE6; uint128 entryPriceE6; uint128 marginE6;
        uint16 leverageBps; int256 fundingIndexAtOpen;
    }

    event CollateralDeposited(address indexed trader, uint256 amount);
    event CollateralWithdrawn(address indexed trader, uint256 amount);
    event PricePublished(bytes32 indexed market, uint256 priceE6, uint256 updatedAt);
    event FundingIndexPublished(bytes32 indexed market, int256 cumulativeBps);
    event GuardedReceipt(uint256 indexed receiptId, address indexed trader, bytes32 indexed market, bool accepted, uint8 reason, uint256 notionalE6, uint256 markPriceE6);
    event PositionOpened(uint256 indexed positionId, address indexed trader, bytes32 indexed market, bool isLong, uint256 notionalE6, uint256 marginE6, uint256 entryPriceE6);
    event PositionClosed(uint256 indexed positionId, address indexed trader, int256 pnlE6, int256 fundingE6, uint256 returnedMarginE6);
    event PositionLiquidated(uint256 indexed positionId, address indexed liquidator, int256 pnlE6, int256 fundingE6);

    error Unauthorized(); error InvalidConfig(); error InsufficientCollateral(); error InvalidPosition(); error TransferFailed();
    modifier onlyAdmin() { if (msg.sender != admin) revert Unauthorized(); _; }
    modifier onlyPublisher() { if (msg.sender != publisher) revert Unauthorized(); _; }

    constructor(address token, address initialPublisher) {
        if (token == address(0) || initialPublisher == address(0)) revert InvalidConfig();
        admin = msg.sender; collateralToken = IERC20Fluxora(token); publisher = initialPublisher;
    }
    function setPublisher(address next) external onlyAdmin { if (next == address(0)) revert InvalidConfig(); publisher = next; }
    function setPolicy(uint256 leverageBps, uint256 notionalE6, uint256 age, uint256 deviationBps, uint256 maintenanceBps) external onlyAdmin {
        if (leverageBps < BPS || leverageBps > 100_000 || notionalE6 == 0 || age == 0 || deviationBps > 2_000 || maintenanceBps < 100 || maintenanceBps >= BPS) revert InvalidConfig();
        maxLeverageBps = leverageBps; maxNotionalUsdE6 = notionalE6; maxPriceAge = age; maxDeviationBps = deviationBps; maintenanceMarginBps = maintenanceBps;
    }
    function deposit(uint256 amount) external {
        if (amount == 0 || !collateralToken.transferFrom(msg.sender, address(this), amount)) revert TransferFailed();
        collateral[msg.sender] += amount; emit CollateralDeposited(msg.sender, amount);
    }
    function withdraw(uint256 amount) external {
        if (amount == 0 || amount > collateral[msg.sender] || !collateralToken.transfer(msg.sender, amount)) revert InsufficientCollateral();
        collateral[msg.sender] -= amount; emit CollateralWithdrawn(msg.sender, amount);
    }
    function publishPrice(bytes32 market, uint192 valueE6, uint64 updatedAt) external onlyPublisher {
        if (valueE6 == 0 || updatedAt > block.timestamp) revert InvalidConfig();
        prices[market] = Price(valueE6, updatedAt); emit PricePublished(market, valueE6, updatedAt);
    }
    function publishFundingIndex(bytes32 market, int256 cumulativeBps) external onlyPublisher {
        cumulativeFundingBps[market] = cumulativeBps; emit FundingIndexPublished(market, cumulativeBps);
    }
    /// reason: 0 accepted, 1 invalid/deviation, 2 missing/stale oracle, 3 leverage/margin, 4 notional cap.
    function openPosition(bytes32 market, bool isLong, uint128 notionalE6, uint16 leverageBps, uint192 clientReferenceE6) external returns (uint256 receiptId, uint256 positionId) {
        Price memory p = prices[market]; uint8 reason;
        if (notionalE6 == 0 || clientReferenceE6 == 0 || leverageBps < BPS) reason = 1;
        else if (p.updatedAt == 0 || block.timestamp - p.updatedAt > maxPriceAge) reason = 2;
        else if (leverageBps > maxLeverageBps || uint256(notionalE6) * BPS / leverageBps > collateral[msg.sender]) reason = 3;
        else if (notionalE6 > maxNotionalUsdE6) reason = 4;
        else {
            uint256 high = p.valueE6 > clientReferenceE6 ? p.valueE6 : clientReferenceE6;
            uint256 low = p.valueE6 > clientReferenceE6 ? clientReferenceE6 : p.valueE6;
            if ((high - low) * BPS / low > maxDeviationBps) reason = 1;
        }
        receiptId = nextReceiptId++;
        emit GuardedReceipt(receiptId, msg.sender, market, reason == 0, reason, notionalE6, p.valueE6);
        if (reason != 0) return (receiptId, 0); // Persist a rejection receipt without reverting.
        uint256 marginE6 = uint256(notionalE6) * BPS / leverageBps;
        collateral[msg.sender] -= marginE6;
        positionId = nextPositionId++;
        positions[positionId] = Position(msg.sender, market, isLong, true, notionalE6, p.valueE6, uint128(marginE6), leverageBps, cumulativeFundingBps[market]);
        traderPositions[msg.sender].push(positionId);
        emit PositionOpened(positionId, msg.sender, market, isLong, notionalE6, marginE6, p.valueE6);
    }
    function closePosition(uint256 positionId) external {
        Position storage pos = positions[positionId];
        if (!pos.open || pos.trader != msg.sender) revert InvalidPosition();
        Price memory p = _freshPrice(pos.market);
        (int256 pnl, int256 funding) = _pnlAndFunding(pos, p.valueE6);
        int256 equity = int256(uint256(pos.marginE6)) + pnl - funding;
        pos.open = false;
        uint256 returned = equity > 0 ? uint256(equity) : 0;
        collateral[msg.sender] += returned;
        emit PositionClosed(positionId, msg.sender, pnl, funding, returned);
    }
    function liquidate(uint256 positionId) external {
        Position storage pos = positions[positionId];
        if (!pos.open) revert InvalidPosition();
        Price memory p = _freshPrice(pos.market);
        (int256 pnl, int256 funding) = _pnlAndFunding(pos, p.valueE6);
        int256 equity = int256(uint256(pos.marginE6)) + pnl - funding;
        uint256 notionalNow = uint256(pos.quantityE6) * p.valueE6 / pos.entryPriceE6;
        if (equity > 0 && uint256(equity) * BPS > notionalNow * maintenanceMarginBps) revert InvalidPosition();
        pos.open = false;
        emit PositionLiquidated(positionId, msg.sender, pnl, funding);
    }
    function getTraderPositions(address trader) external view returns (uint256[] memory) { return traderPositions[trader]; }
    function _freshPrice(bytes32 market) internal view returns (Price memory p) {
        p = prices[market]; if (p.updatedAt == 0 || block.timestamp - p.updatedAt > maxPriceAge) revert InvalidConfig();
    }
    function _pnlAndFunding(Position storage pos, uint256 markE6) internal view returns (int256 pnl, int256 funding) {
        int256 delta = int256(markE6) - int256(uint256(pos.entryPriceE6));
        if (!pos.isLong) delta = -delta;
        pnl = delta * int256(uint256(pos.quantityE6)) / int256(uint256(pos.entryPriceE6));
        funding = int256(uint256(pos.quantityE6)) * (cumulativeFundingBps[pos.market] - pos.fundingIndexAtOpen) / int256(BPS);
    }
}
