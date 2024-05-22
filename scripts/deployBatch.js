const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");
const path = require("path");
const fse = require("fs-extra");
const subProcess = require('child_process')

// npx hardhat run --network testnet scripts/deployBatch.js
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network testnet 0xABA06E4A2Eb17C686Fc67C81d26701D9b82e3a41
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
    const isMainNet = hre.network.name == 'mainnet';
    const studioAccount = isMainNet ? '0xe48de38701116b127e688701fc7752bd5032e3eb' : '0x88Eb3738dc7B13773F570458cbC932521431FeA7';

    const AssetRegistry = await ethers.getContractFactory("AssetRegistry");
    const assetRegistry = await upgrades.deployProxy(AssetRegistry, { initializer: 'initialize' });
    await assetRegistry.waitForDeployment();
    const assetRegistryAddress = await assetRegistry.getAddress();
    const assetRegistryAbi = AssetRegistry.interface.formatJson();
    console.log("\nAssetRegistry deployed to:", assetRegistryAddress);

    const MediaRegistry = await ethers.getContractFactory("MediaRegistry");
    const mediaRegistry = await upgrades.deployProxy(MediaRegistry, { initializer: 'initialize' });
    await mediaRegistry.waitForDeployment();
    const mediaRegistryAddress = await mediaRegistry.getAddress();
    const mediaRegistryAbi = MediaRegistry.interface.formatJson();
    console.log("\nMediaRegistry deployed to:", mediaRegistryAddress);

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

    const CollectorCredit = await hre.ethers.getContractFactory("CollectorCredit");
    const collectorCreditAddress = isMainNet ? '0x5c7421fcCA16C685cEC5aaFf745a9a6BDf75Ba06' : '0x2921f3c02f4c6b1BbD35c5B8deA666F78A9D5919';
    const collectorCredit =    CollectorCredit.attach(collectorCreditAddress);
    const collectorCreditAbi = CollectorCredit.interface.formatJson();
   // console.log('Collector Credit ABI', collectorCreditAbi);
/*

    Collector Credit:
    redeemUSD requires REEDEMER_ROLE => grant to LicenseRegistry
    updateTransfers requires DEFAULT_ADMIN_ROLE 
    authorizeUprade requires UPGRADER_ROLE

*/

    //await creatorVault.grantRole('0x0000000000000000000000000000000000000000000000000000000000000001', studioAccount);

    const STUDIO_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000001';
    const UPGRADER_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000002';
    const REEDEEMER_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000003';
    const KEEPER_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000004';
    const LICENSOR_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000005';


    await assetRegistry.grantRole(STUDIO_ROLE, studioAccount); // STUDIO_ROLE
    await assetRegistry.grantRole(LICENSOR_ROLE, licenseRegistryAddress); // LICENSOR_ROLE
    await collectorCredit.grantRole(REEDEEMER_ROLE, licenseRegistryAddress); 

    await mediaRegistry.setAssetRegistryContract(assetRegistryAddress);
    await assetRegistry.setMediaRegistryContract(mediaRegistryAddress);

    await licenseRegistry.setStudioAccount(studioAccount);
    await licenseRegistry.setAssetRegistryContract(assetRegistryAddress);
    await licenseRegistry.setCreatorVaultFactoryContract(creatorVaultFactoryAddress);
    await licenseRegistry.setCollectorCreditContract(collectorCreditAddress);
    await licenseRegistry.setUsdVtruExchangeRate(150);

    const vaultConfig = {
        assetRegistry: {
            testnet: !isMainNet ? assetRegistryAddress : '',
            mainnet: isMainNet ? assetRegistryAddress : '',
            abi: JSON.parse(assetRegistryAbi)
        },
        mediaRegistry: {
            testnet: !isMainNet ? mediaRegistryAddress : '',
            mainnet: isMainNet ? mediaRegistryAddress : '',
            abi: JSON.parse(mediaRegistryAbi)
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
        },
        collectorCredit: {
            testnet: !isMainNet ? collectorCreditAddress : '',
            mainnet: isMainNet ? collectorCreditAddress : '',
            abi: JSON.parse(collectorCreditAbi)
        }
    }


    const arguments = `module.exports = [
        "${creatorVaultAddress}", // CreatorVault
        "${licenseRegistryAddress}"  // LicenseRegistry
    ]`;
    const argPath = path.resolve(__dirname, 'factory', 'arguments.js');
    fse.writeFileSync(argPath, arguments);
    console.log(`\nArguments file written to ${argPath}\n`);

    const jsonPath = path.resolve(__dirname, '..', 'vault-config.json');

    if (fse.existsSync(jsonPath)) {
        const existing = fse.readJSONSync(jsonPath);
        if (isMainNet) {
            // Copy over testnet values
            vaultConfig.assetRegisty.testnet = existing.assetRegistry.testnet;
            vaultConfig.mediaRegisty.testnet = existing.mediaRegisty.testnet;
            vaultConfig.licenseRegisty.testnet = existing.licenseRegisty.testnet;
            vaultConfig.creatorVault.testnet = existing.creatorVault.testnet;
            vaultConfig.creatorVaultFactory.testnet = existing.creatorVaultFactory.testnet;
            vaultConfig.collectorCredit.testnet = existing.collectorCredit.testnet;
        }
    }
    fse.writeJSONSync(jsonPath, vaultConfig, { spaces: 2 });

    console.log(`\nConfig written to ${jsonPath}\n`);

    subProcess.exec(`npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network testnet ${assetRegistryAddress}`, (err, stdout, stderr) => {
        console.log(`The stdout Buffer from shell: ${stdout.toString()}`)
        console.log(`The stderr Buffer from shell: ${stderr.toString()}`)
    });

    subProcess.exec(`npx hardhat verify --contract contracts/MediaRegistry.sol:MediaRegistry --network testnet ${mediaRegistryAddress}`, (err, stdout, stderr) => {
        console.log(`The stdout Buffer from shell: ${stdout.toString()}`)
        console.log(`The stderr Buffer from shell: ${stderr.toString()}`)
    });

    subProcess.exec(`npx hardhat verify --contract contracts/CreatorVaultFactory.sol:CreatorVaultFactory --network testnet --constructor-args scripts/factory/arguments.js ${creatorVaultFactoryAddress}`, (err, stdout, stderr) => {
        console.log(`The stdout Buffer from shell: ${stdout.toString()}`)
        console.log(`The stderr Buffer from shell: ${stderr.toString()}`)
    });

    subProcess.exec(`npx hardhat verify --contract contracts/LicenseRegistry.sol:LicenseRegistry --network testnet ${licenseRegistryAddress}`, (err, stdout, stderr) => {
        console.log(`The stdout Buffer from shell: ${stdout.toString()}`)
        console.log(`The stderr Buffer from shell: ${stderr.toString()}`)
    });

    subProcess.exec(`npx hardhat verify --contract contracts/CreatorVault.sol:CreatorVault --network testnet ${creatorVaultAddress}`, (err, stdout, stderr) => {
        console.log(`The stdout Buffer from shell: ${stdout.toString()}`)
        console.log(`The stderr Buffer from shell: ${stderr.toString()}`)
    });

}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});