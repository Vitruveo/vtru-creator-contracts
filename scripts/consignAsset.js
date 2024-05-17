const { ethers, JsonRpcProvider, Wallet, Contract } = require("ethers");

const config = require("../vault-config.json");
require("dotenv").config();

const isTestNet = process.env.NEXT_PUBLIC_TESTNET == "true";

const network = isTestNet ? 'testnet' : 'mainnet';

const rpc = isTestNet ? process.env.TESTNET_RPC : process.env.MAINNET_RPC;
const provider = new JsonRpcProvider(rpc);
const signer = new Wallet(process.env.STUDIO_PRIVATE_KEY, provider);

const assetRegistryContract = new Contract(config.assetRegistry[network], config.assetRegistry.abi, signer);
const creatorVaultFactory = new Contract(config.creatorVaultFactory[network], config.creatorVaultFactory.abi, signer);
const creatorVault = (address) => new Contract(address, config.creatorVault.abi, signer);

const header = { 
                    title: 'Nik Kalyani', // Title from metadata
                    description: 'Hello world', // Long description from auxiliary view
                    metadataRefId: 9876543, // ID of metadata – currently not implemented
                    metadataXRefId: 'X1234',
                    tokenUri: 'https://www.vitruveo.xyz',
                    status: 2
};

const creator =     {
    username: 'user6000',
    refId: 1234, // Unique ID of creator in database
    xRefId: 'ABCDEFG',
    vault: '', // Creator contract address
    split: 9000 // Split percentage in basis points
}

const emptyCollaborator = {
    username: '',
    vault: ethers.ZeroAddress, // Creator contract address
    xRefId: '',
    refId: 0, 
    split: 0
}

const collaborators = [

                {
                    username: 'user7891',
                    displayName: 'User 7891',
                    refId: 9876, 
                    xRefId: 'WXYZ',
                    vault: '', // Creator contract address
                    split: 1000
                },
                emptyCollaborator
            ];

const licenses = [
                {
                    id: 0, // TODO: Overwrite in contract
                    licenseTypeId: 1, // 1=NFT, 2=STREAM, 3=REMIX, 4=PRINT
                    editions: 1,
                    editionCents: 15000,
                    discountEditions: 0,
                    discountBasisPoints: 0,
                    discountMaxBasisPoints: 0,
                    available: 1,
                    licensees: []
                },
                {
                    id: 0, // TODO: Overwrite in contract
                    licenseTypeId: 2, // 1=NFT, 2=STREAM, 3=REMIX, 4=PRINT
                    editions: 0,
                    editionCents: 0,
                    discountEditions: 0,
                    discountBasisPoints: 0,
                    discountMaxBasisPoints: 0,
                    available: 0,
                    licensees: []
                },
                {
                    id: 0, // TODO: Overwrite in contract
                    licenseTypeId: 3, // 1=NFT, 2=STREAM, 3=REMIX, 4=PRINT
                    editions: 10000,
                    editionCents: 500,
                    discountEditions: 0,
                    discountBasisPoints: 0,
                    discountMaxBasisPoints: 0,
                    available: 10000,
                    licensees: []
               },
               {
                    id: 0, 
                    licenseTypeId: 0, 
                    editions: 0,
                    editionCents: 0,
                    discountEditions: 0,
                    discountBasisPoints: 0,
                    discountMaxBasisPoints: 0,
                    available: 0,
                    licensees: []
                }
];

const assetMedia = {
                    original: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua",
                    display: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua",
                    exhibition: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua",
                    preview: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua",
                    print: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua"
};

const auxiliaryMedia = {
                    arImage: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua",
                    arVideo: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua",
                    btsImage: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua",
                    btsVideo: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua",
                    codeZip: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua"
};


