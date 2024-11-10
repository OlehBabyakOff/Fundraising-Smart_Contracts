const { expect } = require("chai");
const {
  loadFixture,
} = require("@nomicfoundation/hardhat-toolbox/network-helpers");
const { ethers } = require("hardhat");

describe("Campaign", function () {
  async function deployCampaignFixture() {
    const [creator, donor1, donor2] = await ethers.getSigners();
    const goalAmount = ethers.parseEther("10"); // Goal amount of 10 ETH
    const minDonation = ethers.parseEther("1"); // Minimum donation of 1 ETH
    const maxDonation = ethers.parseEther("5"); // Maximum donation of 5 ETH
    const endDate = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
    const currency = "ETH"; // Currency
    const priceFeedAddress = "0x0000000000000000000000000000000000000000"; // Mock price feed address

    const Campaign = await ethers.getContractFactory("Campaign");
    const campaign = await Campaign.deploy(
      creator.address,
      goalAmount,
      minDonation,
      maxDonation,
      endDate,
      currency,
      priceFeedAddress
    );

    await campaign.waitForDeployment();

    return {
      campaign,
      creator,
      donor1,
      donor2,
      goalAmount,
      minDonation,
      maxDonation,
      endDate,
      currency,
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

    it("Should set the right min and max donation amounts", async function () {
      const { campaign, minDonation, maxDonation } = await loadFixture(
        deployCampaignFixture
      );
      expect(await campaign.minDonation()).to.equal(minDonation);
      expect(await campaign.maxDonation()).to.equal(maxDonation);
    });
  });

  describe("Donations", function () {
    it("Should accept donations within the allowed range", async function () {
      const { campaign, donor1, minDonation, currency } = await loadFixture(
        deployCampaignFixture
      );

      await expect(
        campaign.connect(donor1).donate(currency, { value: minDonation })
      )
        .to.emit(campaign, "DonationReceived")
        .withArgs(await donor1.getAddress(), minDonation, currency);

      expect(await campaign.totalContributionsAmount()).to.equal(minDonation);
      expect(await campaign.contributions(await donor1.getAddress())).to.equal(
        minDonation
      );
    });

    it("Should revert if donation is below minimum donation", async function () {
      const { campaign, donor1, currency } = await loadFixture(
        deployCampaignFixture
      );
      const lowDonation = ethers.parseEther("0.5"); // Below minimum

      await expect(
        campaign.connect(donor1).donate(currency, { value: lowDonation })
      ).to.be.revertedWith("Donation out of range");
    });

    it("Should revert if donation exceeds maximum donation", async function () {
      const { campaign, donor1, currency } = await loadFixture(
        deployCampaignFixture
      );
      const highDonation = ethers.parseEther("6"); // Above maximum

      await expect(
        campaign.connect(donor1).donate(currency, { value: highDonation })
      ).to.be.revertedWith("Donation out of range");
    });
  });

  describe("Refunds", function () {
    it("Should allow refunds if the goal was not met", async function () {
      const { campaign, donor1, currency } = await loadFixture(
        deployCampaignFixture
      );
      const donation = ethers.parseEther("1");

      await campaign.connect(donor1).donate(currency, { value: donation });

      // simulates the passage of the time
      await ethers.provider.send("evm_increaseTime", [3600]);
      await ethers.provider.send("evm_mine");

      expect(await campaign.contributions(donor1.address)).to.equal(donation);
      await campaign.connect(donor1).refund();
      expect(await campaign.contributions(donor1.address)).to.equal(0);
    });

    it("Should revert refunds if the goal was met", async function () {
      const { campaign, donor1, donor2, currency, maxDonation, minDonation } =
        await loadFixture(deployCampaignFixture);

      await Promise.all([
        campaign.connect(donor1).donate(currency, { value: maxDonation }),
        campaign.connect(donor2).donate(currency, { value: maxDonation }),
      ]);

      await expect(campaign.connect(donor1).refund()).to.be.revertedWith(
        "Goal met, no refunds available"
      );
    });

    it("Should revert if trying to refund before the end date", async function () {
      const { campaign, donor1, currency, minDonation } = await loadFixture(
        deployCampaignFixture
      );

      await campaign.connect(donor1).donate(currency, { value: minDonation });

      await expect(campaign.connect(donor1).refund()).to.be.revertedWith(
        "Campaign must be ended for refunds"
      );
    });
  });

  describe("Fund Releases", function () {
    it("Should allow creator to release funds if goal is met", async function () {
      const { campaign, donor1, donor2, currency, maxDonation } =
        await loadFixture(deployCampaignFixture);

      await Promise.all([
        campaign.connect(donor1).donate(currency, { value: maxDonation }),
        campaign.connect(donor2).donate(currency, { value: maxDonation }),
      ]);

      await expect(campaign.releaseFunds())
        .to.emit(campaign, "FundsReleased")
        .withArgs(ethers.parseEther("10"));

      expect(
        await ethers.provider.getBalance(await campaign.getAddress())
      ).to.equal(0);
    });

    it("Should revert if trying to release funds before goal is met", async function () {
      const { campaign } = await loadFixture(deployCampaignFixture);

      await expect(campaign.releaseFunds()).to.be.revertedWith("Goal not met");
    });

    it("Should revert if trying to release funds after goal is met and funds are released", async function () {
      const { campaign, donor1, donor2, currency, maxDonation } =
        await loadFixture(deployCampaignFixture);

      await Promise.all([
        campaign.connect(donor1).donate(currency, { value: maxDonation }),
        campaign.connect(donor2).donate(currency, { value: maxDonation }),
      ]);

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
      const { campaign, creator } = await loadFixture(deployCampaignFixture);
      await expect(campaign.endCampaign()).to.be.revertedWith(
        "Campaign end date not reached"
      );
    });
  });
});
