const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FluxoraPerps (prototype)", function () {
  async function setup() {
    const [admin, trader, other] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("MockCollateral");
    const token = await Token.deploy();
    const Exchange = await ethers.getContractFactory("FluxoraPerps");
    const exchange = await Exchange.deploy(await token.getAddress(), admin.address);
    await token.mint(trader.address, 10_000_000_000n);
    await token.connect(trader).approve(await exchange.getAddress(), ethers.MaxUint256);
    await exchange.connect(trader).deposit(5_000_000_000n);
    const market = ethers.encodeBytes32String("ETHUSDT");
    const now = (await ethers.provider.getBlock("latest")).timestamp;
    await exchange.publishPrice(market, 3_000_000_000n, now);
    return { admin, trader, other, token, exchange, market };
  }
  it("escrows collateral and opens a position after onchain checks", async function () {
    const { trader, exchange, market } = await setup();
    const before = await exchange.collateral(trader.address);
    await expect(exchange.connect(trader).openPosition(market, true, 900_000_000n, 30_000, 3_000_000_000n))
      .to.emit(exchange, "GuardedReceipt").withArgs(1, trader.address, market, true, 0, 900_000_000n, 3_000_000_000n);
    expect(await exchange.collateral(trader.address)).to.equal(before - 300_000_000n);
    expect((await exchange.positions(1)).open).to.equal(true);
  });
  it("records a rejected over-cap order without opening a position", async function () {
    const { trader, exchange, market } = await setup();
    await expect(exchange.connect(trader).openPosition(market, true, 60_000_000_000n, 30_000, 3_000_000_000n))
      .to.emit(exchange, "GuardedReceipt").withArgs(1, trader.address, market, false, 3, 60_000_000_000n, 3_000_000_000n);
    expect(await exchange.nextPositionId()).to.equal(1);
  });
  it("closes a position and returns remaining isolated margin", async function () {
    const { trader, exchange, market } = await setup();
    await exchange.connect(trader).openPosition(market, true, 900_000_000n, 30_000, 3_000_000_000n);
    await exchange.publishPrice(market, 3_300_000_000n, (await ethers.provider.getBlock("latest")).timestamp);
    await expect(exchange.connect(trader).closePosition(1)).to.emit(exchange, "PositionClosed");
    expect((await exchange.positions(1)).open).to.equal(false);
    expect(await exchange.collateral(trader.address)).to.be.greaterThan(4_700_000_000n);
  });
  it("does not allow a non-publisher to publish prices", async function () {
    const { other, exchange, market } = await setup();
    await expect(exchange.connect(other).publishPrice(market, 1_000_000n, 1)).to.be.revertedWithCustomError(exchange, "Unauthorized");
  });
});
