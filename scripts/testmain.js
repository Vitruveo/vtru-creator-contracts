const { ethers, JsonRpcProvider, Wallet, Contract } = require("ethers");

const config = require("../vault-config.json");
require("dotenv").config();

const isTestNet = false; //process.env.NEXT_PUBLIC_TESTNET == "true";

const network = isTestNet ? 'testnet' : 'mainnet';

const rpc = isTestNet ? process.env.TESTNET_RPC : process.env.MAINNET_RPC;
const provider = new JsonRpcProvider(rpc);
const studioProd = new Wallet(process.env.STUDIO_MAIN_PRIVATE_KEY, provider);
console.log('Studio Prod Address', studioProd.address);

//const assetRegistryContract = new Contract(config.assetRegistry[network], config.assetRegistry.abi, studio);
const licenseRegistryContract = new Contract(config.licenseRegistry[network], config.licenseRegistry.abi, studioProd);

(async () => {
 
    try {

    
       // console.log('CREDIT', await coreCollectorContract.getAvailableCredits(user2.address));

 //      console.log(await assetRegistryContract.getAddress());
//       console.log('ASSET', await assetRegistryContract.getAsset('65eb15063fb79934ec457e1b'));
    //    console.log('ASSET', await licenseRegistryContract.getAsset('65eb15063fb79934ec457e1b'))
    //    console.log('License', await licenseRegistryContract.getAssetLicenses('65eb15063fb79934ec457e1b'))
    //    console.log('Available License', await licenseRegistryContract.getAvailableLicense('65eb15063fb79934ec457e1b', 1, 1));
    /*
    const tokens = await coreCollectorContract.getAvailableCreditTokens('0xC0ee5bb36aF2831baaE1d31f358ccA46dAa6a4e8');
    console.log(tokens);

    let blank = 0;
    let valid = 0;
    tokens[0].forEach((token) => {
        if (Number(token[0]) > 0) {
            valid++;
        } else {
            blank++;
        }
    })
    console.log(valid, blank)
*/
    console.log(await licenseRegistryContract.issueLicenseUsingCreditsStudio('0xABBA32cF845256A4284cdbA91D82C96CbB13dc59','65f8864057bab1a729d9077d', 1, 1, 
                {gasLimit: 20_000_000}));

    //console.log(await provider.getBalance('0x5a6abb7d6539cdcbc1b36ed54862bd74622236a4'));
       // console.log(await creatorVault('0xcba7b4112491a86ee7473e1ac5f577f0d85cae5f').tokenURI(1));

       // Vault Fer = 0xcba7b4112491a86ee7473e1ac5f577f0d85cae5f
       // Vault Doc = 0x9e6e23761499590d5026c608124467c3587336c8
       // Asset Fer = 65eb15063fb79934ec457e1b
       // Asset Doc = 65eb1ac83fb79934ec457e1f
       // Buyer Doc = 0xd07D220d7e43eCa35973760F8951c79dEebe0dcc
       // Buyer Fer = 0xC0ee5bb36aF2831baaE1d31f358ccA46dAa6a4e8
       // Vault Ros = 0x5a6abb7d6539cdcbc1b36ed54862bd74622236a4
       // Asset Ros = 65f8bb0257bab1a729d9078c
       // Buyer Ros = 0xABBA32cF845256A4284cdbA91D82C96CbB13dc59

    } catch(e) {
        console.log(e);
    }
async function sleep(millis) {
        return new Promise(resolve => setTimeout(resolve, millis));
    }
})();
