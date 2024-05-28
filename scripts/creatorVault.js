const { ethers, JsonRpcProvider, Wallet, Contract } = require("ethers");

const config = require("../vault-config.json");
require("dotenv").config();

const isTestNet = process.env.NEXT_PUBLIC_TESTNET == "true";

const network = isTestNet ? 'testnet' : 'mainnet';

const rpc = isTestNet ? process.env.TESTNET_RPC : process.env.MAINNET_RPC;
const provider = new JsonRpcProvider(rpc);
const studio = new Wallet(process.env.STUDIO_PRIVATE_KEY, provider);
console.log('Studio Address', studio.address);

const creatorVault = (address) => new Contract(address, config.creatorVault.abi, studio);


(async () => {
 
    var args = process.argv.slice(2);

    try {
    
        const docVaultAddress = ethers.getAddress("0xd1d17c154ced745d58654db862e1ae8641f5fc34");
        const nikVaultAddress = ethers.getAddress("0x0894afb41c0ac7c76c6c9bf5ab48e392b31068e1"); //Wallet: 0xABBA32cF845256A4284cdbA91D82C96CbB13dc59

        const vaultAddress = nikVaultAddress;
        const creatorVault = (address) => new Contract(address, config.creatorVault.abi, studio);
        const myVault = creatorVault(vaultAddress);
        console.log('BALANCE', vaultAddress, ethers.formatEther(await provider.getBalance(vaultAddress)));
        console.log('WALLETS', await myVault.getVaultWallets());
       // console.log(await myVault.addVaultWallet(ethers.getAddress("0xABBA32cF845256A4284cdbA91D82C96CbB13dc59")));
        //await sleep(6000);
        //console.log('WALLETS', await myVault.getVaultWallets());
       console.log(await myVault.claimStudio(ethers.getAddress("0xABBA32cF845256A4284cdbA91D82C96CbB13dc59")));


    async function sleep(millis) {
        return new Promise(resolve => setTimeout(resolve, millis));
     }
    } catch(e) {
        console.log(e);
    }

    async function sleep(millis) {
        return new Promise(resolve => setTimeout(resolve, millis));
    }
})();
