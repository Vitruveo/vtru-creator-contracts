const { ethers } = require("hardhat");

// npx hardhat run --network testnet scripts/factory/deploy.js 
// npx hardhat verify --contract contracts/CreatorVaultFactory.sol:CreatorVaultFactory --network testnet --constructor-args scripts/factory/arguments.js 0x1EB7275117CE93622E20b4D56351ea2e9806bEf1

async function main() {

  const Vault = await ethers.getContractFactory("CreatorVault");
  const vaultTargetV1 = await Vault.deploy();
  console.log(`CreatorVault address: ${await vaultTargetV1.getAddress()}`)

  const VaultFactory = await hre.ethers.getContractFactory("CreatorVaultFactory");
  const factory = await VaultFactory.deploy(await vaultTargetV1.getAddress(), "0xC6BCaada8ee54B19a715E24e439CCa89aD18fD13");
  console.log(`CreatorVaultFactory address: ${await factory.getAddress()}`)
 
  await factory.createVault("ABCD", "Hello", "HELLO", ["0xbB2fFce67f15c66bB947421f93E61f3da9F1aaEC"]);
  console.log("getVaultCount", await factory.getVaultCount());
  await factory.createVault("ABCD1", "Hello", "HELLO", ["0x88Eb3738dc7B13773F570458cbC932521431FeA7"]);
  console.log("getVaultCount", await factory.getVaultCount());
  console.log("isVaultByKey", await factory.isVaultByKey("ABCD"));
  console.log("getVaultByKey", await factory.getVaultByKey("ABCD"));
  console.log("getVaultAtIndex", await factory.getVaultAtIndex(0));
  console.log("getKeyAtIndex", await factory.getKeyAtIndex(0));
  console.log("getVaultCount", await factory.getVaultCount());
  console.log("getVaultByWallet", await factory.getVaultByWallet('0xbB2fFce67f15c66bB947421f93E61f3da9F1aaEC'));
 // const consignedContractsAddress = '0xbB2fFce67f15c66bB947421f93E61f3da9F1aaEC';
//  await factory.setAssetRegistryContract(consignedContractsAddress);
//  await factory.setStudioAccount('0x88Eb3738dc7B13773F570458cbC932521431FeA7');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});