const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");
const config = require("../../vault-config.json");

// npx hardhat run --network testnet scripts/assets/upgrade.js
// npx hardhat run --network mainnet scripts/assets/upgrade.js
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network testnet 0x5b21D8C455283d7AB039dE551d0D5b7C9F692649
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network mainnet 0xeBF19B6f5c3f99BC5F75137D1113F506C7f6799E

async function main() {
  const network = hre.network.name.toLowerCase(); 
  const AssetRegistry = await ethers.getContractFactory("AssetRegistry");
  const contract = config.assetRegistry[network];
  const assetRegistry = await upgrades.upgradeProxy(contract, AssetRegistry);
  await assetRegistry.waitForDeployment();
  console.log("AssetRegistry deployed to:", await assetRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });