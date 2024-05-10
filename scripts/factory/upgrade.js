const hre = require("hardhat");

async function main() {
  const Vault = await hre.ethers.getContractFactory("CreatorVault");
  const vaultTargetV1 = await Vault.deploy();
  console.log(`target address: ${await vaultTargetV1.getAddress()}`)

  const VaultFactory = await hre.ethers.getContractFactory("CreatorVaultFactory");
  const factory = await VaultFactory.attach('0x4548874059283eC891e2c70f9D313835175D8915');

  const VaultBeacon = await hre.ethers.getContractFactory("CreatorVaultBeacon");
  const vaultBeacon = VaultBeacon.attach(await factory.getBeacon());
  const before = await vaultBeacon.implementation();
  await vaultBeacon.update(await vaultTargetV1.getAddress());
  console.log('\n\nBEFORE/AFTER', before, await vaultBeacon.implementation(),'\n\n');
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });