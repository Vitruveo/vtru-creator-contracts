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

const assetRegistryContract = new Contract(config.assetRegistry[network], config.assetRegistry.abi, studio);
const creatorVaultFactory = new Contract(config.creatorVaultFactory[network], config.creatorVaultFactory.abi, corenft);
const creatorVault = (address) => new Contract(address, config.creatorVault.abi, studio);
const assets = [
    "65f6d3f757bab1a729d90706"
];

(async () => {
 
    try {


        // const vault = await creatorVault('0x0DbDAdebF00dA7f9BDC7Ed810C5E0Ac9CfE38acb');

        // console.log(await vault.getVaultWallets());
        // console.log(await vault.fundsAvailableBlockNumber());
        // console.log(await vault.isTrusted());
        // console.log(await vault.isBlocked());


        // return;

        // GET VAULT INFO
        //console.log(await assetRegistryContract.getAddress())
        let hasBalance = 0;
        let isBlocked = 0;
        let total = 0;
        const results = [];
        for(let v=0; v<assets.length; v++) {
            const assetKey = assets[v];
            const asset = await assetRegistryContract.getAsset(assetKey);
            const vaultAddress = asset[2][0] 
            const vault = await creatorVault(vaultAddress);
            const vaultBalance = Number(await vault.vaultBalance())/10**18;
            const name = await vault.name();
            const blocked = await vault.isBlocked();
            if (blocked) isBlocked++;
            if (vaultBalance > 0) hasBalance++;
            total++;
            const wallets = await vault.getVaultWallets();
            console.log('\n\n\nBEFORE', `${name} Wallets`, `${wallets[0]} (${(Number(await provider.getBalance(wallets[0]))/10**18).toFixed(2)})`, wallets.length > 1 ? `${wallets[1]} (${(Number(await provider.getBalance(wallets[1]))/10**18).toFixed(2)})` : '');
            console.table({ assetKey, vaultAddress, blocked, vaultBalance, vaultBalance});
            //await vault.setBlocked(false);
            // await vault.claimStudio(wallets[0]);
            // console.log('\nAFTER', `${name} Wallets`, `${wallets[0]} (${(Number(await provider.getBalance(wallets[0]))/10**18).toFixed(2)})`, wallets.length > 1 ? `${wallets[1]} (${(Number(await provider.getBalance(wallets[1]))/10**18).toFixed(2)})` : '');
            // console.table({ assetKey, vaultAddress, blocked, vaultBalance, vaultBalance});
            // await sleep(100);
        }

        // console.log({total, hasBalance, isBlocked});
        // // console.log('Balances', hasBalance, 'Sales', hasSale);
        // const jsonPath = path.resolve(__dirname, '..', 'friends.json');
        // fse.writeJSONSync(jsonPath, results, { spaces: 2 });
        // //await vault.blockAndRecoverFundsStudio(studio.address);
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


