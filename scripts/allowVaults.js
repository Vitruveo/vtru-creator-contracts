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
    "665db8ca46ec49bbdafb84a8",
    "65f6cb9a57bab1a729d90704",
    "65eb15063fb79934ec457e1b",
    "65eb1ac83fb79934ec457e1f",
    "65f8bb0257bab1a729d9078c",
    "6606f6df59e94e78747e1fd8",
    "65f8864057bab1a729d9077d",
    "65eb6e2b3fb79934ec457e2e",
    "65eb7cdc3fb79934ec457e3c",
    "65eb8cbc3fb79934ec457e44",
    "65eba1ef3fb79934ec457e45",
    "65ec1b2e3fb79934ec457e48",
    "65ec694c3fb79934ec457e4c",
    "65ec7ed63fb79934ec457e50",
    "65ef70523fb79934ec457e68",
    "65ef9c0407fb7c9bc19c4594",
    "65ef9d7207fb7c9bc19c4596",
    "65efa3c807fb7c9bc19c4599",
    "65f005d307fb7c9bc19c459b",
    "65f05c1907fb7c9bc19c45b0",
    "65f0a4aa07fb7c9bc19c45b9",
    "65f0a6fe07fb7c9bc19c45ba",
    "663452a93e3abae4cedb7873",
    "6634e1ba3e3abae4cedb7877",
    "65f1849607fb7c9bc19c45c3",
    "65f1d5ee07fb7c9bc19c45c7",
    "65f1da4007fb7c9bc19c45c9",
    "65f2d633f44c703f83221f8f",
    "65f2e57df44c703f83221f90",
    "65f2ef63f44c703f83221f92",
    "65f34cc5f44c703f83222307",
    "65f43d7157bab1a729d905fc",
    "65f4816d57bab1a729d90600",
    "65f483c057bab1a729d90606",
    "65f4841357bab1a729d90609",
    "65f484a557bab1a729d9060b",
    "65f484ea57bab1a729d9060c",
    "65f488cf57bab1a729d90619",
    "65f4890d57bab1a729d9061c",
    "65f48c9f57bab1a729d90621",
    "65f490a557bab1a729d90626",
    "65f497a957bab1a729d9062b",
    "65f4993257bab1a729d9062e",
    "65f49a6257bab1a729d90631",
    "65f49eb257bab1a729d90636",
    "65f4a78657bab1a729d9063b",
    "65f4ab5a57bab1a729d90640",
    "65f4aea657bab1a729d90643",
    "65f4b1ae57bab1a729d90645",
    "66363803482f2dc87d801f8a",
    "6637e15f482f2dc87d801f8f",
    "663e8d9bb4c45b7b9f2c8bf0",
    "663f9b9db4c45b7b9f2c8c03",
    "6643a8d74ec5211f0bca3e4e",
    "6643bfa54ec5211f0bca3e64",
    "65f4b40957bab1a729d90648",
    "65f4c5bc57bab1a729d9064e",
    "65f4c5ef57bab1a729d9064f",
    "65f4c80b57bab1a729d90653",
    "65f4cdbd57bab1a729d9065a",
    "65f4e29757bab1a729d90664",
    "65f4f01657bab1a729d90668",
    "65f5269b57bab1a729d9066c",
    "65f527dc57bab1a729d9066e",
    "65f53fd957bab1a729d90675",
    "65f54f7257bab1a729d9067c",
    "65f552c357bab1a729d9067d",
    "65f581ab57bab1a729d9068f",
    "65f5ad1b57bab1a729d9069e",
    "65f5b50e57bab1a729d906a4",
    "65f5bd8257bab1a729d906a8",
    "65f5e60d57bab1a729d906ca",
    "65f5e6b657bab1a729d906cb",
    "65f608c757bab1a729d906d2",
    "65f60bab57bab1a729d906d6",
    "65f61c3e57bab1a729d906df",
    "65f61d0757bab1a729d906e0",
    "65f627b157bab1a729d906e3",
    "65f6323757bab1a729d906e8",
    "65f6330357bab1a729d906ea",
    "65f67c8b57bab1a729d906f0",
    "65f68ff957bab1a729d906f4",
    "65f6905857bab1a729d906f5",
    "65f6a8b957bab1a729d906fc",
    "65f6acec57bab1a729d90700",
    "65f6e56557bab1a729d9070d",
    "65f6fd1957bab1a729d9071b",
    "65f7032957bab1a729d90720",
    "65f707dd57bab1a729d90724",
    "65f7197b57bab1a729d9072a",
    "65f7335857bab1a729d9072f",
    "65f76c2c57bab1a729d90732",
    "65f76fd457bab1a729d90736",
    "65f7924b57bab1a729d90740",
    "65f7a2e057bab1a729d90744",
    "65f7ae1157bab1a729d90747",
    "65f7b52057bab1a729d90748",
    "65f7c81357bab1a729d9074c",
    "65f83a0057bab1a729d90761",
    "65f841a157bab1a729d90764",
    "65f8449957bab1a729d90767",
    "65f84ff757bab1a729d9076c",
    "65f86e6057bab1a729d90775",
    "65f87a1957bab1a729d90777",
    "65f87de057bab1a729d90779",
    "65f891d757bab1a729d9077f",
    "65f93bf157bab1a729d9079c",
    "65f9622657bab1a729d9079f",
    "65f9782f57bab1a729d907a1",
    "65f982e157bab1a729d907a4",
    "65f9835457bab1a729d907a6",
    "65f99f3c57bab1a729d907ab",
    "65faab1857bab1a729d907be",
    "65fae8e957bab1a729d907c3",
    "65fc998959e94e78747e1f52",
    "65fcab3f59e94e78747e1f55",
    "65fd71a159e94e78747e1f5e",
    "65fe12b359e94e78747e1f7a",
    "65fe1c0959e94e78747e1f7c",
    "65edb2f03fb79934ec457e54",
    "65f7014e57bab1a729d9071d",
    "65f7788957bab1a729d90738",
    "65f8822d57bab1a729d9077b",
    "65f9848257bab1a729d907a7",
    "65fa1d2157bab1a729d907b5",
    "65fef48f59e94e78747e1f8a",
    "660033bb59e94e78747e1f94",
    "65ffb91a59e94e78747e1f8f",
    "660115a259e94e78747e1f9d",
    "6601538b59e94e78747e1f9f",
    "6602721c59e94e78747e1fad",
    "660276ef59e94e78747e1faf",
    "6602d11759e94e78747e1fb3",
    "6602f51859e94e78747e1fb6",
    "66042c7359e94e78747e1fbf",
    "66047a2b59e94e78747e1fc4",
    "6604af7c59e94e78747e1fc7",
    "6604b02f59e94e78747e1fc8",
    "66054feb59e94e78747e1fca",
    "6605bd1a59e94e78747e1fcf",
    "6606c56259e94e78747e1fd6",
    "6607b21f59e94e78747e1fe2",
    "6607f6c759e94e78747e1fe4",
    "6608048359e94e78747e1fe6",
    "66082b7c59e94e78747e1feb",
    "6609b07259e94e78747e1ff2",
    "660a706759e94e78747e1ffb",
    "660ae4b059e94e78747e1fff",
    "660bb3f959e94e78747e2000",
    "660c84a559e94e78747e2007",
    "660c85e259e94e78747e2008",
    "660c8de859e94e78747e2009",
    "660f465759e94e78747e201c",
    "66101a9259e94e78747e2020",
    "6612b30859e94e78747e2028",
    "6614d58059e94e78747e2030",
    "661acb1659e94e78747e204a",
    "661adc0e59e94e78747e204b",
    "661b545c59e94e78747e2051",
    "661bbe1959e94e78747e2053",
    "661d39a459e94e78747e2057",
    "661fdaec59e94e78747e2060",
    "6620d77059e94e78747e2062",
    "662171a759e94e78747e2064",
    "662534d80903ef02962fa97b",
    "66256a540903ef02962fa981",
    "6626703b0903ef02962fa98f",
    "6628874ad479422d88c09102",
    "662a5b871c535be3ce34315d",
    "662e6bca3e3abae4cedb743d",
    "662fc8e73e3abae4cedb7445",
    "6632efcf3e3abae4cedb7858"
];

(async () => {
 
    try {

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
            results.push({assetKey, vaultAddress, name});
            console.log(assetKey, vaultAddress, name, blocked, vaultBalance, vaultBalance);
            //await vault.setBlocked(true);
            //await sleep(100);
        }

        console.log({total, hasBalance, isBlocked});
        // console.log('Balances', hasBalance, 'Sales', hasSale);
        const jsonPath = path.resolve(__dirname, '..', 'friends.json');
        fse.writeJSONSync(jsonPath, results, { spaces: 2 });
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


