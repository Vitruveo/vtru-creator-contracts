const { ethers } = require("hardhat");

// npx hardhat run --network testnet scripts/factory/deploy.js 
// npx hardhat verify --contract contracts/CreatorVaultFactory.sol:CreatorVaultFactory --network testnet --constructor-args scripts/factory/arguments.js 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707
// npx hardhat verify --contract contracts/CreatorVault.sol:CreatorVault --network testnet 0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9
// npx hardhat verify --contract contracts/CreatorVault.sol:CreatorVault --network mainnet 0x51129c0424f979e7f18251eD31BEa156b2Bc1772
// npx hardhat verify --contract contracts/CreatorVaultFactory.sol:CreatorVaultFactory --network mainnet --constructor-args scripts/factory/arguments.js 0xDFda76C704515d19C737C54cFf523E45ab01d90A


async function main() {

  const Vault = await ethers.getContractFactory("CreatorVault");
  //const vaultTargetV1 = await Vault.deploy();
  //console.log(`CreatorVault address: ${await vaultTargetV1.getAddress()}`)

  const VaultFactory = await hre.ethers.getContractFactory("CreatorVaultFactory");
//  const factory = await VaultFactory.deploy(await vaultTargetV1.getAddress(), "0x79AfA7Dd7AE14F9C5255f1AC9c8A2b8bEb2CcCD1"); // CreatorVault, LicenseRegistry
  const factory = await VaultFactory.deploy("0x475aF7F0F3FF49C45D34b1Db35218FC17EA50F09", "0x79AfA7Dd7AE14F9C5255f1AC9c8A2b8bEb2CcCD1"); // CreatorVault, LicenseRegistry
  console.log(`CreatorVaultFactory address: ${await factory.getAddress()}`)
 
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});