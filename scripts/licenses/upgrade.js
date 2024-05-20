const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");

// npx hardhat run --network testnet scripts/licenses/upgrade.js
// npx hardhat verify --contract contracts/LicenseRegistry.sol:LicenseRegistry --network testnet 0x66C0f10C3A15c9EcDe395355db1f1dA9Ab29bf13
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
  const network = hre.network.name.toLowerCase(); 
  const LicenseRegistry = await ethers.getContractFactory("LicenseRegistry");
  const contract = network == 'mainnet' ? ''.toLowerCase() : '0x17146243e22183D8554dC334b85dece1dbC0b63a'.toLowerCase();
  const licenseRegistry = await upgrades.upgradeProxy(contract, LicenseRegistry);
  await licenseRegistry.waitForDeployment();
  console.log("LicenseRegistry deployed to:", await licenseRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });