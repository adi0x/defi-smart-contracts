// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * SimpleSwap - A Mini Decentralized Exchange (DEX)
 * 
 * What this does:
 * - Swaps Token A for Token B at a fixed rate (1:2)
 * - You provide liquidity (both tokens)
 * - Users can swap back and forth
 * 
 * This teaches you how Uniswap works!
 */

contract SimpleSwap {
    
    // The two tokens we're swapping
    address public tokenA;  // Your AdithiToken
    address public tokenB;  // You'll deploy a second token
    
    // Exchange rate: 1 Token A = 2 Token B
    uint256 public rate = 2;
    
    // Track liquidity provider (you)
    address public owner;
    
    // Events
    event Swap(
        address indexed user,
        address indexed fromToken,
        address indexed toToken,
        uint256 amountIn,
        uint256 amountOut
    );
    
    event LiquidityAdded(
        address indexed provider,
        uint256 amountA,
        uint256 amountB
    );
    
    
    constructor(address _tokenA, address _tokenB) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        owner = msg.sender;
    }
    
    
    /**
     * ADD LIQUIDITY
     * Owner adds both tokens to enable swapping
     * 
     * Example: Add 10,000 Token A and 20,000 Token B
     * Now users can swap between them
     */
    function addLiquidity(uint256 _amountA, uint256 _amountB) external {
        require(msg.sender == owner, "Only owner can add liquidity");
        
        // Transfer Token A from owner to contract
        (bool successA, ) = tokenA.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                _amountA
            )
        );
        require(successA, "Token A transfer failed");
        
        // Transfer Token B from owner to contract
        (bool successB, ) = tokenB.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                _amountB
            )
        );
        require(successB, "Token B transfer failed");
        
        emit LiquidityAdded(msg.sender, _amountA, _amountB);
    }
    
    
    /**
     * SWAP A FOR B
     * Give Token A, get Token B
     * 
     * Example: Give 100 Token A → Get 200 Token B
     * 
     * Rate: 1:2 (fixed)
     */
    function swapAForB(uint256 _amountA) external {
        require(_amountA > 0, "Amount must be > 0");
        
        // Calculate how much Token B to give
        uint256 amountB = _amountA * rate;
        
        // Check contract has enough Token B
        (bool checkSuccess, bytes memory balanceData) = tokenB.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(checkSuccess, "Balance check failed");
        uint256 contractBalanceB = abi.decode(balanceData, (uint256));
        require(contractBalanceB >= amountB, "Insufficient Token B liquidity");
        
        // Transfer Token A from user to contract
        (bool successA, ) = tokenA.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                _amountA
            )
        );
        require(successA, "Token A transfer failed");
        
        // Transfer Token B from contract to user
        (bool successB, ) = tokenB.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                amountB
            )
        );
        require(successB, "Token B transfer failed");
        
        emit Swap(msg.sender, tokenA, tokenB, _amountA, amountB);
    }
    
    
    /**
     * SWAP B FOR A
     * Give Token B, get Token A
     * 
     * Example: Give 200 Token B → Get 100 Token A
     * 
     * Rate: 2:1 (reverse of above)
     */
    function swapBForA(uint256 _amountB) external {
        require(_amountB > 0, "Amount must be > 0");
        require(_amountB % rate == 0, "Amount must be divisible by rate");
        
        // Calculate how much Token A to give
        uint256 amountA = _amountB / rate;
        
        // Check contract has enough Token A
        (bool checkSuccess, bytes memory balanceData) = tokenA.call(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(checkSuccess, "Balance check failed");
        uint256 contractBalanceA = abi.decode(balanceData, (uint256));
        require(contractBalanceA >= amountA, "Insufficient Token A liquidity");
        
        // Transfer Token B from user to contract
        (bool successB, ) = tokenB.call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                msg.sender,
                address(this),
                _amountB
            )
        );
        require(successB, "Token B transfer failed");
        
        // Transfer Token A from contract to user
        (bool successA, ) = tokenA.call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                msg.sender,
                amountA
            )
        );
        require(successA, "Token A transfer failed");
        
        emit Swap(msg.sender, tokenB, tokenA, _amountB, amountA);
    }
    
    
    /**
     * GET LIQUIDITY
     * Check how much of each token is in the pool
     */
    function getLiquidity() external view returns (uint256 balanceA, uint256 balanceB) {
        (bool successA, bytes memory dataA) = tokenA.staticcall(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(successA, "Failed to get Token A balance");
        balanceA = abi.decode(dataA, (uint256));
        
        (bool successB, bytes memory dataB) = tokenB.staticcall(
            abi.encodeWithSignature("balanceOf(address)", address(this))
        );
        require(successB, "Failed to get Token B balance");
        balanceB = abi.decode(dataB, (uint256));
    }
    
    
    /**
     * GET SWAP PREVIEW
     * See how much you'll get before swapping
     */
    function getSwapPreviewAForB(uint256 _amountA) external view returns (uint256) {
        return _amountA * rate;
    }
    
    function getSwapPreviewBForA(uint256 _amountB) external view returns (uint256) {
        return _amountB / rate;
    }
}
