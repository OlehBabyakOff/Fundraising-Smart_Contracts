// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./Campaign.sol";

contract CampaignFactory {
    address[] public campaigns;
    mapping(address => bool) public hasActiveCampaign;

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
        require(
            !hasActiveCampaign[msg.sender],
            "You already have an active campaign."
        );

        Campaign newCampaign = new Campaign(
            msg.sender,
            _title,
            _description,
            _image,
            _goalAmount,
            _endDate
        );

        campaigns.push(address(newCampaign));

        hasActiveCampaign[msg.sender] = true;

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

    function resetActiveCampaignStatus(address creator) external {
        require(
            hasActiveCampaign[creator],
            "Creator does not have an active campaign."
        );

        hasActiveCampaign[creator] = false;
    }

    function getTotalCampaigns() external view returns (uint) {
        return campaigns.length;
    }
}
