const { ethers, upgrades } = require("hardhat");

// npx hardhat run --network testnet scripts/licenses/deploy.js
// npx hardhat verify --contract contracts/LicenseRegistry.sol:LicenseRegistry --network testnet 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
// npx hardhat verify --contract contracts/LicenseRegistry.sol:LicenseRegistry --network mainnet 0x79AfA7Dd7AE14F9C5255f1AC9c8A2b8bEb2CcCD1

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