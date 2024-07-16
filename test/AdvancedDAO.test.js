import { expect } from "chai";
import { ethers } from "hardhat";

describe("AdvancedDAO", function () {
    let dao;
    let token;
    let owner;
    let addr1;
    let addr2;
    const votingPeriod = 60; // 60 seconds for testing
    const quorumPercentage = 50;

    beforeEach(async function () {
        [owner, addr1, addr2] = await ethers.getSigners();

        // Deploy a mock ERC20 token
        const Token = await ethers.getContractFactory("MockERC20");
        token = await Token.deploy("Mock Token", "MTK", ethers.utils.parseUnits("1000", 18));
        await token.deployed();

        // Transfer some tokens to addr1 and addr2
        await token.transfer(addr1.address, ethers.utils.parseUnits("100", 18));
        await token.transfer(addr2.address, ethers.utils.parseUnits("100", 18));

        // Deploy the DAO
        const DAO = await ethers.getContractFactory("AdvancedDAO");
        dao = await DAO.deploy(token.address, votingPeriod, quorumPercentage);
        await dao.deployed();
    });

    it("should create a proposal", async function () {
        await token.connect(addr1).approve(dao.address, ethers.utils.parseUnits("100", 18));
        await dao.connect(addr1).createProposal("Proposal 1");

        const proposal = await dao.proposals(1);
        expect(proposal.description).to.equal("Proposal 1");
        expect(proposal.proposer).to.equal(addr1.address);
    });

    it("should allow voting on a proposal", async function () {
        await token.connect(addr1).approve(dao.address, ethers.utils.parseUnits("100", 18));
        await dao.connect(addr1).createProposal("Proposal 1");

        await token.connect(addr1).approve(dao.address, ethers.utils.parseUnits("100", 18));
        await dao.connect(addr1).vote(1, true);

        const proposal = await dao.proposals(1);
        expect(proposal.voteCount).to.equal(100);
    });

    it("should execute a proposal if quorum is met", async function () {
        await token.connect(addr1).approve(dao.address, ethers.utils.parseUnits("100", 18));
        await dao.connect(addr1).createProposal("Proposal 1");

        await token.connect(addr1).approve(dao.address, ethers.utils.parseUnits("100", 18));
        await dao.connect(addr1).vote(1, true);

        // Fast forward time
        await new Promise(resolve => setTimeout(resolve, 61000));

        await dao.executeProposal(1);
        const proposal = await dao.proposals(1);
        expect(proposal.executed).to.be.true;
    });

    it("should revert if quorum is not met", async function () {
        await token.connect(addr1).approve(dao.address, ethers.utils.parseUnits("100", 18));
        await dao.connect(addr1).createProposal("Proposal 1");

        await token.connect(addr1).approve(dao.address, ethers.utils.parseUnits("100", 18));
        await dao.connect(addr1).vote(1, true);

        // Fast forward time
        await new Promise(resolve => setTimeout(resolve, 61000));

        await expect(dao.executeProposal(1)).to.be.revertedWith("Quorum not reached");
    });
});
