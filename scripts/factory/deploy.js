const { ethers } = require("hardhat");

// npx hardhat run --network testnet scripts/factory/deploy.js 
// npx hardhat verify --contract contracts/CreatorVaultFactory.sol:CreatorVaultFactory --network testnet --constructor-args scripts/factory/arguments.js 0x6bc8DbdC3754812b245667e7E309D7EC979087Ed
// npx hardhat verify --contract contracts/CreatorVault.sol:CreatorVault --network testnet 0xB8B691a47BC0Cff87272DC2060Ae96798c810d23


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