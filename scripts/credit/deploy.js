const { ethers, upgrades } = require("hardhat");

// npx hardhat run --network testnet scripts/deploycredit.js 

async function main() {
  const CollectorCredit = await ethers.getContractFactory("CollectorCredit");
  const collectorCredit = await upgrades.deployProxy(CollectorCredit, {initializer: 'initialize'});
  await collectorCredit.waitForDeployment();
  console.log("CollectorCredit deployed to:", await collectorCredit.getAddress());
}



main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });