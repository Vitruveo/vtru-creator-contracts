const { ethers } = require("hardhat");

// npx hardhat run --network testnet scripts/factory/deploy.js 
// npx hardhat verify --contract contracts/CreatorVaultFactory.sol:CreatorVaultFactory --network testnet --constructor-args scripts/factory/arguments.js 0x13E813Fa69e2674aD442e9d3e9EEE60b8bDC42e5

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