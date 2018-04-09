
pragma solidity ^0.4.19;

import './SafeMath.sol';

interface token { 
    function transfer(address receiver, uint amount) external ;
}

contract CustomCrowdSale {
    using SafeMath for uint256;
    
    token public tokenReward;
    address public beneficiary;
    uint256 public amountRaised;
    uint256 public minCap; // the ICO ether goal (in wei)
    uint256 public maxCap; // the ICO ether max cap (in wei)
    uint256 public startTimestamp; // timestamp after which ICO will start
    uint256 public duration; // duration of ICO
    uint256 public price;
    
    //mapping
    mapping(address => uint256) public balanceOf;
    
    //logic
    bool fundingGoalReached = false;
    bool crowdsaleClosed = false;
    
    //events
    event GoalReached(address recipient, uint totalAmountRaised);
    event FundTransfer(address backer, uint amount, bool isContribution);
    
    /**
    * Constrctor function
    */
    function CustomCrowdSale( 
        ) public {
        tokenReward = token(0xDD960d7747737721389aC28B4B95aAb24F714357); // place token contract address of the desired token to be issued. 
        beneficiary = 0xf9fE46227013EFBcc0255b4CEd93192Fe2F6a097; //place desired address eligible to withdraw eth from this contract.
        startTimestamp;
        price = 400000000000000 wei;
        minCap = 1400 ether;
        maxCap = 2800 ether;
        duration = 13 weeks;

    }
    
     modifier isIcoOpen() {
        require(now >= startTimestamp);
        require(now <= (startTimestamp.add(duration)) || amountRaised < minCap);
        require(amountRaised <= maxCap);
        _;
    }
    
    /**
     * Fallback function
     * The function without name is the default function that is called whenever anyone sends funds to a contract.
     */
    function () internal isIcoOpen payable {        
        require(!crowdsaleClosed);      // Crowdsale must still be open.
        uint256 amount = msg.value; //ether value sent from sender
        balanceOf[msg.sender] = balanceOf[msg.sender].add(amount);
        amountRaised = amountRaised.add(amount);
        tokenReward.transfer(msg.sender, (amount.div(price)) * 1 ether); // Transfer Reward tokens to purchaser.
        emit FundTransfer(msg.sender, amount, true);     // Trigger and publicly log event 
        beneficiary.transfer(msg.value); // immediately transfer ether to fundsWallet
    }

    modifier isIcoFinished() {
        require(now >= startTimestamp);
        require(amountRaised >= maxCap || (now >= (startTimestamp.add(duration)) && amountRaised >= minCap));
        _;
        crowdsaleClosed = true;          // End this crowdsale.
    }

    /**
     * Withdraw the funds
     *
     * Checks to see if goal or time limit has been reached, and if so, and the funding goal was reached,
     * sends the entire amount to the beneficiary. If goal was not reached beneficiary can withdraw available funds.
     */
    function safeWithdraw() public isIcoFinished {
        require (beneficiary == msg.sender); 
        withdraw();               // Beneficiary is allowed withdraw funds raised to beneficiary's account.
        emit FundTransfer(beneficiary, amountRaised, false);     // Trigger and publicly log event. 
        
    }
    
    function withdraw() internal {
        uint256 fund = amountRaised;
        amountRaised = 0;
        beneficiary.transfer(fund); // transfer all ether to beneficiary address.
    }

}