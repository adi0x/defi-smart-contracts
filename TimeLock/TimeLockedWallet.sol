// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title TimeLockedWallet
 * @dev A wallet that locks funds until a specific timestamp
 * Use case: Vesting, savings, treasury management
 */
contract TimeLockedWallet {
    
    address public owner;
    uint256 public unlockTime;
    bool public emergencyUnlocked;
    
    event Deposit(address indexed sender, uint256 amount, uint256 timestamp);
    event Withdrawal(address indexed recipient, uint256 amount, uint256 timestamp);
    event UnlockTimeExtended(uint256 oldTime, uint256 newTime);
    event EmergencyUnlock(address indexed by, uint256 timestamp);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this");
        _;
    }
    
    modifier canWithdraw() {
        require(
            block.timestamp >= unlockTime || emergencyUnlocked,
            "Funds are still locked"
        );
        _;
    }
    
    /**
     * @dev Constructor sets owner and unlock time
     * @param _unlockTime Unix timestamp when funds can be withdrawn
     */
    constructor(uint256 _unlockTime) {
        require(_unlockTime > block.timestamp, "Unlock time must be in future");
        owner = msg.sender;
        unlockTime = _unlockTime;
        emergencyUnlocked = false;
    }
    
    /**
     * @dev Deposit ETH into the wallet
     */
    function deposit() external payable {
        require(msg.value > 0, "Must deposit some ETH");
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Allow contract to receive ETH directly
     */
    receive() external payable {
        emit Deposit(msg.sender, msg.value, block.timestamp);
    }
    
    /**
     * @dev Withdraw all funds (only after unlock time or emergency unlock)
     */
    function withdraw() external onlyOwner canWithdraw {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        // Use call instead of transfer for safety
        (bool success, ) = owner.call{value: balance}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(owner, balance, block.timestamp);
    }
    
    /**
     * @dev Withdraw specific amount (only after unlock time or emergency unlock)
     */
    function withdrawAmount(uint256 _amount) external onlyOwner canWithdraw {
        require(_amount > 0, "Amount must be greater than 0");
        require(address(this).balance >= _amount, "Insufficient balance");
        
        (bool success, ) = owner.call{value: _amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(owner, _amount, block.timestamp);
    }
    
    /**
     * @dev Extend the lock time (can only make it longer, not shorter)
     */
    function extendLockTime(uint256 _newUnlockTime) external onlyOwner {
        require(_newUnlockTime > unlockTime, "Can only extend, not shorten");
        require(!emergencyUnlocked, "Already emergency unlocked");
        
        uint256 oldTime = unlockTime;
        unlockTime = _newUnlockTime;
        
        emit UnlockTimeExtended(oldTime, _newUnlockTime);
    }
    
    /**
     * @dev Emergency unlock - allows immediate withdrawal
     * WARNING: This is irreversible!
     */
    function emergencyUnlock() external onlyOwner {
        require(!emergencyUnlocked, "Already unlocked");
        emergencyUnlocked = true;
        emit EmergencyUnlock(msg.sender, block.timestamp);
    }
    
    /**
     * @dev Get remaining lock time in seconds
     */
    function getRemainingLockTime() external view returns (uint256) {
        if (block.timestamp >= unlockTime || emergencyUnlocked) {
            return 0;
        }
        return unlockTime - block.timestamp;
    }
    
    /**
     * @dev Check if funds are currently locked
     */
    function isLocked() external view returns (bool) {
        return block.timestamp < unlockTime && !emergencyUnlocked;
    }
    
    /**
     * @dev Get contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
