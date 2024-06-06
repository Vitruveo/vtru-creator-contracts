const { ethers, JsonRpcProvider, Wallet, Contract } = require("ethers");
const path = require("path");
const fse = require("fs-extra");

const config = require("../vault-config.json");
const data = require("./fixvaults.json");

require("dotenv").config();

const isTestNet = false; //process.env.NEXT_PUBLIC_TESTNET == "true";

const network = isTestNet ? 'testnet' : 'mainnet';

const rpc = isTestNet ? process.env.TESTNET_RPC : process.env.MAINNET_RPC;
const provider = new JsonRpcProvider(rpc);
const corenft = new Wallet(process.env.CORE_PRIVATE_KEY, provider);
const studioProd = new Wallet(process.env.STUDIO_MAIN_PRIVATE_KEY, provider);
const colnft = new Wallet(process.env.COLLECTOR_PRIVATE_KEY, provider);

const col = new Contract(config.collectorCredit[network], config.collectorCredit.abi, colnft);

const assetRegistryContract = new Contract(config.assetRegistry[network], config.assetRegistry.abi, studioProd);
const licenseRegistryContract = new Contract(config.licenseRegistry[network], config.licenseRegistry.abi, studioProd);
const creatorVaultFactory = new Contract(config.creatorVaultFactory[network], config.creatorVaultFactory.abi, corenft);
const creatorVault = (address) => new Contract(address, config.creatorVault.abi, studioProd);


(async () => {
 
    try {

        // GET VAULT INFO
        // const vaults = await creatorVaultFactory.getVaultBatch(0,151);
        // const targets = [];
        // let count = 0;
        // for(let v=0; v<vaults.length; v++) {
        //     const vaultAddress = vaults[v];
        //     const vault = creatorVault(vaultAddress);
        //     try {
        //         const tokens = await vault.currentSupply();
        //         if (Number(tokens) > 0) {
        //             const balance = Number(await provider.getBalance(vaultAddress))/10**18
        //             console.log(v, vaultAddress, await vault.name(), await vault.vaultBalance(), balance, balance < 99 ? "**************" : "");
        //             count++;
        //             targets.push({ vault: vaultAddress, balance, buyer: await vault.ownerOf(1) });
        //         }    
        //     } catch(e) {
        //         console.log(`Error for ${vaultAddress}`);
        //     }
        // };

       // console.log(JSON.stringify(targets));


        // RECOVER VTRU and burn token
        /*
            {
            '0x4830de42068B5bDbE558f7ed032FD7A4Ad12c381': 1,
            '0x23fc63f385DbFDc59b93205CEB97e19D98B0dA9E': 13,
            '0xc242343d77d079eBDD39F2c213E021c115e40599': 18,
            '0xC6F60Deb5C488fD06F76823C8dEfcB82E2974015': 4,
            '0x05F00778e905FE62693f5c6A15DC0B310D603D1e': 19,
            '0xa1Ea38b4A23f7E7e3741c9613df980799f7711Ba': 8,
            '0xBe022b7854aBBbfF4f9e0112499d38D431212aa0': 3,
            '0x325af93Cf0941fd73E2aBC36a20c8178e9d87FD1': 7,
            '0x279bc70bC870f55546639924A00e1B1E02f3b61d': 2,
            '0x3f97b22AC09Adc699D2727d0Fe15b2C28126f04d': 4,
            '0x4DD28221a7E48f47E508e8e5C217Fa3CDB36fF4D': 1,
            '0x0612BA65Ea9074FB4d064b192038D823fD057f46': 2
            }
        */
            
        // const coreNft = '0xAC51c04Cb72A5D0F56D71Baf3E2F2B28e6426922';
        // const tokens = [1];         
        // //const vault = creatorVault('0x9F17a6A21745c559763C71037850AF55356AE410');

        //await vault.addVaultWallet(coreNft);
        //await sleep(5000);
        // console.log(await vault.fundsAvailableBlockNumber());
        // console.log('BEFORE',await vault.vaultBalance());
        // console.log(await vault.claimStudio(coreNft))
        // await sleep(5000);
        // console.log('AFTER',await vault.vaultBalance());
        


        // const info = await vault.getTokenInfo(1);
        // data[i].assetKey = info[0];
        // data[i].licenseInstanceId = Number(info[1]);
        // const instance = await licenseRegistryContract.getLicenseInstance(data[i].licenseInstanceId);
        // data[i].licenseId = Number(instance[2]);

            let counter = 0;
            let buyers = {};
        for(let i=0;i<data.length;i++) {
            const item = data[i];
            try {
                await col.grantCreditNFT(1, item.buyer, 0, 15);
                await sleep(4000);
        // const vault = creatorVault(item.vault);
        // const ti = await vault.ownerOf(1);
        //         console.log(ti)
                //await sleep(5000);
                //const lic = await licenseRegistryContract.getTokens(item.buyer);
 // const lic = await licenseRegistryContract.unregisterTokens(item.buyer, [1]);
 // await sleep(5000);
//                counter += lic.length;
                //const asset = await assetRegistryContract.getAsset(item.assetKey);
                
                   // console.log(lic);
                    //console.log(lic);
                //    await assetRegistryContract.revokeLicense(item.licenseId, item.buyer);
                //    await sleep(5000);
                 //}
            } catch(e) {
                console.log(`Error ${item.vault}`);
                console.log(e);
            }
            console.log(counter)
        };
        //const jsonPath = path.resolve(__dirname, 'fixvaults.json');
       // fse.writeJSONSync(jsonPath, data, { spaces: 2 });
       
        // recover VTRU
        // decrement token counter
        // delete token
       //function recoveryStudio(address account, uint[] memory tokenIds) 

    } catch(e) {
        console.log(e);
    }
    async function sleep(millis) {
        return new Promise(resolve => setTimeout(resolve, millis));
    }
})();
