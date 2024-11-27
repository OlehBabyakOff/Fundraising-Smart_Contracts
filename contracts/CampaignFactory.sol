// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./Campaign.sol";

contract CampaignFactory {
    address[] public campaigns;

    struct CampaignDetails {
        address campaignAddress;
        address creator;
        string title;
        string description;
        string image;
        uint goalAmount;
        uint totalContributionsAmount;
        uint endDate;
    }

    event CampaignCreated(
        address indexed campaignAddress,
        address indexed creator,
        string title,
        string description,
        string image,
        uint goalAmount,
        uint endDate
    );

    function createCampaign(
        string memory _title,
        string memory _description,
        string memory _image,
        uint _goalAmount,
        uint _endDate
    ) external {
        Campaign newCampaign = new Campaign(
            msg.sender,
            _title,
            _description,
            _image,
            _goalAmount,
            _endDate
        );

        campaigns.push(address(newCampaign));

        emit CampaignCreated(
            address(newCampaign),
            msg.sender,
            _title,
            _description,
            _image,
            _goalAmount,
            _endDate
        );
    }

    function getCampaigns(
        uint startIndex,
        uint limit
    ) external view returns (CampaignDetails[] memory) {
        uint endIndex = startIndex + limit;
        if (endIndex > campaigns.length) {
            endIndex = campaigns.length;
        }

        uint resultSize = endIndex - startIndex;
        CampaignDetails[] memory result = new CampaignDetails[](resultSize);

        for (uint i = 0; i < resultSize; i++) {
            address campaignAddress = campaigns[startIndex + i];
            Campaign campaign = Campaign(campaignAddress);
            (
                address creator,
                string memory title,
                string memory description,
                string memory image,
                uint goalAmount,
                uint totalContributionsAmount,
                uint endDate
            ) = campaign.getCampaignDetails();

            result[i] = CampaignDetails(
                campaignAddress,
                creator,
                title,
                description,
                image,
                goalAmount,
                totalContributionsAmount,
                endDate
            );
        }

        return result;
    }

    function getTotalCampaigns() external view returns (uint) {
        return campaigns.length;
    }
}