(async () => {
    const encode = function(json) { return Buffer.from(JSON.stringify(json)).toString('base64');}
    const decode = function(base64) { return JSON.parse(Buffer.from(base64, 'base64').toString('utf-8')); }
    
    const media = [
        encode({ "purpose": "original", "mimeType": "image/jpeg", "bytes": 1234567, "width": 2000, "height": 5000, "cid": "abababababababababababa"}),
        encode({ "purpose": "display", "mimeType": "image/jpeg", "bytes": 999999, "width": 2000, "height": 5000, "cid": "abababababababababababa"}),
        encode({ "purpose": "exhibition", "mimeType": "image/jpeg", "bytes": 9237923, "width": 2000, "height": 5000, "cid": "abababababababababababa"}),
        encode({ "purpose": "preview", "mimeType": "image/jpeg", "bytes": 888888, "width": 2000, "height": 5000, "cid": "abababababababababababa"}),
    ]

    try {

        let nonce = await signer.getNonce(); 

        // Create vaults
        let vaultKey = ethers.Wallet.createRandom().address.substring(4, 10);
        try {
            await creatorVaultFactory.createVault(
                vaultKey, // KEY
                `${creator.username}'s Vault`, // NAME
                creator.username, // SYMBOL
                [ethers.Wallet.createRandom().address, ethers.Wallet.createRandom().address],
                { nonce }
            );
        } catch(e) {
            console.log("\n\nError creating creator vault. Probably because it already exists");
        }     
        
       // while (creator.vault.length == 0) {
            await sleep(5000); // Allow time for the previous transaction to complete;
            creator.vault = await creatorVaultFactory.getVault(vaultKey);
            console.log('\n\nCreator Vault', creator.vault);
      //


        nonce = await signer.getNonce(); 

        // Create vaults
        vaultKey = ethers.Wallet.createRandom().address.substring(4, 10);;
        try {
            await creatorVaultFactory.createVault(
                vaultKey,
                `${collaborators[0].username}'s Vault`, 
                collaborators[0].username, 
                [ethers.Wallet.createRandom().address],
                { nonce }
            );
        } catch(e) {
            console.log("\n\nError creating coolaborator vault. Probably because it already exists");
        }              

        await sleep(6000); // Allow time for the previous transaction to complete;                              
        collaborators[0].vault = await creatorVaultFactory.getVault(vaultKey);
        console.log('\n\nCollaborators[0] Vault', collaborators[0].vault);

        nonce = await signer.getNonce(); 

        // IMPORTANT: We need to implement a nonce service so that each contract call uses
        //            the next sequential nonce number. A transaction will only be processed
        //            if the nonce value of a pending transaction is exactly the last nonce
        //            plus 1. 
        //            This will help: https://github.com/MetaMask/nonce-tracker
        //

        try {
            const assetKey = "ZBCD1234";
            const receipt1 = await assetRegistryContract.consign(
                                                                    assetKey,
                                                                    header,
                                                                    creator,
                                                                    collaborators[0],
                                                                    collaborators[1],
                                                                    licenses[0],
                                                                    licenses[1],
                                                                    licenses[2],
                                                                    licenses[3],
                                                                    media,
                                                                    { nonce } 
                                                                );
        } catch(e) {
            console.log(e);
        }
        //console.log(receipt1);
        await sleep(6000); // Allow time for the previous transaction to complete;

        let assetId = -1;
        let hexAssetId = '';
        // Get the event that was logged 
        const assetLog = assetRegistryContract.filters.AssetConsigned(null, creator.vault, null);    
        console.log(assetLog)    
        // if (assetLog) {
        //   const events = await assetRegistryContract.queryFilter(assetLog);
        //   const latest = events[events.length - 1];
        //   assetId = Number(latest.topics[1]);
        //   hexAssetId = latest.topics[1];
          
        //   const report = {
        //     view: `${explorer}/tx/${latest.transactionHash}`,
        //     tx: latest.transactionHash,
        //     assetId
        //   }
        //   console.log(report)
        // }

    } catch(e) {
        console.log(e);
    }


    async function sleep(millis) {
        return new Promise(resolve => setTimeout(resolve, millis));
    }
})();
