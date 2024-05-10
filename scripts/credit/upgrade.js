const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");

// npx hardhat run --network testnet scripts/credit/upgrade.js 
// npx hardhat verify --contract contracts/CollectorCredit.sol:CollectorCredit --network testnet 0x2921f3c02f4c6b1bbd35c5b8dea666f78a9d5919

async function main() {
  const network = hre.network.name.toLowerCase(); 
  const CollectorCreditV2 = await ethers.getContractFactory("CollectorCredit");
  const contract = network == 'mainnet' ? '0x5c7421fcCA16C685cEC5aaFf745a9a6BDf75Ba06'.toLowerCase() : '0x2921f3c02f4c6b1BbD35c5B8deA666F78A9D5919'.toLowerCase();
  const collectorCreditV2 = await upgrades.upgradeProxy(contract, CollectorCreditV2);
  await collectorCreditV2.waitForDeployment();
  console.log("CollectorCredit deployed to:", await collectorCreditV2.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });