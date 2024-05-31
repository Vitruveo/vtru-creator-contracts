const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");
const config = require("../../vault-config.json");

// npx hardhat run --network testnet scripts/licenses/upgrade.js
// npx hardhat run --network mainnet scripts/licenses/upgrade.js
// npx hardhat verify --contract contracts/LicenseRegistry.sol:LicenseRegistry --network testnet 0x1e8F9510e9A599204Db4dA3f352a7e73111f050C
// npx hardhat verify --contract contracts/LicenseRegistry.sol:LicenseRegistry --network mainnet 0x79AfA7Dd7AE14F9C5255f1AC9c8A2b8bEb2CcCD1

async function main() {
  const network = hre.network.name.toLowerCase(); 
  const LicenseRegistry = await ethers.getContractFactory("LicenseRegistry");
  const contract = config.licenseRegistry[network];
  const licenseRegistry = await upgrades.upgradeProxy(contract, LicenseRegistry);
  await licenseRegistry.waitForDeployment();
  console.log("LicenseRegistry deployed to:", await licenseRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });