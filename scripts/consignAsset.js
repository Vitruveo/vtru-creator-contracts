const { ethers, JsonRpcProvider, Wallet, Contract } = require("ethers");

const config = require("../vault-config.json");
require("dotenv").config();

const isTestNet = process.env.NEXT_PUBLIC_TESTNET == "true";

const network = isTestNet ? 'testnet' : 'mainnet';

const rpc = isTestNet ? process.env.TESTNET_RPC : process.env.MAINNET_RPC;
const provider = new JsonRpcProvider(rpc);
const signer = new Wallet(process.env.STUDIO_PRIVATE_KEY, provider);

const assetRegistryContract = new Contract(config.assetRegistry[network], config.assetRegistry.abi, signer);
const mediaRegistryContract = new Contract(config.mediaRegistry[network], config.mediaRegistry.abi, signer);
const creatorVaultFactory = new Contract(config.creatorVaultFactory[network], config.creatorVaultFactory.abi, signer);
const creatorVault = (address) => new Contract(address, config.creatorVault.abi, signer);

const core = { 
                    title: 'Nik Kalyani', // Title from metadata
                    description: 'Hello world', // Long description from auxiliary view
                    tokenUri: 'https://www.vitruveo.xyz',
                    mediaTypes: [],
                    mediaItems: [],            
                    status: 2
};

const creator =     {
    vault: '', // Creator contract address
    split: 9000 // Split percentage in basis points
}

const emptyCollaborator = {
    vault: ethers.ZeroAddress, // Creator contract address
    split: 0
}

const collaborators = [

                {
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
                    print: "bafybeif5wb5ihbwverck24cdv5l2qw7syhtugsbjeam2pnzls44u3py3ua",
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

        // Create Creator vault
        let vaultKey = ethers.Wallet.createRandom().address.substring(4, 10);
        try {
            await creatorVaultFactory.createVault(
                vaultKey, // KEY
                `${vaultKey}'s Vault`, // NAME
                vaultKey, // SYMBOL
                [ethers.Wallet.createRandom().address, ethers.Wallet.createRandom().address],
                { nonce }
            );
        } catch(e) {
            console.log("\n\nError creating creator vault. Probably because it already exists");
        }     
        
        await sleep(5000); // Allow time for the previous transaction to complete;
        creator.vault = await creatorVaultFactory.getVault(vaultKey);
        console.log('\n\nCreator Vault', creator.vault);

        nonce = await signer.getNonce(); 

        // Create Collaborator vault
        vaultKey = ethers.Wallet.createRandom().address.substring(4, 10);;
        try {
            await creatorVaultFactory.createVault(
                vaultKey,
                `${vaultKey}'s Vault`, 
                vaultKey, 
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

        const assetKey = String(Math.floor(Date.now() / 1000));
        try {


        // Add the asset media
        Object.keys(assetMedia).forEach((m) => {
            core.mediaTypes.push(m);
            core.mediaItems.push(assetMedia[m]);
        })

            const receipt1 = await assetRegistryContract.consign(
                                                                    assetKey,
                                                                    core,
                                                                    creator,
                                                                    collaborators[0],
                                                                    collaborators[1],
                                                                    licenses[0],
                                                                    licenses[1],
                                                                    licenses[2],
                                                                    licenses[3],
                                                                    { nonce } 
                                                                );
        } catch(e) {
            console.log(e);
        }
        //console.log(receipt1);
        await sleep(6000); // Allow time for the previous transaction to complete;
        console.log('ASSET', await assetRegistryContract.getAsset(assetKey));

        console.log(await mediaRegistryContract.getMedia(assetKey));

        console.log('Media added!');

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


    // const userVault = new Contract('0x0FF6c4Cb16993CefD40b250683eDacA29FFe74C5', config.creatorVault.abi, signer);
    // await userVault.addCreatorCredits(10);

    async function sleep(millis) {
        return new Promise(resolve => setTimeout(resolve, millis));
    }
})();
