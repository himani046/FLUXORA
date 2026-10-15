// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title FluxoraGuard
/// @notice Educational pre-trade risk gate. NOT a perpetuals exchange.
/// @dev No custody, order matching, funding, position accounting, or liquidation.
///      Price publisher is trusted for this prototype; production needs robust oracle design and audit.
contract FluxoraGuard {
 address public immutable admin;
 address public pricePublisher;
 uint256 public maxLeverageBps=50_000; // 5x
 uint256 public maxNotionalUsdE6=50_000*1e6;
 uint256 public maxPriceAge=90;
 uint256 public maxDeviationBps=500;
 struct PriceObservation { uint192 priceUsdE6; uint64 updatedAt; }
 struct Preview { address trader; uint128 collateralUsdE6; uint128 notionalUsdE6; uint16 leverageBps; bool accepted; uint8 reason; uint64 checkedAt; uint192 oraclePriceUsdE6; }
 mapping(bytes32=>PriceObservation) public prices;
 uint256 public nextPreviewId=1;
 mapping(uint256=>Preview) public previews;
 event PricePublished(bytes32 indexed market,uint256 priceUsdE6,uint256 updatedAt);
 event PreviewRecorded(uint256 indexed previewId,address indexed trader,bool accepted,uint8 reason,uint256 collateralUsdE6,uint256 notionalUsdE6,uint256 oraclePriceUsdE6);
 error Unauthorized(); error InvalidConfiguration();
 constructor(address publisher){if(publisher==address(0))revert InvalidConfiguration();admin=msg.sender;pricePublisher=publisher;}
 modifier onlyAdmin(){if(msg.sender!=admin)revert Unauthorized();_;}
 function setPublisher(address publisher) external onlyAdmin {if(publisher==address(0))revert InvalidConfiguration();pricePublisher=publisher;}
 function setPolicy(uint256 leverageBps,uint256 notionalUsdE6,uint256 ageSeconds,uint256 deviationBps) external onlyAdmin {
  if(leverageBps<10_000||leverageBps>100_000||notionalUsdE6==0||ageSeconds==0||deviationBps>2_000)revert InvalidConfiguration();
  maxLeverageBps=leverageBps;maxNotionalUsdE6=notionalUsdE6;maxPriceAge=ageSeconds;maxDeviationBps=deviationBps;
 }
 function publishPrice(bytes32 market,uint192 priceUsdE6,uint64 updatedAt) external {
  if(msg.sender!=pricePublisher)revert Unauthorized();if(priceUsdE6==0||updatedAt>block.timestamp)revert InvalidConfiguration();prices[market]=PriceObservation(priceUsdE6,updatedAt);emit PricePublished(market,priceUsdE6,updatedAt);
 }
 /// @notice Records a pre-trade preview; it deliberately does NOT open a position.
 /// @dev All USD fields use 6 decimals; reason 0=accepted, 1=invalid/deviation, 2=stale/missing, 3=leverage, 4=notional.
 function preview(bytes32 market,uint128 collateralUsdE6,uint128 notionalUsdE6,uint16 leverageBps,uint192 referencePriceUsdE6) external returns(uint256 previewId){
  PriceObservation memory obs=prices[market];uint8 reason=0;
  if(collateralUsdE6==0||notionalUsdE6==0||referencePriceUsdE6==0||leverageBps<10_000){reason=1;}
  else if(obs.updatedAt==0||block.timestamp-obs.updatedAt>maxPriceAge){reason=2;}
  else if(uint256(leverageBps)>maxLeverageBps||uint256(notionalUsdE6)>uint256(collateralUsdE6)*leverageBps/10_000){reason=3;}
  else if(notionalUsdE6>maxNotionalUsdE6){reason=4;}
  else {uint256 high=obs.priceUsdE6>referencePriceUsdE6?obs.priceUsdE6:referencePriceUsdE6;uint256 low=obs.priceUsdE6>referencePriceUsdE6?referencePriceUsdE6:obs.priceUsdE6;if((high-low)*10_000/low>maxDeviationBps)reason=1;}
  previewId=nextPreviewId++;bool accepted=reason==0;previews[previewId]=Preview(msg.sender,collateralUsdE6,notionalUsdE6,leverageBps,accepted,reason,uint64(block.timestamp),obs.priceUsdE6);
  emit PreviewRecorded(previewId,msg.sender,accepted,reason,collateralUsdE6,notionalUsdE6,obs.priceUsdE6);
 }
}
