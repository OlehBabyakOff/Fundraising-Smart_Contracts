// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./Campaign.sol";

contract CampaignFactory {
    address[] public campaigns;

    event CampaignCreated(
        address indexed campaignAddress,
        address indexed creator,
        uint goalAmount,
        uint endDate
    );

    function createCampaign(uint _goalAmount, uint _endDate) external {
        Campaign newCampaign = new Campaign(msg.sender, _goalAmount, _endDate);
        campaigns.push(address(newCampaign));
        emit CampaignCreated(
            address(newCampaign),
            msg.sender,
            _goalAmount,
            _endDate
        );
    }

    function getCampaigns(
        uint startIndex,
        uint limit
    ) external view returns (address[] memory) {
        uint endIndex = startIndex + limit;
        if (endIndex > campaigns.length) {
            endIndex = campaigns.length;
        }

        address[] memory result = new address[](endIndex - startIndex);
        for (uint i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = campaigns[i];
        }

        return result;
    }

    function getTotalCampaigns() external view returns (uint) {
        return campaigns.length;
    }
}
