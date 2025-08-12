const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("PlayGame", function () {
  async function deployAll() {
    const [owner, gateway, p1, p2, outsider] = await ethers.getSigners();

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

    // fund players with USDT then buy GT
    const initial = ethers.parseEther("100");
    await usdt.mint(await p1.getAddress(), initial);
    await usdt.mint(await p2.getAddress(), initial);
    await usdt.connect(p1).approve(await store.getAddress(), initial);
    await usdt.connect(p2).approve(await store.getAddress(), initial);
    await store.connect(p1).buy(initial);
    await store.connect(p2).buy(initial);

    const PlayGame = await ethers.getContractFactory("PlayGame");
    const play = await PlayGame.deploy(await gt.getAddress(), await gateway.getAddress());
    await play.waitForDeployment();

    return { owner, gateway, p1, p2, outsider, usdt, gt, store, play };
  }

  it("full happy path: create, join, submit result", async function () {
    const { p1, p2, gateway, gt, play } = await deployAll();
    const matchId = 1;
    const stake = ethers.parseEther("10");

    await gt.connect(p1).approve(await play.getAddress(), stake);
    await expect(play.connect(p1).createMatch(matchId, stake)).to.emit(play, "MatchCreated");

    await gt.connect(p2).approve(await play.getAddress(), stake);
    await expect(play.connect(p2).joinMatch(matchId)).to.emit(play, "MatchJoined");

    await expect(play.connect(gateway).submitResult(matchId, await p2.getAddress()))
      .to.emit(play, "MatchResolved");
    const p2Addr = await p2.getAddress();
    const start = ethers.parseEther("100");
    const expected = start - stake + stake * 2n; // BigInt math in ethers v6
    expect(await gt.balanceOf(p2Addr)).to.equal(expected);
  });

  it("only gateway can submit results", async function () {
    const { p1, p2, outsider, gt, play } = await deployAll();
    const matchId = 2;
    const stake = ethers.parseEther("5");
    await gt.connect(p1).approve(await play.getAddress(), stake);
    await play.connect(p1).createMatch(matchId, stake);
    await gt.connect(p2).approve(await play.getAddress(), stake);
    await play.connect(p2).joinMatch(matchId);
    await expect(play.connect(outsider).submitResult(matchId, await p1.getAddress())).to.be.revertedWith("not gateway");
  });

  it("owner can cancel open matches and refund", async function () {
    const { owner, p1, gt, play } = await deployAll();
    const matchId = 3;
    const stake = ethers.parseEther("1");
    const before = await gt.balanceOf(await p1.getAddress());
    await gt.connect(p1).approve(await play.getAddress(), stake);
    await play.connect(p1).createMatch(matchId, stake);
    await expect(play.connect(owner).cancelMatch(matchId)).to.emit(play, "MatchCancelled");
    const after = await gt.balanceOf(await p1.getAddress());
    expect(after).to.equal(before);
  });
});


