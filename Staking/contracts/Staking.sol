//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "hardhat/console.sol";

contract Staking {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;
    
    // state variables
    uint public totalSupply;
    uint public lastUpdated;
    uint public rewardRate = 100;
    uint public rewardPerTokenStored;

    mapping (address => uint) public userRewardPerTokenPaid;
    mapping (address => uint) public rewards;
    mapping (address => uint) private stakedTokens;

    // events
    event staked (address indexed user, uint amount);
    event unstaked (address indexed user, uint amount);
    event rewardClaimed (address indexed user, uint amount);

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    } 
    
    // --- Modifiers ---
    // everytime a user stakes, withdraws or claim-Rewards following values are updated
    modifier updateReward(address _userAddress) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdated = block.timestamp;
        rewards[_userAddress] = rewardEarned(_userAddress);
        userRewardPerTokenPaid[_userAddress] = rewardPerTokenStored;
        _;
    }

    // --- Functions ---
    function stakedTokensAmount(address _userAddress)  external view returns (uint) {
        return (stakedTokens[_userAddress]);
    }

    function stake(uint _amount) external updateReward(msg.sender) {
        // require(msg.sender != address(0), "invalid address");
        require (_amount > 0, "Amount should be greater than 0");
        totalSupply += _amount;
        stakedTokens[msg.sender] += _amount;
        stakingToken.transferFrom(msg.sender, address(this), _amount);
        // emitting event
        emit staked(msg.sender, _amount);
    }

    function unstake(uint _amount) external updateReward(msg.sender) {
        require(stakedTokens[msg.sender] >= _amount, "amount > staked amount");
        require (_amount > 0, "Amount should be greater than 0");

        // console.log("msg.sender: %s,rewards[msg.sender]: %s", msg.sender, rewards[msg.sender]);

        totalSupply -= _amount;
        stakedTokens[msg.sender] -= _amount;
        // stakingToken.transfer(address(this), _amount);
        stakingToken.transfer(msg.sender, _amount);
        // emitting event
        emit unstaked(msg.sender, _amount);
    }


    function claimReward() external updateReward(msg.sender) {
        uint userReward = rewards[msg.sender];
        require (rewards[msg.sender] > 0, "no rewards to claim");
        // console.log("msg.sender: %s,rewards[msg.sender]: %s", msg.sender, rewards[msg.sender]);
        rewards[msg.sender] = 0;
        rewardsToken.transfer(msg.sender, userReward);
        // emitting event
        emit rewardClaimed(msg.sender, userReward);
    }

    function rewardPerToken() public view returns(uint) {
        if (totalSupply == 0) {
            return rewardPerTokenStored;
        }
        else {
            return (rewardPerTokenStored + (rewardRate * (block.timestamp - lastUpdated) * 1e18) / totalSupply);
        }
    }

    // total reward earned by the user from k(lastUpdated) to n(current) seconds
    function rewardEarned(address _userAccount) public view returns(uint) {
        return ((stakedTokens[_userAccount] * (rewardPerToken() - userRewardPerTokenPaid[_userAccount])) / 1e18 + rewards[_userAccount]);
    }

}
