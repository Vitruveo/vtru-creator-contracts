const { ethers, upgrades } = require("hardhat");

// npx hardhat run --network testnet scripts/media/deploy.js
// npx hardhat verify --contract contracts/MediaRegistry.sol:MediaRegistry --network testnet 0xCf7Ed3AccA5a467e9e704C703E8D87F634fB0Fc9
// npx hardhat verify --contract contracts/MediaRegistry.sol:MediaRegistry --network mainnet 0x3925b92Ef881A9B0465Ef1ebDEE5D6C0ED4d464b

async function main() {
  const MediaRegistry = await ethers.getContractFactory("MediaRegistry");
  const mediaRegistry = await upgrades.deployProxy(MediaRegistry, {initializer: 'initialize'});
  await mediaRegistry.waitForDeployment();
  console.log("MediaRegistry deployed to:", await mediaRegistry.getAddress());
}

main().catch((error) => {
   console.error(error);
   process.exitCode = 1;
 });