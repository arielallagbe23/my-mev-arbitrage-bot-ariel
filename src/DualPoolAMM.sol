// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DualPoolAMM
 * @notice AMM minimal avec 2 pools indépendants pour démontrer un écart de prix.
 */
contract DualPoolAMM is Ownable {
    error PoolAlreadyInitialized(uint256 poolId);
    error PoolNotInitialized(uint256 poolId);
    error InvalidToken(address token);
    error InsufficientOutput(uint256 minOut, uint256 actualOut);

    struct Pool {
        address token0;
        address token1;
        uint256 reserve0;
        uint256 reserve1;
    }

    uint256 public constant FEE_DENOM = 10_000;
    uint256 public feeBps = 30; // 0.30%

    Pool public poolA;
    Pool public poolB;

    event PoolSeeded(uint256 indexed poolId, address token0, address token1, uint256 amount0, uint256 amount1);
    event Swap(
        uint256 indexed poolId,
        address indexed trader,
        address tokenIn,
        uint256 amountIn,
        address tokenOut,
        uint256 amountOut
    );

    constructor(address initialOwner) Ownable(initialOwner) {}

    function setFeeBps(uint256 newFeeBps) external onlyOwner {
        require(newFeeBps <= 100, "fee too high");
        feeBps = newFeeBps;
    }

    function seedPoolA(address token0, address token1, uint256 amount0, uint256 amount1) external onlyOwner {
        _seedPool(1, token0, token1, amount0, amount1);
    }

    function seedPoolB(address token0, address token1, uint256 amount0, uint256 amount1) external onlyOwner {
        _seedPool(2, token0, token1, amount0, amount1);
    }

    function _seedPool(uint256 poolId, address token0, address token1, uint256 amount0, uint256 amount1) internal {
        Pool storage pool = _pool(poolId);
        if (pool.reserve0 != 0 || pool.reserve1 != 0) {
            revert PoolAlreadyInitialized(poolId);
        }
        IERC20(token0).transferFrom(msg.sender, address(this), amount0);
        IERC20(token1).transferFrom(msg.sender, address(this), amount1);

        pool.token0 = token0;
        pool.token1 = token1;
        pool.reserve0 = amount0;
        pool.reserve1 = amount1;

        emit PoolSeeded(poolId, token0, token1, amount0, amount1);
    }

    function swap(uint256 poolId, address tokenIn, uint256 amountIn, uint256 minOut, address to)
        external
        returns (uint256 amountOut)
    {
        Pool storage pool = _pool(poolId);
        if (pool.reserve0 == 0 || pool.reserve1 == 0) {
            revert PoolNotInitialized(poolId);
        }

        bool zeroToOne;
        if (tokenIn == pool.token0) {
            zeroToOne = true;
        } else if (tokenIn == pool.token1) {
            zeroToOne = false;
        } else {
            revert InvalidToken(tokenIn);
        }

        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);

        uint256 amountInWithFee = (amountIn * (FEE_DENOM - feeBps)) / FEE_DENOM;

        if (zeroToOne) {
            amountOut = _getAmountOut(amountInWithFee, pool.reserve0, pool.reserve1);
            if (amountOut < minOut) revert InsufficientOutput(minOut, amountOut);
            pool.reserve0 = pool.reserve0 + amountIn;
            pool.reserve1 = pool.reserve1 - amountOut;
            IERC20(pool.token1).transfer(to, amountOut);
            emit Swap(poolId, msg.sender, pool.token0, amountIn, pool.token1, amountOut);
        } else {
            amountOut = _getAmountOut(amountInWithFee, pool.reserve1, pool.reserve0);
            if (amountOut < minOut) revert InsufficientOutput(minOut, amountOut);
            pool.reserve1 = pool.reserve1 + amountIn;
            pool.reserve0 = pool.reserve0 - amountOut;
            IERC20(pool.token0).transfer(to, amountOut);
            emit Swap(poolId, msg.sender, pool.token1, amountIn, pool.token0, amountOut);
        }
    }

    function quoteOut(uint256 poolId, address tokenIn, uint256 amountIn) external view returns (uint256 amountOut) {
        Pool memory pool = _poolView(poolId);
        if (pool.reserve0 == 0 || pool.reserve1 == 0) {
            revert PoolNotInitialized(poolId);
        }

        uint256 amountInWithFee = (amountIn * (FEE_DENOM - feeBps)) / FEE_DENOM;

        if (tokenIn == pool.token0) {
            amountOut = _getAmountOut(amountInWithFee, pool.reserve0, pool.reserve1);
        } else if (tokenIn == pool.token1) {
            amountOut = _getAmountOut(amountInWithFee, pool.reserve1, pool.reserve0);
        } else {
            revert InvalidToken(tokenIn);
        }
    }

    function poolPrice(uint256 poolId) external view returns (uint256 priceToken0InToken1) {
        Pool memory pool = _poolView(poolId);
        if (pool.reserve0 == 0 || pool.reserve1 == 0) {
            revert PoolNotInitialized(poolId);
        }
        return (pool.reserve1 * 1e18) / pool.reserve0;
    }

    function _getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut)
        internal
        pure
        returns (uint256)
    {
        return (reserveOut * amountIn) / (reserveIn + amountIn);
    }

    function _pool(uint256 poolId) internal view returns (Pool storage) {
        if (poolId == 1) return poolA;
        if (poolId == 2) return poolB;
        revert PoolNotInitialized(poolId);
    }

    function _poolView(uint256 poolId) internal view returns (Pool memory) {
        if (poolId == 1) return poolA;
        if (poolId == 2) return poolB;
        revert PoolNotInitialized(poolId);
    }
}
