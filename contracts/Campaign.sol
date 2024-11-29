// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
}

contract Campaign {
    address public serverAddress;
    address public creator;

    string public title;
    string public description;
    string public image;

    uint public goalAmount;
    uint public totalContributionsAmount;

    uint public endDate;

    bool public isGoalMet;
    bool public isCampaignEnded;

    bool public isFundsReleased;
    bool public isFundsRefunded;

    uint public constant MIN_DONATION = 0.001 ether;

    mapping(address => uint) public contributions;

    address[] public contributors;

    event DonationReceived(address indexed donor, uint amount);
    event FundsReleased(address indexed creator, uint amount);
    event RefundIssued(address indexed donor, uint amount);

    constructor(
        address _creator,
        string memory _title,
        string memory _description,
        string memory _image,
        uint _goalAmount,
        uint _endDate
    ) {
        require(_endDate > block.timestamp, "End date must be in the future");
        require(_goalAmount > 0, "Goal amount must be greater than 0");

        creator = _creator;
        title = _title;
        description = _description;
        image = _image;
        goalAmount = _goalAmount;
        endDate = _endDate;
        isGoalMet = false;
        isCampaignEnded = false;
        isFundsReleased = false;
        isFundsRefunded = false;
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

        if (contributions[msg.sender] == 0) {
            contributors.push(msg.sender);
        }

        contributions[msg.sender] += donation;

        totalContributionsAmount += donation;

        emit DonationReceived(msg.sender, msg.value);
    }

    function refund() external {
        require(!isGoalMet, "Goal met, no refunds available");
        require(
            block.timestamp >= endDate || isCampaignEnded,
            "Campaign must be ended for refunds"
        );

        uint totalRefundedAmount = 0;

        for (uint i = 0; i < contributors.length; i++) {
            address contributor = contributors[i];
            uint contributedAmount = contributions[contributor];

            if (contributedAmount > 0) {
                contributions[contributor] = 0;

                payable(contributor).transfer(contributedAmount);

                totalRefundedAmount += contributedAmount;

                emit RefundIssued(contributor, contributedAmount);
            }
        }

        isFundsRefunded = true;
    }

    function releaseFunds() external onlyCreatorOrServer {
        require(isGoalMet, "Goal not met");

        uint amountToRelease = totalContributionsAmount;
        require(amountToRelease > 0, "No funds to release");

        totalContributionsAmount = 0;
        payable(creator).transfer(amountToRelease);

        isFundsReleased = true;

        emit FundsReleased(creator, amountToRelease);
    }

    function endCampaign() external onlyCreatorOrServer {
        isCampaignEnded = true;
    }

    function getCampaignStatus() external view returns (bool, bool, uint) {
        return (isCampaignEnded, isGoalMet, totalContributionsAmount);
    }

    function getCampaignDetails()
        external
        view
        returns (
            address _creator,
            string memory _title,
            string memory _description,
            string memory _image,
            uint _goalAmount,
            uint _totalContributionsAmount,
            uint _endDate,
            bool _isGoalMet,
            bool _isCampaignEnded,
            bool _isFundsReleased,
            bool _isFundsRefunded
        )
    {
        return (
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
}
