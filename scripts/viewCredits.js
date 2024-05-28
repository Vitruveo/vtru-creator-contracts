const { ethers, JsonRpcProvider, Wallet, Contract } = require("ethers");

const config = require("../vault-config.json");
require("dotenv").config();

const isTestNet = process.env.NEXT_PUBLIC_TESTNET == "true";

const network = isTestNet ? 'testnet' : 'mainnet';

const rpc = isTestNet ? process.env.TESTNET_RPC : process.env.MAINNET_RPC;
const provider = new JsonRpcProvider(rpc);
const studio = new Wallet(process.env.STUDIO_PRIVATE_KEY, provider);
console.log('Studio Address', studio.address);
const user1 = new Wallet(process.env.USER1_PRIVATE_KEY, provider);
const corenft = new Wallet(process.env.CORE_PRIVATE_KEY, provider);
const user2 = new Wallet(process.env.USER2_PRIVATE_KEY, provider);

const assetRegistryContract = new Contract(config.assetRegistry[network], config.assetRegistry.abi, studio);
const mediaRegistryContract = new Contract(config.mediaRegistry[network], config.mediaRegistry.abi, studio);
const licenseRegistryContract = new Contract(config.licenseRegistry[network], config.licenseRegistry.abi, studio);
const creatorVaultFactory = new Contract(config.creatorVaultFactory[network], config.creatorVaultFactory.abi, studio);
const creatorVault = (address) => new Contract(address, config.creatorVault.abi, studio);
const user1CollectorContract = new Contract(config.collectorCredit[network], config.collectorCredit.abi, user1);
const user2CollectorContract = new Contract(config.collectorCredit[network], config.collectorCredit.abi, user2);
const coreCollectorContract = new Contract(config.collectorCredit[network], config.collectorCredit.abi, corenft);

const STUDIO_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000001';
const UPGRADER_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000002';
const REEDEEMER_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000003';
const KEEPER_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000004';
const LICENSOR_ROLE = '0x0000000000000000000000000000000000000000000000000000000000000005';


(async () => {
 
    try {

    
        console.log('CREDIT', await coreCollectorContract.getAvailableCredits(user2.address));



    } catch(e) {
        console.log(e);
    }
async function sleep(millis) {
        return new Promise(resolve => setTimeout(resolve, millis));
    }
})();
