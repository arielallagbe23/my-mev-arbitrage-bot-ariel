// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {MockUSD6} from "../src/MockUSD6.sol";
import {MockUSD18} from "../src/MockUSD18.sol";
import {DualPoolAMM} from "../src/DualPoolAMM.sol";
import {ArbExecutor} from "../src/ArbExecutor.sol";

contract ArbTest is Test {
    MockUSD6 internal usd6;
    MockUSD18 internal usd18;
    DualPoolAMM internal amm;
    ArbExecutor internal bot;

    function setUp() public {
        usd6 = new MockUSD6(address(this));
        usd18 = new MockUSD18(address(this));
        amm = new DualPoolAMM(address(this));

        usd6.approve(address(amm), type(uint256).max);
        usd18.approve(address(amm), type(uint256).max);

        // Pool A: 1:1
        amm.seedPoolA(address(usd18), address(usd6), 10_000 * 1e18, 10_000 * 1e6);
        // Pool B: 1:1.05
        amm.seedPoolB(address(usd18), address(usd6), 10_000 * 1e18, 10_500 * 1e6);

        bot = new ArbExecutor(address(amm), address(usd18), address(usd6), address(this));

        // Fund bot with token1 (usd6)
        usd6.transfer(address(bot), 1_000 * 1e6);
    }

    function test_pricesAreDifferent() public {
        uint256 priceA = amm.poolPrice(1);
        uint256 priceB = amm.poolPrice(2);
        assertLt(priceA, priceB);
    }

    function test_arbitrageIsProfitable() public {
        uint256 amountIn = 100 * 1e6;

        uint256 out0 = amm.quoteOut(1, address(usd6), amountIn);
        uint256 out1 = amm.quoteOut(2, address(usd18), out0);
        uint256 expectedProfit = out1 > amountIn ? out1 - amountIn : 0;

        assertGt(expectedProfit, 0);

        uint256 minProfit = (expectedProfit * 8) / 10; // 80% of expected
        uint256 profit = bot.run(amountIn, minProfit);

        assertGe(profit, minProfit);
    }

    function test_revertsWhenMinProfitTooHigh() public {
        uint256 amountIn = 100 * 1e6;
        uint256 out0 = amm.quoteOut(1, address(usd6), amountIn);
        uint256 out1 = amm.quoteOut(2, address(usd18), out0);
        uint256 expectedProfit = out1 > amountIn ? out1 - amountIn : 0;
        uint256 minProfit = 1_000_000 * 1e6;

        vm.expectRevert(
            abi.encodeWithSelector(ArbExecutor.NotProfitable.selector, expectedProfit, minProfit)
        );
        bot.run(amountIn, minProfit);
    }
}
