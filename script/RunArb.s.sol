// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {DualPoolAMM} from "../src/DualPoolAMM.sol";
import {ArbExecutor} from "../src/ArbExecutor.sol";

contract RunArb is Script {
    // Remplir après déploiement
    address constant AMM = 0x7E0cDd82a0F22382B18dCdB1c52F5F3fa99C7147;
    address constant BOT = 0x8A95e6b889542a9077787a1a9240161d4A5E5375;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        DualPoolAMM amm = DualPoolAMM(AMM);
        ArbExecutor bot = ArbExecutor(BOT);

        uint256 priceA = amm.poolPrice(1);
        uint256 priceB = amm.poolPrice(2);
        console.log("Price A (token1 per token0):", priceA / 1e6);
        console.log("Price B (token1 per token0):", priceB / 1e6);

        uint256 amountIn = 100 * 1e6;
        uint256 minProfit = 1 * 1e6; // 1 USD6 min

        uint256 profit = bot.run(amountIn, minProfit);
        console.log("Profit (token1):", profit / 1e6);

        vm.stopBroadcast();
    }
}
