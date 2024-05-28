const hre = require("hardhat");
const config = require("../../vault-config.json");

// npx hardhat run --network testnet scripts/factory/upgrade.js 

async function main() {
  const network = hre.network.name.toLowerCase(); 
  const Vault = await hre.ethers.getContractFactory("CreatorVault");
  const vaultTargetV1 = await Vault.deploy();
  const vaultTargetAddress = await vaultTargetV1.getAddress();
  console.log(`target address: ${vaultTargetAddress}`)

  const VaultFactory = await hre.ethers.getContractFactory("CreatorVaultFactory");
  const contract = config.creatorVaultFactory[network];
  const factory = await VaultFactory.attach(contract);

  const VaultBeacon = await hre.ethers.getContractFactory("CreatorVaultBeacon");
  const vaultBeacon = VaultBeacon.attach(await factory.getBeacon());
  const before = await vaultBeacon.implementation();
  await vaultBeacon.update(vaultTargetAddress);
  await sleep(7000);

  console.log('\n\nBEFORE/AFTER', before, await vaultBeacon.implementation(),'\n\n');

  async function sleep(millis) {
    return new Promise(resolve => setTimeout(resolve, millis));
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