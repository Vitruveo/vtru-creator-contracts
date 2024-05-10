const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");

// npx hardhat run --network testnet scripts/upgradeAssetRegistry.js
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network testnet 0x3925b92Ef881A9B0465Ef1ebDEE5D6C0ED4d464b
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
  const network = hre.network.name.toLowerCase(); 
  const AssetRegistry = await ethers.getContractFactory("AssetRegistry");
  const contract = network == 'mainnet' ? ''.toLowerCase() : '0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB'.toLowerCase();
  const assetRegistry = await upgrades.upgradeProxy(contract, AssetRegistry);
  await assetRegistry.waitForDeployment();
  console.log("AssetRegistry deployed to:", await assetRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });