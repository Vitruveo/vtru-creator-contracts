const { ethers, upgrades } = require("hardhat");
const hre = require("hardhat");
const path = require("path");
const fse = require("fs-extra");
const subProcess = require('child_process')

// npx hardhat run --network testnet scripts/updateBatch.js
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network testnet 0xABA06E4A2Eb17C686Fc67C81d26701D9b82e3a41
// npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network mainnet 0x7eF4199309B0C80227e439Af25A4C1bb1caB61dB

async function main() {
    const isMainNet = hre.network.name == 'mainnet';

    const AssetRegistry = await ethers.getContractFactory("AssetRegistry");
    const assetRegistryAbi = AssetRegistry.interface.formatJson();

    const MediaRegistry = await ethers.getContractFactory("MediaRegistry");
    const mediaRegistryAbi = MediaRegistry.interface.formatJson();

    const LicenseRegistry = await ethers.getContractFactory("LicenseRegistry");
    const licenseRegistryAbi = LicenseRegistry.interface.formatJson();

    const CreatorVault = await ethers.getContractFactory("CreatorVault");
    const creatorVaultAbi = CreatorVault.interface.formatJson();

    const CreatorVaultFactory = await hre.ethers.getContractFactory("CreatorVaultFactory");
    const creatorVaultFactoryAbi = CreatorVaultFactory.interface.formatJson();

    const CollectorCredit = await hre.ethers.getContractFactory("CollectorCredit");
    const collectorCreditAbi = CollectorCredit.interface.formatJson();

    const jsonPath = path.resolve(__dirname, '..', 'vault-config.json');

    if (fse.existsSync(jsonPath)) {
        const vaultConfig = fse.readJSONSync(jsonPath);
      //  console.log(vaultConfig); return;
        vaultConfig.assetRegistry.abi = JSON.parse(assetRegistryAbi);
        vaultConfig.mediaRegistry.abi = JSON.parse(mediaRegistryAbi);
        vaultConfig.licenseRegistry.abi = JSON.parse(licenseRegistryAbi);
        vaultConfig.creatorVault.abi = JSON.parse(creatorVaultAbi);
        vaultConfig.creatorVaultFactory.abi = JSON.parse(creatorVaultFactoryAbi);
        vaultConfig.collectorCredit.abi = JSON.parse(collectorCreditAbi);
        fse.writeJSONSync(jsonPath, vaultConfig, { spaces: 2 });



    console.log(`\nConfig written to ${jsonPath}\n`);
 
    subProcess.exec(`npx hardhat verify --contract contracts/AssetRegistry.sol:AssetRegistry --network ${hre.network.name} ${vaultConfig.assetRegistry[hre.network.name]}`, (err, stdout, stderr) => {
        console.log(`The stdout Buffer from shell: ${stdout.toString()}`)
        console.log(`The stderr Buffer from shell: ${stderr.toString()}`)
    });

    subProcess.exec(`npx hardhat verify --contract contracts/MediaRegistry.sol:MediaRegistry --network ${hre.network.name} ${vaultConfig.mediaRegistry[hre.network.name]}`, (err, stdout, stderr) => {
        console.log(`The stdout Buffer from shell: ${stdout.toString()}`)
        console.log(`The stderr Buffer from shell: ${stderr.toString()}`)
    });

    subProcess.exec(`npx hardhat verify --contract contracts/CreatorVaultFactory.sol:CreatorVaultFactory --network ${hre.network.name} --constructor-args scripts/factory/arguments.js ${vaultConfig.creatorVaultFactory[hre.network.name]}`, (err, stdout, stderr) => {
        console.log(`The stdout Buffer from shell: ${stdout.toString()}`)
        console.log(`The stderr Buffer from shell: ${stderr.toString()}`)
    });

    subProcess.exec(`npx hardhat verify --contract contracts/LicenseRegistry.sol:LicenseRegistry --network ${hre.network.name} ${vaultConfig.licenseRegistry[hre.network.name]}`, (err, stdout, stderr) => {
        console.log(`The stdout Buffer from shell: ${stdout.toString()}`)
        console.log(`The stderr Buffer from shell: ${stderr.toString()}`)
    });

    subProcess.exec(`npx hardhat verify --contract contracts/CreatorVault.sol:CreatorVault --network ${hre.network.name} ${vaultConfig.creatorVault[hre.network.name]}`, (err, stdout, stderr) => {
        console.log(`The stdout Buffer from shell: ${stdout.toString()}`)
        console.log(`The stderr Buffer from shell: ${stderr.toString()}`)
    });

    }
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});