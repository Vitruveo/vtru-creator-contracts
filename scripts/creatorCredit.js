const { ethers, JsonRpcProvider, Wallet, Contract } = require("ethers");

const config = require("../vault-config.json");
require("dotenv").config();

const isTestNet = process.env.NEXT_PUBLIC_TESTNET == "true";
const network = isTestNet ? 'testnet' : 'mainnet';

const rpc = isTestNet ? process.env.TESTNET_RPC : process.env.MAINNET_RPC;
const provider = new JsonRpcProvider(rpc);
const signer = new Wallet(process.env.STUDIO_PRIVATE_KEY, provider);
const CreatorVault = (address) => new Contract(address, config.creatorVault.abi, signer);




(async () => {

    try {

        async function addCredits(address) {
            const creatorVault = CreatorVault(address);
            await creatorVault.addCreatorCredits(1);
        }

        addCredits('0xc3819778bafa6ed57bc192ecf5a58f9e2e37be4b');

        } catch(e) {
            console.log(e);
        }


})();
