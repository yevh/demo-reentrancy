const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Reentrancy demo", function () {
  let owner, attacker;
  let secureVault, vulnerableVault;

  beforeEach(async function () {
    [owner, attacker] = await ethers.getSigners();

    const SecureVault = await ethers.getContractFactory("SecureVault");
    secureVault = await SecureVault.deploy();
    await secureVault.waitForDeployment();

    const VulnerableVault = await ethers.getContractFactory("VulnerableVault");
    vulnerableVault = await VulnerableVault.deploy();
    await vulnerableVault.waitForDeployment();

    // Fund each vault with 10 ETH
    const ten = ethers.parseEther("10");
    await secureVault.connect(owner).deposit({ value: ten });
    await vulnerableVault.connect(owner).deposit({ value: ten });
  });

  it("drains VulnerableVault", async function () {
    const Attack = await ethers.getContractFactory("Attack", attacker);
    const attack = await Attack.deploy(vulnerableVault.getAddress());
    await attack.waitForDeployment();

    await attack.connect(attacker).pwn({ value: ethers.parseEther("1") });

    const finalBalance = await ethers.provider.getBalance(vulnerableVault.getAddress());
    expect(finalBalance).to.equal(0n);
  });

  it("fails on SecureVault", async function () {
    const Attack = await ethers.getContractFactory("Attack", attacker);
    const attackSecure = await Attack.deploy(secureVault.getAddress());
    await attackSecure.waitForDeployment();

    await expect(
      attackSecure.connect(attacker).pwn({ value: ethers.parseEther("1") })
    ).to.be.revertedWith("ReentrancyGuard: reentrant call");
  });
});