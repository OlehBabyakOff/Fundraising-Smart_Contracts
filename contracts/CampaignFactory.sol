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

    function getTotalCampaigns() external view returns (uint) {
        return campaigns.length;
    }
}
