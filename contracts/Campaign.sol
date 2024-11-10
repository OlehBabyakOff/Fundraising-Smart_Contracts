// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC20 {
    function transfer(address recipient, uint amount) external returns (bool);
}

interface IPriceFeed {
    function getLatestPrice() external view returns (uint);
}

contract Campaign {
    address public serverAddress;
    address public creator;
    uint public goalAmount;
    uint public totalContributionsAmount;
    uint public minDonation;
    uint public maxDonation;
    uint public endDate;
    bool public isGoalMet;
    bool public isCampaignEnded;
    string public currency;

    mapping(address => uint) public contributions;
    mapping(address => string) public donorCurrencies;
    mapping(string => address) public tokenAddresses;

    IPriceFeed public priceFeed;

    event DonationReceived(address indexed donor, uint amount, string currency);
    event FundsReleased(uint amount);
    event RefundIssued(address indexed donor, uint amount, string currency);

    constructor(
        address _creator,
        uint _goalAmount,
        uint _minDonation,
        uint _maxDonation,
        uint _endDate,
        string memory _currency,
        address _priceFeedAddress
    ) {
        require(_endDate > block.timestamp, "End date must be in the future");
        require(_goalAmount > 0, "Goal amount must be greater than 0");

        creator = _creator;
        goalAmount = _goalAmount;
        minDonation = _minDonation;
        maxDonation = _maxDonation;
        endDate = _endDate;
        currency = _currency;
        priceFeed = IPriceFeed(_priceFeedAddress);
        isGoalMet = false;
        isCampaignEnded = false;

        // Predefined list of supported currencies
        addSupportedCurrencies();
    }

    function addSupportedCurrencies() internal {
        // ETH
        tokenAddresses["ETH"] = address(0);
        // DAI
        tokenAddresses["DAI"] = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
        // USDC
        tokenAddresses["USDC"] = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
        // USDT
        tokenAddresses["USDT"] = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
        // WBTC
        tokenAddresses["WBTC"] = 0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599;
        // LINK
        tokenAddresses["LINK"] = 0x514910771AF9Ca656af840dff83E8264EcF986CA;
        // UNI
        tokenAddresses["UNI"] = 0xbb7119e85c5AafdDca2A41C77C5F48829d85C5D8;
        // MKR
        tokenAddresses["MKR"] = 0x9F8F72Aa9304c8B593d555f12ef6589cc30Db0D8;
        // SUSHI
        tokenAddresses["SUSHI"] = 0x0b3f868E0Be5597D5db7fEB59E1Ec4E3e8e9b8A0;
        // BAT
        tokenAddresses["BAT"] = 0x0D8775F648430679A709E98d2b0Cb6250d2887EF;
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

    function donate(string memory _currency) external payable campaignOngoing {
        uint donationInBaseCurrency = convertToBaseCurrency(
            msg.value,
            _currency
        );

        require(
            donationInBaseCurrency >= minDonation &&
                donationInBaseCurrency <= maxDonation,
            "Donation out of range"
        );
        require(
            totalContributionsAmount + donationInBaseCurrency <= goalAmount,
            "Donation exceeds goal"
        );

        contributions[msg.sender] += donationInBaseCurrency;
        donorCurrencies[msg.sender] = _currency;
        totalContributionsAmount += donationInBaseCurrency;

        emit DonationReceived(msg.sender, msg.value, _currency);

        if (totalContributionsAmount >= goalAmount) {
            isGoalMet = true;
            isCampaignEnded = true;
        }
    }

    function convertToBaseCurrency(
        uint amount,
        string memory _currency
    ) internal view returns (uint) {
        if (
            keccak256(abi.encodePacked(_currency)) ==
            keccak256(abi.encodePacked(currency))
        ) {
            return amount;
        }

        uint exchangeRate = priceFeed.getLatestPrice();
        return (amount * exchangeRate) / 1e18;
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

        string memory donationCurrency = donorCurrencies[msg.sender];
        address tokenAddress = tokenAddresses[donationCurrency];

        if (tokenAddress == address(0)) {
            // Refund in native currency
            payable(msg.sender).transfer(contributedAmount);
        } else {
            // Refund in other ERC-20 token
            IERC20 token = IERC20(tokenAddress);
            require(
                token.transfer(msg.sender, contributedAmount),
                "Token transfer failed"
            );
        }

        emit RefundIssued(msg.sender, contributedAmount, donationCurrency);
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
