const { ethers } = require("hardhat");

// npx hardhat run --network testnet scripts/factory/deploy.js 
// npx hardhat verify --contract contracts/CreatorVaultFactory.sol:CreatorVaultFactory --network testnet --constructor-args scripts/factory/arguments.js 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
// npx hardhat verify --contract contracts/CreatorVault.sol:CreatorVault --network testnet 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9


async function main() {

  const Vault = await ethers.getContractFactory("CreatorVault");
  const vaultTargetV1 = await Vault.deploy();
  console.log(`CreatorVault address: ${await vaultTargetV1.getAddress()}`)

  const VaultFactory = await hre.ethers.getContractFactory("CreatorVaultFactory");
  const factory = await VaultFactory.deploy(await vaultTargetV1.getAddress(), "0xf4E5C69d5Fb2a4168157861D32C18609D3F8f3a7"); // CreatorVault, LicenseRegistry
  console.log(`CreatorVaultFactory address: ${await factory.getAddress()}`)
 
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});