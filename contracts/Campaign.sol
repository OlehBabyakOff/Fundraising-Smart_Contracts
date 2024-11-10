// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
}

contract Campaign {
    address public serverAddress;
    address public creator;

    uint public goalAmount;
    uint public totalContributionsAmount;

    uint public endDate;

    bool public isGoalMet;
    bool public isCampaignEnded;

    uint public constant MIN_DONATION = 1 ether;

    mapping(address => uint) public contributions;

    event DonationReceived(address indexed donor, uint amount);
    event FundsReleased(uint amount);
    event RefundIssued(address indexed donor, uint amount);

    constructor(address _creator, uint _goalAmount, uint _endDate) {
        require(_endDate > block.timestamp, "End date must be in the future");
        require(_goalAmount > 0, "Goal amount must be greater than 0");

        creator = _creator;
        goalAmount = _goalAmount;
        endDate = _endDate;
        isGoalMet = false;
        isCampaignEnded = false;
    }

    modifier onlyCreatorOrServer() {
        require(
            msg.sender == creator || msg.sender == serverAddress,
            "Not allowed"
        );
        _;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "You are not the creator");
        _;
    }

    modifier campaignOngoing() {
        require(block.timestamp < endDate, "Campaign has ended");
        require(!isCampaignEnded, "Campaign has already ended");
        _;
    }

    function donate() external payable campaignOngoing {
        uint donation = msg.value;

        require(
            donation >= MIN_DONATION,
            "Donations below the minimum amount are not allowed"
        );

        require(
            totalContributionsAmount + donation <= goalAmount,
            "Donation exceeds goal"
        );

        contributions[msg.sender] += donation;

        totalContributionsAmount += donation;

        emit DonationReceived(msg.sender, msg.value);

        if (totalContributionsAmount >= goalAmount) {
            isGoalMet = true;
            isCampaignEnded = true;
        }
    }

    function refund() external {
        require(!isGoalMet, "Goal met, no refunds available");
        require(
            block.timestamp >= endDate || isCampaignEnded,
            "Campaign must be ended for refunds"
        );

        uint contributedAmount = contributions[msg.sender];
        require(contributedAmount > 0, "No contributions to refund");

        contributions[msg.sender] = 0;

        payable(msg.sender).transfer(contributedAmount);

        emit RefundIssued(msg.sender, contributedAmount);
    }

    function releaseFunds() external onlyCreatorOrServer {
        require(isGoalMet, "Goal not met");

        uint amountToRelease = totalContributionsAmount;
        require(amountToRelease > 0, "No funds to release");

        totalContributionsAmount = 0;
        payable(creator).transfer(amountToRelease);

        emit FundsReleased(amountToRelease);
    }

    function endCampaign() external onlyCreatorOrServer {
        require(block.timestamp >= endDate, "Campaign end date not reached");
        isCampaignEnded = true;
    }

    function getCampaignStatus() external view returns (bool, uint) {
        return (isGoalMet, totalContributionsAmount);
    }
}
