const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  if (!deployer) throw new Error("Set DEPLOYER_PRIVATE_KEY in .env for a testnet deployment.");
  console.log("Deploying test-only contracts from:", deployer.address);
  const Token = await ethers.getContractFactory("MockCollateral");
  const token = await Token.deploy();
  await token.waitForDeployment();
  const Exchange = await ethers.getContractFactory("FluxoraPerps");
  const exchange = await Exchange.deploy(await token.getAddress(), deployer.address);
  await exchange.waitForDeployment();
  console.log(JSON.stringify({
    network: "sepolia",
    deployer: deployer.address,
    collateralToken: await token.getAddress(),
    fluxoraPerps: await exchange.getAddress(),
    warning: "Mock collateral and trusted-publisher contract; testnet demo only."
  }, null, 2));
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
