const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");
const path = require("path");
const fse = require("fs-extra");

// npx hardhat run --network testnet scripts/deployBatch.js
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network testnet 0x6f7b4bEA245d1Dd07ff9662A753a6ad41dc0d197
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
    const isMainNet = hre.network.name == 'mainnet';

    const AssetRegistry = await ethers.getContractFactory("AssetRegistry");
    const assetRegistry = await upgrades.deployProxy(AssetRegistry, { initializer: 'initialize' });
    await assetRegistry.waitForDeployment();
    const assetRegistryAddress = await assetRegistry.getAddress();
    const assetRegistryAbi = AssetRegistry.interface.formatJson();
    console.log("\nAssetRegistry deployed to:", assetRegistryAddress);

    const LicenseRegistry = await ethers.getContractFactory("LicenseRegistry");
    const licenseRegistry = await upgrades.deployProxy(LicenseRegistry, { initializer: 'initialize' });
    await licenseRegistry.waitForDeployment();
    const licenseRegistryAddress = await licenseRegistry.getAddress();
    const licenseRegistryAbi = LicenseRegistry.interface.formatJson();
    console.log("\nLicenseRegistry deployed to:", licenseRegistryAddress);

    const CreatorVault = await ethers.getContractFactory("CreatorVault");
    const creatorVault = await CreatorVault.deploy();
    const creatorVaultAddress = await creatorVault.getAddress();
    const creatorVaultAbi = CreatorVault.interface.formatJson();
    console.log("\nCreatorVault deployed to:", creatorVaultAddress)


    const CreatorVaultFactory = await hre.ethers.getContractFactory("CreatorVaultFactory");
    const creatorVaultFactory = await CreatorVaultFactory.deploy(creatorVaultAddress, licenseRegistryAddress); // CreatorVault, LicenseRegistry
    const creatorVaultFactoryAddress = await creatorVaultFactory.getAddress();
    const creatorVaultFactoryAbi = CreatorVaultFactory.interface.formatJson();
    console.log("\nCreatorVaultFactory deployed to:", creatorVaultFactoryAddress);

    await licenseRegistry.setStudioAccount('0x88Eb3738dc7B13773F570458cbC932521431FeA7');
    await licenseRegistry.setAssetRegistryContract(assetRegistryAddress);
    await licenseRegistry.setCreatorVaultFactoryContract(creatorVaultFactoryAddress);
    await licenseRegistry.setCollectorCreditContract(isMainNet ? '0x5c7421fcCA16C685cEC5aaFf745a9a6BDf75Ba06' : '0x2921f3c02f4c6b1BbD35c5B8deA666F78A9D5919');

    const vaultConfig = {
        assetRegistry: {
            testnet: !isMainNet ? assetRegistryAddress : '',
            mainnet: isMainNet ? assetRegistryAddress : '',
            abi: JSON.parse(assetRegistryAbi)
        },
        licenseRegistry: {
            testnet: !isMainNet ? licenseRegistryAddress : '',
            mainnet: isMainNet ? licenseRegistryAddress : '',
            abi: JSON.parse(licenseRegistryAbi)
        },
        creatorVault: {
            testnet: !isMainNet ? creatorVaultAddress : '',
            mainnet: isMainNet ? creatorVaultAddress : '',
            abi: JSON.parse(creatorVaultAbi)
        },
        creatorVaultFactory: {
            testnet: !isMainNet ? creatorVaultFactoryAddress : '',
            mainnet: isMainNet ? creatorVaultFactoryAddress : '',
            abi: JSON.parse(creatorVaultFactoryAbi)
        }
    }
    fse.writeJSONSync(path.resolve(__dirname, '..', 'vault-config.json'), vaultConfig, { spaces: 2 });
    console.log(`\nConfig written to ${path.resolve(__dirname, '..', 'vault-config.json')}\n`);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});