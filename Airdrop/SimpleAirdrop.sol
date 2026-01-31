// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract SimpleAirdrop {
    
    address public owner;
    IERC20 public token;
    
    mapping(address => bool) public hasClaimed;
    
    uint256 public airdropAmount;
    bool public isActive;
    
    event AirdropClaimed(address indexed recipient, uint256 amount);
    event AirdropStarted(address indexed token, uint256 amount);
    event AirdropStopped();
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        isActive = false;
    }
    
    function startAirdrop(address _tokenAddress, uint256 _airdropAmount) external onlyOwner {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_airdropAmount > 0, "Amount must be > 0");
        
        token = IERC20(_tokenAddress);
        airdropAmount = _airdropAmount;
        isActive = true;
        
        emit AirdropStarted(_tokenAddress, _airdropAmount);
    }
    
    function claim() external {
        require(isActive, "Airdrop not active");
        require(!hasClaimed[msg.sender], "Already claimed");
        require(token.balanceOf(address(this)) >= airdropAmount, "Insufficient tokens");
        
        hasClaimed[msg.sender] = true;
        require(token.transfer(msg.sender, airdropAmount), "Transfer failed");
        
        emit AirdropClaimed(msg.sender, airdropAmount);
    }
    
    function batchAirdrop(address[] calldata _recipients, uint256 _amount) external onlyOwner {
        require(_recipients.length > 0, "No recipients");
        require(_amount > 0, "Amount must be > 0");
        
        uint256 totalRequired = _recipients.length * _amount;
        require(token.balanceOf(address(this)) >= totalRequired, "Insufficient tokens");
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            require(token.transfer(_recipients[i], _amount), "Transfer failed");
            emit AirdropClaimed(_recipients[i], _amount);
        }
    }
    
    function stopAirdrop() external onlyOwner {
        isActive = false;
        emit AirdropStopped();
    }
    
    function withdrawTokens(address _tokenAddress) external onlyOwner {
        IERC20 tokenToWithdraw = IERC20(_tokenAddress);
        uint256 balance = tokenToWithdraw.balanceOf(address(this));
        require(balance > 0, "No tokens to withdraw");
        require(tokenToWithdraw.transfer(owner, balance), "Transfer failed");
    }
    
    function getContractTokenBalance() external view returns (uint256) {
        if (address(token) == address(0)) return 0;
        return token.balanceOf(address(this));
    }
}
