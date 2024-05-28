const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");
const config = require("../../vault-config.json");

// npx hardhat run --network testnet scripts/apps/upgrade.js
// npx hardhat verify --contract contracts/AppRegistry.sol:AppRegistry --network testnet 0x9f6844abe0A68D203Bca17fc366D07Cbe8bF5e7A
// npx hardhat verify --contract contracts/AppRegistry.sol:AppRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
  const network = hre.network.name.toLowerCase(); 
  const AppRegistry = await ethers.getContractFactory("AppRegistry");
  const contract = config.appRegistry[network];
  const appRegistry = await upgrades.upgradeProxy(contract, AppRegistry);
  await appRegistry.waitForDeployment();
  console.log("AppRegistry deployed to:", await appRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });