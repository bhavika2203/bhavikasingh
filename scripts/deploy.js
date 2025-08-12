const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", await deployer.getAddress());

  // Deploy Mock USDT (18 decimals)
  const MockUSDT = await ethers.getContractFactory("MockUSDT");
  const usdt = await MockUSDT.deploy();
  await usdt.waitForDeployment();
  console.log("MockUSDT:", await usdt.getAddress());

  // Deploy GameToken
  const GameToken = await ethers.getContractFactory("GameToken");
  const gt = await GameToken.deploy();
  await gt.waitForDeployment();
  console.log("GameToken:", await gt.getAddress());

  // Deploy TokenStore
  const TokenStore = await ethers.getContractFactory("TokenStore");
  const store = await TokenStore.deploy(await usdt.getAddress(), await gt.getAddress());
  await store.waitForDeployment();
  console.log("TokenStore:", await store.getAddress());

  // Set TokenStore in GameToken
  const tx1 = await gt.setTokenStore(await store.getAddress());
  await tx1.wait();

  // Deploy PlayGame with API Gateway as deployer (replaceable later by redeploy)
  const PlayGame = await ethers.getContractFactory("PlayGame");
  const play = await PlayGame.deploy(await gt.getAddress(), await deployer.getAddress());
  await play.waitForDeployment();
  console.log("PlayGame:", await play.getAddress());

  console.log("Deployment complete.");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});


