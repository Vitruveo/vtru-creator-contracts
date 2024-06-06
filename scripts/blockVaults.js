const { ethers, JsonRpcProvider, Wallet, Contract } = require("ethers");
const path = require("path");
const fse = require("fs-extra");

const config = require("../vault-config.json");
const data = require("./badvaults.json");

require("dotenv").config();


const network = hre.network.name;
const isTestNet = network == 'testnet';

const rpc = isTestNet ? process.env.TESTNET_RPC : process.env.MAINNET_RPC;
const provider = new JsonRpcProvider(rpc);
const corenft = new Wallet(process.env.CORE_PRIVATE_KEY, provider);
const studio = isTestNet ? new Wallet(process.env.STUDIO_PRIVATE_KEY, provider) : new Wallet(process.env.STUDIO_MAIN_PRIVATE_KEY, provider);
const colnft = new Wallet(process.env.COLLECTOR_PRIVATE_KEY, provider);

const col = new Contract(config.collectorCredit[network], config.collectorCredit.abi, colnft);

const assetRegistryContract = new Contract(config.assetRegistry[network], config.assetRegistry.abi, studio);
const licenseRegistryContract = new Contract(config.licenseRegistry[network], config.licenseRegistry.abi, studio);
const creatorVaultFactory = new Contract(config.creatorVaultFactory[network], config.creatorVaultFactory.abi, corenft);
const creatorVault = (address) => new Contract(address, config.creatorVault.abi, studio);


(async () => {
 
    try {

        // GET VAULT INFO
        //console.log(await assetRegistryContract.getAddress())
        let hasBalance = 0;
        let hasSale = 0;
        let review = [];
      //  for(let v=0; v<data.length; v++) {
        console.log
            const vaultAddress = '0x54A8feDe4c4158EeBd601F4955dfDdA2E0d3554f'; //data[v]; 
            const vault = await creatorVault(vaultAddress);
            const vaultBalance = Number(await vault.vaultBalance())/10**18;
            const name = await vault.name();
            console.log('BEFORE', vaultAddress, name, await vault.isBlocked(), vaultBalance, await vault.fundsAvailableBlockNumber());
            //await vault.setBlocked(true);
            //await sleep(100);
      //  }

        // console.log('Balances', hasBalance, 'Sales', hasSale);
        // const jsonPath = path.resolve(__dirname, '..', 'review.json');
        // fse.writeJSONSync(jsonPath, review, { spaces: 2 });
        //await vault.blockAndRecoverFundsStudio(studio.address);
        //await sleep(5000);
       // console.log(vaultAddress, studio.address, await vault.name(), await vault.isBlocked(), Number(await provider.getBalance(studio))/10**18, Number(await vault.vaultBalance())/10**18);
       // console.log('tokenURI', atob((await vault.tokenURI(1)).split(',')[1]));
    } catch(e) {
        console.log(e);
    }
    async function sleep(millis) {
        return new Promise(resolve => setTimeout(resolve, millis));
    }
})();
