const { ethers } = require("hardhat");
const hre = require("hardhat");
require('dotenv').config();

/// npx hardhat run --network testnet scripts/collector/transfers.js 
/// npx hardhat run --network mainnet scripts/collector/transfers.js 


async function sleep(millis) {
    return new Promise(resolve => setTimeout(resolve, millis));
}


(async () => {
    const network = hre.network.name;
    const isTestNet = network === 'testnet' ? true : false;
    const contractAddress = isTestNet ? process.env.TESTNET_VCOLC_CONTRACT : process.env.MAINNET_VCOLC_CONTRACT;

    const CollectorCredit = await ethers.getContractFactory("CollectorCredit");
    const collectorCredit = CollectorCredit.attach(contractAddress);
    console.log(network, contractAddress);

    // Get the event that was logged 
    const transferLog = collectorCredit.filters.Transfer(null, null, null);        
    if (transferLog) {
        const events = await collectorCredit.queryFilter(transferLog);
        const transfers = [];
        events.forEach((e) => {
            if (e.topics[1] != '0x0000000000000000000000000000000000000000000000000000000000000000' &&
                e.topics[2] != '0x0000000000000000000000000000000000000000000000000000000000000000') {
                transfers.push(e);
            }
        })

        console.log(transfers, transfers.length);
    }

})();
