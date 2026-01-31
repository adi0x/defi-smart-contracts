// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IStaking {
    function stake(uint256 amount) external;
    function unstake() external;
    function calculateRewards(address user) external view returns (uint256);
}

contract YieldAggregator {
    
    address public owner;
    IERC20 public token;
    
    struct Pool {
        address stakingContract;
        uint256 apy;
        bool isActive;
    }
    
    mapping(uint256 => Pool) public pools;
    mapping(address => uint256) public userDeposits;
    mapping(address => uint256) public userPool;
    
    uint256 public poolCount;
    uint256 public totalDeposits;
    
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event PoolAdded(uint256 indexed poolId, address stakingContract, uint256 apy);
    event FundsRebalanced(uint256 fromPool, uint256 toPool, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }
    
    function addPool(address _stakingContract, uint256 _apy) external onlyOwner {
        poolCount++;
        pools[poolCount] = Pool({
            stakingContract: _stakingContract,
            apy: _apy,
            isActive: true
        });
        
        emit PoolAdded(poolCount, _stakingContract, _apy);
    }
    
    function deposit(uint256 _amount) external {
        require(_amount > 0, "Amount must be > 0");
        require(poolCount > 0, "No pools available");
        
        token.transferFrom(msg.sender, address(this), _amount);
        
        userDeposits[msg.sender] += _amount;
        totalDeposits += _amount;
        
        uint256 bestPool = findBestPool();
        userPool[msg.sender] = bestPool;
        
        token.approve(pools[bestPool].stakingContract, _amount);
        IStaking(pools[bestPool].stakingContract).stake(_amount);
        
        emit Deposited(msg.sender, _amount);
    }
    
    function withdraw() external {
        uint256 amount = userDeposits[msg.sender];
        require(amount > 0, "No deposits");
        
        uint256 poolId = userPool[msg.sender];
        IStaking(pools[poolId].stakingContract).unstake();
        
        uint256 balance = token.balanceOf(address(this));
        require(token.transfer(msg.sender, balance), "Transfer failed");
        
        totalDeposits -= amount;
        userDeposits[msg.sender] = 0;
        
        emit Withdrawn(msg.sender, balance);
    }
    
    function findBestPool() public view returns (uint256) {
        uint256 bestPool = 1;
        uint256 highestAPY = 0;
        
        for (uint256 i = 1; i <= poolCount; i++) {
            if (pools[i].isActive && pools[i].apy > highestAPY) {
                highestAPY = pools[i].apy;
                bestPool = i;
            }
        }
        
        return bestPool;
    }
    
    function rebalance(address _user) external onlyOwner {
        uint256 currentPool = userPool[_user];
        uint256 bestPool = findBestPool();
        
        require(currentPool != bestPool, "Already in best pool");
        
        uint256 amount = userDeposits[_user];
        
        IStaking(pools[currentPool].stakingContract).unstake();
        
        token.approve(pools[bestPool].stakingContract, amount);
        IStaking(pools[bestPool].stakingContract).stake(amount);
        
        userPool[_user] = bestPool;
        
        emit FundsRebalanced(currentPool, bestPool, amount);
    }
    
    function getUserInfo(address _user) external view returns (
        uint256 depositAmount,
        uint256 currentPoolId,
        uint256 currentAPY
    ) {
        depositAmount = userDeposits[_user];
        currentPoolId = userPool[_user];
        currentAPY = pools[currentPoolId].apy;
    }
    
    function updatePoolAPY(uint256 _poolId, uint256 _newAPY) external onlyOwner {
        require(_poolId > 0 && _poolId <= poolCount, "Invalid pool");
        pools[_poolId].apy = _newAPY;
    }
}
