const { ethers, upgrades } = require("hardhat");

// npx hardhat run --network testnet scripts/registry/deploy.js
// npx hardhat verify --contract contracts/ContractRegistry.sol:ContractRegistry --network testnet 0x55fB1f353E73fFbca27fE8155e724435aB458491
// npx hardhat verify --contract contracts/ContractRegistry.sol:ContractRegistry --network mainnet 0x55fB1f353E73fFbca27fE8155e724435aB458491

async function main() {
  const ContractRegistry = await ethers.getContractFactory("ContractRegistry");

  [Creator, Registry, Collector] = await ethers.getSigners();
  const contractRegistry = await ContractRegistry.connect(Registry).deploy();
  console.log("ContractRegistry deployed to:", await contractRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });