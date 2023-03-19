const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers")

describe ("Staking", () => {

    let S, RT, ST, amount, user;

    beforeEach(async () => {
        const RewardTokens = await ethers.getContractFactory("RewardTokens");
        const StakingTokens = await ethers.getContractFactory("StakingTokens");
        const Staking = await ethers.getContractFactory("Staking");
    
        RT = await RewardTokens.deploy();
        ST = await StakingTokens.deploy();
        S = await Staking.deploy(ST.address, RT.address);

        amount = await ethers.utils.parseEther("100000");

        const accounts = await ethers.getSigners();
        user = accounts[0];
    });
    
    describe('constructor', () => { 
        it("checking the addresses of staking and rewards token", async () => {
            const stakingTokenAddress = await S.stakingToken(); 
            const rewardsTokenAddress = await S.rewardsToken(); 
            
            assert.equal(stakingTokenAddress, ST.address);
            assert.equal(rewardsTokenAddress, RT.address);
        });
    });

    describe('stake', () => { 
        
        it("when no time has passed", async () => { 
            await ST.approve(S.address, amount);
            await S.stake(amount);
            const earnedByUser = await S.rewardEarned(user.address);
            assert.equal(earnedByUser, 0);
        });
        
        it("when some time has passed", async () => { 
            await ST.approve(S.address, amount);
            await S.stake(amount);
            
            await time.increase(86400);
            const earnedByUser = await S.rewardEarned(user.address);
            const expected = 8600000;
            assert.equal(earnedByUser, expected);
            
        });
        
        it("checking user's balance", async () => {
            await ST.approve(S.address, amount);
            await S.stake(amount);
            
            const userBalance = await S.stakedTokensAmount(user.address);
            expect(userBalance).to.equal(amount);
        });
    });
    
    describe('unstake', () => { 
        it("checking user's balance after withdrawing tokens", async () => {
            await ST.approve(S.address, amount);
            await S.stake(amount);
            
            const unstakedAmount = amount.sub(1000);
            await S.unstake(unstakedAmount);
            
            const userBalance = await S.stakedTokensAmount(user.address);
            expect(userBalance).to.equal(amount.sub(unstakedAmount));
            
        });
        
        it("withdrawing 0 amount", async () => {
            await ST.approve(S.address, amount);
            await S.stake(amount);
            
            await expect(S.unstake(0)).to.be.revertedWith("Amount should be greater than 0");
            
        });

        it("withdrawing greater amount than staked", async () => {
            await ST.approve(S.address, amount);
            await S.stake(amount);
            
            const unstakedAmount = await ethers.utils.parseEther("100010");
            
            await expect(S.unstake(unstakedAmount)).to.be.revertedWith("amount > staked amount");
        });
    });
    
    
    describe('claimReward', () => { 
        it("claiming reward twice together", async () => {
            await ST.approve(S.address, amount);
            await RT.transfer(S.address, amount);
            await S.stake(amount);
            
            await time.increase(86400);
            await S.claimReward();
            
            // claiming reward again
            await expect(S.claimReward()).to.be.revertedWith("no rewards to claim");
        });
        
    });
    
});