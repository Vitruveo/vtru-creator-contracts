const { ethers } = require("hardhat");

// npx hardhat run --network testnet scripts/factory/deploy.js 
// npx hardhat verify --contract contracts/CreatorVaultFactory.sol:CreatorVaultFactory --network testnet --constructor-args scripts/factory/arguments.js 0xdBe0A90c88a95828B756F08d0178fDd02c362ADc

async function main() {

  const Vault = await ethers.getContractFactory("CreatorVault");
  const vaultTargetV1 = await Vault.deploy();
  console.log(`CreatorVault address: ${await vaultTargetV1.getAddress()}`)

  const VaultFactory = await hre.ethers.getContractFactory("CreatorVaultFactory");
  const factory = await VaultFactory.deploy(await vaultTargetV1.getAddress(), "0xC6BCaada8ee54B19a715E24e439CCa89aD18fD13");
  console.log(`CreatorVaultFactory address: ${await factory.getAddress()}`)
 
 // const consignedContractsAddress = '0xbB2fFce67f15c66bB947421f93E61f3da9F1aaEC';
//  await factory.setAssetRegistryContract(consignedContractsAddress);
//  await factory.setStudioAccount('0x88Eb3738dc7B13773F570458cbC932521431FeA7');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});