const { ethers, upgrades } = require("hardhat");

// npx hardhat run --network testnet scripts/licenses/deploy.js
// npx hardhat verify --contract contracts/LicenseRegistry.sol:LicenseRegistry --network testnet 0xC6BCaada8ee54B19a715E24e439CCa89aD18fD13
// npx hardhat verify --contract contracts/LicenseRegistry.sol:LicenseRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
  const LicenseRegistry = await ethers.getContractFactory("LicenseRegistry");
  const licenseRegistry = await upgrades.deployProxy(LicenseRegistry, {initializer: 'initialize'});
  await licenseRegistry.waitForDeployment();
  console.log("LicenseRegistry deployed to:", await licenseRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });