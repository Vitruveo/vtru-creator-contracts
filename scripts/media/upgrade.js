const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");
const config = require("../../vault-config.json");

// npx hardhat run --network testnet scripts/media/upgrade.js
// npx hardhat verify --contract contracts/MediaRegistry.sol:MediaRegistry --network testnet 0x8e6A921744335994283046449522b914d0B06E7d
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
  const network = hre.network.name.toLowerCase(); 
  const MediaRegistry = await ethers.getContractFactory("MediaRegistry");
  const contract = config.mediaRegistry[network];
  const mediaRegistry = await upgrades.upgradeProxy(contract, MediaRegistry);
  await mediaRegistry.waitForDeployment();
  console.log("MediaRegistry deployed to:", await mediaRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });