const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("CampaignFactoryModule", (m) => {
  const campaignFactory = m.contract("CampaignFactory", []);

  return { campaignFactory };
});
