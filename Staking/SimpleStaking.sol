// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * SimpleStaking Contract
 * 
 * What this does:
 * - Users deposit (stake) tokens
 * - They earn 10% rewards per year
 * - They can withdraw anytime with rewards
 */

contract SimpleStaking {
    
    // The token users will stake (your MinimalToken address)
    address public tokenAddress;
    
    // Reward rate: 10% per year = 10
    uint256 public rewardRate = 10;
    
    // Track each user's stake
    struct Stake {
        uint256 amount;        // How many tokens staked
        uint256 startTime;     // When they started staking
    }
    
    // Mapping: user address => their stake info
    mapping(address => Stake) public stakes;
    
    // Events
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount, uint256 reward);
    
    
    constructor(address _tokenAddress) {
        tokenAddress = _tokenAddress;
    }
    
    
    /**
     * STAKE FUNCTION
     * User deposits tokens to start earning rewards
     */
    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");
        
        // If already staking, claim rewards first
        if (stakes[msg.sender].amount > 0) {
            uint256 reward = calculateReward(msg.sender);
            if (reward > 0) {
                // Transfer reward (simplified - in real contract would mint or have reserve)
                stakes[msg.sender].amount += reward;
            }
        }
        
        // Transfer tokens from user to this contract
        // Note: User must approve this contract first!
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                _amount
            )
        );
        require(success, "Transfer failed");
        
        // Update stake
        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].startTime = block.timestamp;
        
        emit Staked(msg.sender, _amount);
    }
    
    
    /**
     * CALCULATE REWARD
     * How much reward has user earned so far?
     * 
     * Formula: (amount * rate * timeStaked) / (365 days * 100)
     * 
     * Example: 
     * - Stake 1000 tokens
     * - Rate 10%
     * - Time: 182.5 days (half year)
     * - Reward: (1000 * 10 * 182.5 days) / (365 days * 100) = 50 tokens
     */
    function calculateReward(address _user) public view returns (uint256) {
        Stake memory userStake = stakes[_user];
        
        if (userStake.amount == 0) {
            return 0;
        }
        
        uint256 timeStaked = block.timestamp - userStake.startTime;
        uint256 reward = (userStake.amount * rewardRate * timeStaked) / (365 days * 100);
        
        return reward;
    }
    
    
    /**
     * UNSTAKE FUNCTION
     * User withdraws all tokens + rewards
     */
    function unstake() external {
        require(stakes[msg.sender].amount > 0, "No stake found");
        
        // Calculate total (staked + rewards)
        uint256 stakedAmount = stakes[msg.sender].amount;
        uint256 reward = calculateReward(msg.sender);
        uint256 total = stakedAmount + reward;
        
        // Reset stake
        stakes[msg.sender].amount = 0;
        stakes[msg.sender].startTime = 0;
        
        // Transfer tokens back to user
        (bool success, ) = tokenAddress.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                total
            )
        );
        require(success, "Transfer failed");
        
        emit Unstaked(msg.sender, stakedAmount, reward);
    }
    
    
    /**
     * GET STAKE INFO
     * Check user's stake and pending rewards
     */
    function getStakeInfo(address _user) external view returns (
        uint256 stakedAmount,
        uint256 pendingReward,
        uint256 stakingTime
    ) {
        stakedAmount = stakes[_user].amount;
        pendingReward = calculateReward(_user);
        stakingTime = stakes[_user].startTime;
    }
}
