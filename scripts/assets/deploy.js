const { ethers, upgrades } = require("hardhat");

// npx hardhat run --network testnet scripts/assets/deploy.js
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network testnet 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network mainnet 0xeBF19B6f5c3f99BC5F75137D1113F506C7f6799E

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