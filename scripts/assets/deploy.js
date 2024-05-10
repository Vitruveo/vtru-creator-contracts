const { ethers, upgrades } = require("hardhat");

// npx hardhat run --network testnet scripts/assets/deploy.js
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network testnet 0xE2ee7AD1D7e058dB97905B016BEA4046bc9b11b6
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
  const AssetRegistry = await ethers.getContractFactory("AssetRegistry");
  const assetRegistry = await upgrades.deployProxy(AssetRegistry, {initializer: 'initialize'});
  await assetRegistry.waitForDeployment();
  console.log("AssetRegistry deployed to:", await assetRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });