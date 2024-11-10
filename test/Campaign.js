const { expect } = require("chai");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { ethers } = require("hardhat");

describe("Campaign", function () {
  async function deployCampaignFixture() {
    const [creator, donor] = await ethers.getSigners();
    const goalAmount = ethers.parseEther("10"); // Goal amount of 10 ETH
    const endDate = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now

    const Campaign = await ethers.getContractFactory("Campaign");
    const campaign = await Campaign.deploy(
      creator.address,
      goalAmount,
      endDate
    );

    await campaign.waitForDeployment();

    return {
      campaign,
      creator,
      donor,
      goalAmount,
      endDate,
    };
  }

  describe("Deployment", function () {
    it("Should set the right creator", async function () {
      const { campaign, creator } = await loadFixture(deployCampaignFixture);
      expect(await campaign.creator()).to.equal(creator.address);
    });

    it("Should set the right goal amount", async function () {
      const { campaign, goalAmount } = await loadFixture(deployCampaignFixture);
      expect(await campaign.goalAmount()).to.equal(goalAmount);
    });
  });

  describe("Donations", function () {
    it("Should accept donations within the allowed range", async function () {
      const { campaign, donor } = await loadFixture(deployCampaignFixture);

      const donation = ethers.parseEther("1");

      await expect(campaign.connect(donor).donate({ value: donation }))
        .to.emit(campaign, "DonationReceived")
        .withArgs(await donor.getAddress(), donation);

      expect(await campaign.totalContributionsAmount()).to.equal(donation);

      expect(await campaign.contributions(await donor.getAddress())).to.equal(
        donation
      );
    });

    it("Should revert if donation is below minimum amount", async function () {
      const { campaign, donor } = await loadFixture(deployCampaignFixture);
      const lowDonation = ethers.parseEther("0.001");

      await expect(
        campaign.connect(donor).donate({ value: lowDonation })
      ).to.be.revertedWith(
        "Donations below the minimum amount are not allowed"
      );
    });

    it("Should revert if donation exceeds goal", async function () {
      const { campaign, donor } = await loadFixture(deployCampaignFixture);

      const highDonation = ethers.parseEther("11"); // Above maximum

      await expect(
        campaign.connect(donor).donate({ value: highDonation })
      ).to.be.revertedWith("Donation exceeds goal");
    });
  });

  describe("Refunds", function () {
    it("Should allow refunds if the goal was not met", async function () {
      const { campaign, donor } = await loadFixture(deployCampaignFixture);

      const donation = ethers.parseEther("1");

      await campaign.connect(donor).donate({ value: donation });

      // simulates the passage of the time
      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");

      expect(await campaign.contributions(donor.address)).to.equal(donation);

      await campaign.connect(donor).refund();

      expect(await campaign.contributions(donor.address)).to.equal(0);
    });

    it("Should revert refunds if the goal was met", async function () {
      const { campaign, donor } = await loadFixture(deployCampaignFixture);

      const donation = ethers.parseEther("10");

      await campaign.connect(donor).donate({ value: donation });

      await expect(campaign.connect(donor).refund()).to.be.revertedWith(
        "Goal met, no refunds available"
      );
    });

    it("Should revert if trying to refund before the end date", async function () {
      const { campaign, donor } = await loadFixture(deployCampaignFixture);

      const donation = ethers.parseEther("1");

      await campaign.connect(donor).donate({ value: donation });

      await expect(campaign.connect(donor).refund()).to.be.revertedWith(
        "Campaign must be ended for refunds"
      );
    });
  });

  describe("Fund Releases", function () {
    it("Should allow creator to release funds if goal is met", async function () {
      const { campaign, donor } = await loadFixture(deployCampaignFixture);

      const donation = ethers.parseEther("10");

      await campaign.connect(donor).donate({ value: donation });

      await expect(campaign.releaseFunds())
        .to.emit(campaign, "FundsReleased")
        .withArgs(donation);

      expect(
        await ethers.provider.getBalance(await campaign.getAddress())
      ).to.equal(0);
    });

    it("Should revert if trying to release funds before goal is met", async function () {
      const { campaign } = await loadFixture(deployCampaignFixture);

      await expect(campaign.releaseFunds()).to.be.revertedWith("Goal not met");
    });

    it("Should revert if trying to release funds after goal is met and funds are released", async function () {
      const { campaign, donor } = await loadFixture(deployCampaignFixture);

      const donation = ethers.parseEther("10");

      await campaign.connect(donor).donate({ value: donation });

      await campaign.releaseFunds();

      await expect(campaign.releaseFunds()).to.be.revertedWith(
        "No funds to release"
      );
    });
  });

  describe("Campaign Ending", function () {
    it("Should allow the creator to end the campaign after the end date", async function () {
      const { campaign } = await loadFixture(deployCampaignFixture);

      // simulates the passage of the time
      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");

      await campaign.endCampaign();
      expect(await campaign.isCampaignEnded()).to.be.true;
    });

    it("Should revert if the creator tries to end the campaign before the end date", async function () {
      const { campaign } = await loadFixture(deployCampaignFixture);

      await expect(campaign.endCampaign()).to.be.revertedWith(
        "Campaign end date not reached"
      );
    });
  });
});
