// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IDualPoolAMM {
    function swap(uint256 poolId, address tokenIn, uint256 amountIn, uint256 minOut, address to)
        external
        returns (uint256 amountOut);
    function quoteOut(uint256 poolId, address tokenIn, uint256 amountIn) external view returns (uint256 amountOut);
    function poolPrice(uint256 poolId) external view returns (uint256 priceToken0InToken1);
}

/**
 * @title ArbExecutor
 * @notice Exécuteur on-chain d'arbitrage entre deux pools.
 */
contract ArbExecutor {
    error NotOwner();
    error NotProfitable(uint256 profit, uint256 minProfit);

    address public immutable dex;
    address public immutable token0;
    address public immutable token1;
    address public owner;

    event ArbitrageRun(uint256 amountIn, uint256 profit, uint256 poolBuy, uint256 poolSell);

    constructor(address _dex, address _token0, address _token1, address _owner) {
        dex = _dex;
        token0 = _token0;
        token1 = _token1;
        owner = _owner;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    function run(uint256 amountInToken1, uint256 minProfitToken1) external onlyOwner returns (uint256 profit) {
        IDualPoolAMM amm = IDualPoolAMM(dex);

        uint256 priceA = amm.poolPrice(1);
        uint256 priceB = amm.poolPrice(2);

        uint256 balanceBefore = IERC20(token1).balanceOf(address(this));

        if (priceA < priceB) {
            profit = _arb(amm, 1, 2, amountInToken1);
            emit ArbitrageRun(amountInToken1, profit, 1, 2);
        } else {
            profit = _arb(amm, 2, 1, amountInToken1);
            emit ArbitrageRun(amountInToken1, profit, 2, 1);
        }

        uint256 balanceAfter = IERC20(token1).balanceOf(address(this));
        uint256 netProfit = balanceAfter > balanceBefore ? balanceAfter - balanceBefore : 0;

        if (netProfit < minProfitToken1) {
            revert NotProfitable(netProfit, minProfitToken1);
        }
        return netProfit;
    }

    function _arb(IDualPoolAMM amm, uint256 buyPool, uint256 sellPool, uint256 amountInToken1)
        internal
        returns (uint256)
    {
        IERC20(token1).approve(dex, amountInToken1);

        uint256 minOut0 = (amm.quoteOut(buyPool, token1, amountInToken1) * 995) / 1000;
        uint256 amountToken0 = amm.swap(buyPool, token1, amountInToken1, minOut0, address(this));

        IERC20(token0).approve(dex, amountToken0);

        uint256 minOut1 = (amm.quoteOut(sellPool, token0, amountToken0) * 995) / 1000;
        uint256 amountToken1Out = amm.swap(sellPool, token0, amountToken0, minOut1, address(this));

        return amountToken1Out > amountInToken1 ? amountToken1Out - amountInToken1 : 0;
    }

    function deposit(address token, uint256 amount) external onlyOwner {
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).transfer(msg.sender, amount);
    }
}
