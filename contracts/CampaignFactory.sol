// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./Campaign.sol";

contract CampaignFactory {
    address[] public campaigns;

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
