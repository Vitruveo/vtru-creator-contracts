const hre = require("hardhat");

async function main() {
  const Vault = await hre.ethers.getContractFactory("CreatorVault");
  const vaultTargetV1 = await Vault.deploy();
  console.log(`target address: ${await vaultTargetV1.getAddress()}`)

  const VaultFactory = await hre.ethers.getContractFactory("CreatorVaultFactory");
  const factory = await VaultFactory.deploy(await vaultTargetV1.getAddress(), (await hre.ethers.Wallet.createRandom()).address);

  const vaults = [];
  const wallets = [];

  for (let i = 0; i < 20; i++) {
    const vaultId = i;
    const currentWallets = [];
    for (let w=0; w<4; w++) {
      wallets.push(await hre.ethers.Wallet.createRandom());
      currentWallets.push(wallets[wallets.length-1].address);
    }
    await factory.createVault(`${i}`, `Vault ${i}`, "VAULT", currentWallets);
    const vaultAddress = await factory.getVaultByKey(`${i}`);
    const vault = Vault.attach(vaultAddress)
    vaults.push(vault);
    console.log(vault.target, await vault.version(), await vault.getCreatorCredits())
  }


  const Vault2 = await hre.ethers.getContractFactory("CreatorVault2");
  const vaultTargetV2 = await Vault2.deploy();
  //console.log(`target address: ${await vaultTargetV2.getAddress()}`)

  const VaultBeacon = await hre.ethers.getContractFactory("CreatorVaultBeacon");
  const vaultBeacon = VaultBeacon.attach(await factory.getBeacon());
  const before = await vaultBeacon.implementation();
  await vaultBeacon.update(await vaultTargetV2.getAddress());
  console.log('\n\nBEFORE/AFTER', before, await vaultBeacon.implementation(),'\n\n');

  for (let i = 0; i < 20; i++) {
    const vault = vaults[i];
    console.log(vault.target, await vault.version(), await vault.getCreatorCredits())
  }




  const Vault3 = await hre.ethers.getContractFactory("CreatorVault3");
  const vaultTargetV3 = await Vault3.deploy();
  //console.log(`target address: ${await vaultTargetV2.getAddress()}`)

  const VaultBeacon3 = await hre.ethers.getContractFactory("CreatorVaultBeacon");
  const vaultBeacon3 = VaultBeacon3.attach(await factory.getBeacon());
  const before1 = await vaultBeacon3.implementation();
  await vaultBeacon3.update(await vaultTargetV3.getAddress());
  console.log('\n\nBEFORE/AFTER', before1, await vaultBeacon3.implementation(),'\n\n');

  for (let i = 0; i < 20; i++) {
    const vault = vaults[i];
    console.log(vault.target, await vault.version(), await vault.getCreatorCredits())
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });