const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GameToken & TokenStore", function () {
  async function deployAll() {
    const [owner, buyer, other] = await ethers.getSigners();

    const MockUSDT = await ethers.getContractFactory("MockUSDT");
    const usdt = await MockUSDT.deploy();
    await usdt.waitForDeployment();

    const GameToken = await ethers.getContractFactory("GameToken");
    const gt = await GameToken.deploy();
    await gt.waitForDeployment();

    const TokenStore = await ethers.getContractFactory("TokenStore");
    const store = await TokenStore.deploy(await usdt.getAddress(), await gt.getAddress());
    await store.waitForDeployment();

    await gt.setTokenStore(await store.getAddress());

    return { owner, buyer, other, usdt, gt, store };
  }

  it("only store can mint", async function () {
    const { gt, owner } = await deployAll();
    await expect(gt.connect(owner).mint(await owner.getAddress(), 1)).to.be.revertedWith("Not store");
  });

  it("buyer can purchase GT 1:1 using USDT", async function () {
    const { buyer, usdt, gt, store } = await deployAll();
    await usdt.mint(await buyer.getAddress(), ethers.parseEther("100"));
    await usdt.connect(buyer).approve(await store.getAddress(), ethers.parseEther("10"));
    await expect(store.connect(buyer).buy(ethers.parseEther("10")))
      .to.emit(store, "Purchased");
    expect(await gt.balanceOf(await buyer.getAddress())).to.equal(ethers.parseEther("10"));
    expect(await usdt.balanceOf(await store.getAddress())).to.equal(ethers.parseEther("10"));
  });

  it("owner can withdraw USDT", async function () {
    const { owner, buyer, usdt, gt, store } = await deployAll();
    await usdt.mint(await buyer.getAddress(), ethers.parseEther("5"));
    await usdt.connect(buyer).approve(await store.getAddress(), ethers.parseEther("5"));
    await store.connect(buyer).buy(ethers.parseEther("5"));
    await expect(store.connect(owner).withdraw(ethers.parseEther("5")))
      .to.emit(store, "Withdrawn");
    expect(await usdt.balanceOf(await owner.getAddress())).to.equal(ethers.parseEther("5"));
  });
});


