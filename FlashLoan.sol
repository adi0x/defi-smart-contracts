// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

interface IFlashLoanReceiver {
    function executeOperation(
        address token,
        uint256 amount,
        uint256 fee,
        bytes calldata params
    ) external returns (bool);
}

contract FlashLoan {
    
    address public owner;
    IERC20 public token;
    
    uint256 public constant FLASH_LOAN_FEE = 9;
    uint256 public poolBalance;
    
    event FlashLoanExecuted(address indexed borrower, uint256 amount, uint256 fee, uint256 timestamp);
    event PoolFunded(address indexed funder, uint256 amount);
    event FeesWithdrawn(address indexed owner, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(address _tokenAddress) {
        owner = msg.sender;
        token = IERC20(_tokenAddress);
    }
    
    function addLiquidity(uint256 _amount) external {
        require(_amount > 0, "Amount must be > 0");
        require(token.transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        
        poolBalance += _amount;
        
        emit PoolFunded(msg.sender, _amount);
    }
    
    function flashLoan(
        address _receiver,
        uint256 _amount,
        bytes calldata _params
    ) external {
        require(_amount > 0, "Amount must be > 0");
        require(_amount <= poolBalance, "Insufficient liquidity");
        
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= _amount, "Pool has insufficient balance");
        
        uint256 fee = (_amount * FLASH_LOAN_FEE) / 10000;
        
        require(token.transfer(_receiver, _amount), "Loan transfer failed");
        
        require(
            IFlashLoanReceiver(_receiver).executeOperation(
                address(token),
                _amount,
                fee,
                _params
            ),
            "Flash loan execution failed"
        );
        
        uint256 balanceAfter = token.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore + fee,
            "Flash loan not repaid with fee"
        );
        
        poolBalance = balanceAfter;
        
        emit FlashLoanExecuted(msg.sender, _amount, fee, block.timestamp);
    }
    
    function getPoolBalance() external view returns (uint256) {
        return poolBalance;
    }
    
    function withdrawFees() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > poolBalance, "No fees to withdraw");
        
        uint256 fees = balance - poolBalance;
        require(token.transfer(owner, fees), "Transfer failed");
        
        emit FeesWithdrawn(owner, fees);
    }
    
    function emergencyWithdraw() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No balance");
        require(token.transfer(owner, balance), "Transfer failed");
        poolBalance = 0;
    }
}

contract SimpleFlashLoanReceiver is IFlashLoanReceiver {
    
    address public flashLoanContract;
    IERC20 public token;
    
    event OperationExecuted(uint256 amount, uint256 fee);
    
    constructor(address _flashLoanContract, address _token) {
        flashLoanContract = _flashLoanContract;
        token = IERC20(_token);
    }
    
    function executeOperation(
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params
    ) external override returns (bool) {
        require(msg.sender == flashLoanContract, "Only flash loan contract");
        
        uint256 totalDebt = _amount + _fee;
        
        require(
            token.approve(flashLoanContract, totalDebt),
            "Approval failed"
        );
        
        emit OperationExecuted(_amount, _fee);
        
        return true;
    }
    
    function requestFlashLoan(uint256 _amount) external {
        bytes memory params = "";
        FlashLoan(flashLoanContract).flashLoan(address(this), _amount, params);
    }
}
