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
        bool isGoalMet;
        bool isCampaignEnded;
        bool isFundsReleased;
        bool isFundsRefunded;
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

    // CREATE

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

    // function getCampaigns(
    //     uint startIndex,
    //     uint limit
    // ) external view returns (CampaignDetails[] memory) {
    //     uint endIndex = startIndex + limit;
    //     if (endIndex > campaigns.length) {
    //         endIndex = campaigns.length;
    //     }

    //     uint resultSize = endIndex - startIndex;
    //     CampaignDetails[] memory result = new CampaignDetails[](resultSize);

    //     for (uint i = 0; i < resultSize; i++) {
    //         address campaignAddress = campaigns[startIndex + i];
    //         Campaign campaign = Campaign(campaignAddress);
    //         (
    //             address creator,
    //             string memory title,
    //             string memory description,
    //             string memory image,
    //             uint goalAmount,
    //             uint totalContributionsAmount,
    //             uint endDate,
    //             bool isGoalMet,
    //             bool isCampaignEnded,
    //             bool isFundsReleased,
    //             bool isFundsRefunded
    //         ) = campaign.getCampaignDetails();

    //         result[i] = CampaignDetails(
    //             campaignAddress,
    //             creator,
    //             title,
    //             description,
    //             image,
    //             goalAmount,
    //             totalContributionsAmount,
    //             endDate,
    //             isGoalMet,
    //             isCampaignEnded,
    //             isFundsReleased,
    //             isFundsRefunded
    //         );
    //     }

    //     return result;
    // }

    // GET With pagination

    function getTotalCampaigns() external view returns (uint) {
        return campaigns.length;
    }

    function getCampaigns(
        uint page,
        uint offset
    ) external view returns (CampaignDetails[] memory) {
        uint skip = (page - 1) * offset;
        uint endIndex = skip + offset;

        if (skip >= campaigns.length) {
            return new CampaignDetails;
        }

        if (endIndex > campaigns.length) {
            endIndex = campaigns.length;
        }

        uint resultSize = endIndex - skip;
        CampaignDetails[] memory result = new CampaignDetails[](resultSize);

        for (uint i = 0; i < resultSize; i++) {
            address campaignAddress = campaigns[skip + i];
            Campaign campaign = Campaign(campaignAddress);
            (
                address creator,
                string memory title,
                string memory description,
                string memory image,
                uint goalAmount,
                uint totalContributionsAmount,
                uint endDate,
                bool isGoalMet,
                bool isCampaignEnded,
                bool isFundsReleased,
                bool isFundsRefunded
            ) = campaign.getCampaignDetails();

            result[i] = CampaignDetails(
                campaignAddress,
                creator,
                title,
                description,
                image,
                goalAmount,
                totalContributionsAmount,
                endDate,
                isGoalMet,
                isCampaignEnded,
                isFundsReleased,
                isFundsRefunded
            );
        }

        return result;
    }

    function getCampaignsByCreator(
        address creator
    ) external view returns (CampaignDetails[] memory) {
        uint creatorCampaignsCount = 0;

        for (uint i = 0; i < campaigns.length; i++) {
            Campaign campaign = Campaign(campaigns[i]);
            (address campaignCreator, , , , , , , , , , ) = campaign
                .getCampaignDetails();
            if (campaignCreator == creator) {
                creatorCampaignsCount++;
            }
        }

        CampaignDetails[] memory creatorCampaigns = new CampaignDetails[](
            creatorCampaignsCount
        );
        uint index = 0;

        for (uint i = 0; i < campaigns.length; i++) {
            Campaign campaign = Campaign(campaigns[i]);
            (
                address campaignCreator,
                string memory title,
                string memory description,
                string memory image,
                uint goalAmount,
                uint totalContributionsAmount,
                uint endDate,
                bool isGoalMet,
                bool isCampaignEnded,
                bool isFundsReleased,
                bool isFundsRefunded
            ) = campaign.getCampaignDetails();

            if (campaignCreator == creator) {
                creatorCampaigns[index] = CampaignDetails(
                    campaigns[i],
                    campaignCreator,
                    title,
                    description,
                    image,
                    goalAmount,
                    totalContributionsAmount,
                    endDate,
                    isGoalMet,
                    isCampaignEnded,
                    isFundsReleased,
                    isFundsRefunded
                );
                index++;
            }
        }

        return creatorCampaigns;
    }

    // GET with filters

    function filterCampaignsByName(
        string memory searchTerm
    ) public view returns (CampaignDetails[] memory) {
        uint count = 0;

        for (uint i = 0; i < campaigns.length; i++) {
            Campaign campaign = Campaign(campaigns[i]);

            (, string memory title, , , , , , , , , ) = campaign
                .getCampaignDetails();

            if (keccak256(bytes(title)) == keccak256(bytes(searchTerm))) {
                count++;
            }
        }

        CampaignDetails[] memory filteredCampaigns = new CampaignDetails[](
            count
        );

        uint index = 0;

        for (uint i = 0; i < campaigns.length; i++) {
            Campaign campaign = Campaign(campaigns[i]);

            (, string memory title, , , , , , , , , ) = campaign
                .getCampaignDetails();

            if (keccak256(bytes(title)) == keccak256(bytes(searchTerm))) {
                filteredCampaigns[index] = campaign.getCampaignDetails(campaign);

                index++;
            }
        }

        return filteredCampaigns;
    }

    // GET with sort

    function sortCampaignsByValue() public {
        for (uint i = 0; i < campaigns.length - 1; i++) {
            for (uint j = i + 1; j < campaigns.length; j++) {
                Campaign campaignI = Campaign(campaigns[i]);

                Campaign campaignJ = Campaign(campaigns[j]);

                uint totalContributionsI;

                uint totalContributionsJ;

                (, , , , , totalContributionsI, , , , ) = campaignI
                    .getCampaignDetails();

                (, , , , , totalContributionsJ, , , , ) = campaignJ
                    .getCampaignDetails();

                if (totalContributionsI > totalContributionsJ) {
                    address temp = campaigns[i];

                    campaigns[i] = campaigns[j];

                    campaigns[j] = temp;
                }
            }
        }
    }

    // GET with search

    function searchCampaignsByName(string memory searchTerm) public view returns (CampaignDetails[] memory) {
        uint count = 0;
        for (uint i = 0; i < campaigns.length; i++) {
            Campaign campaign = Campaign(campaigns[i]);
            ( , string memory title, , , , , , , , , ) = campaign.getCampaignDetails();
            if (bytes(title).length >= bytes(searchTerm).length) {
                bool match = true;
                for (uint j = 0; j < bytes(searchTerm).length; j++) {
                    if (bytes(title)[j] != bytes(searchTerm)[j]) {
                        match = false;
                        break;
                    }
                }
                if (match) {
                    count++;
                }
            }
        }

        CampaignDetails[] memory result = new CampaignDetails[](count);
        uint index = 0;
        for (uint i = 0; i < campaigns.length; i++) {
            Campaign campaign = Campaign(campaigns[i]);
            ( , string memory title, , , , , , , , , ) = campaign.getCampaignDetails();
            if (bytes(title).length >= bytes(searchTerm).length) {
                bool match = true;
                for (uint j = 0; j < bytes(searchTerm).length; j++) {
                    if (bytes(title)[j] != bytes(searchTerm)[j]) {
                        match = false;
                        break;
                    }
                }
                
                if (match) {
                    result[index] = campaign.getCampaignDetails(campaign);
                    index++;
                }
            }
        }

        return result;
    }
}
