const { ethers } = require("hardhat");

// npx hardhat run --network testnet scripts/factory/deploy.js 
// npx hardhat verify --contract contracts/CreatorVaultFactory.sol:CreatorVaultFactory --network testnet --constructor-args scripts/factory/arguments.js 0x7eA2E62810e9d867D682fF78D52B1d0A9B82F870
// npx hardhat verify --contract contracts/CreatorVault.sol:CreatorVault --network testnet 0xBF300Af66e994Cf2f3123464d22A2184a73a9A7F


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