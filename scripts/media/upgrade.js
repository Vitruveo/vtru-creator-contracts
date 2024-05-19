const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");

// npx hardhat run --network testnet scripts/media/upgrade.js
// npx hardhat verify --contract contracts/MediaRegistry.sol:MediaRegistry --network testnet 0x17146243e22183D8554dC334b85dece1dbC0b63a
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
  const network = hre.network.name.toLowerCase(); 
  const MediaRegistry = await ethers.getContractFactory("MediaRegistry");
  const contract = network == 'mainnet' ? ''.toLowerCase() : '0x17146243e22183D8554dC334b85dece1dbC0b63a'.toLowerCase();
  const mediaRegistry = await upgrades.upgradeProxy(contract, MediaRegistry);
  await mediaRegistry.waitForDeployment();
  console.log("MediaRegistry deployed to:", await mediaRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });