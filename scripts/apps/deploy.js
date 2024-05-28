const { ethers, upgrades } = require("hardhat");

// npx hardhat run --network testnet scripts/apps/deploy.js
// npx hardhat verify --contract contracts/AppRegistry.sol:AppRegistry --network testnet 0xD78030AB82C7Ae472700124d935d4F4aC08e469F
// npx hardhat verify --contract contracts/AppRegistry.sol:AppRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
  const AppRegistry = await ethers.getContractFactory("AppRegistry");
  const appRegistry = await upgrades.deployProxy(AppRegistry, {initializer: 'initialize'});
  await appRegistry.waitForDeployment();
  console.log("AppRegistry deployed to:", await appRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });