// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import {MockUSD6} from "../src/MockUSD6.sol";
import {MockUSD18} from "../src/MockUSD18.sol";
import {DualPoolAMM} from "../src/DualPoolAMM.sol";
import {ArbExecutor} from "../src/ArbExecutor.sol";

contract DeployAll is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(pk);

        vm.startBroadcast(pk);

        MockUSD6 usd6 = new MockUSD6(deployer);
        MockUSD18 usd18 = new MockUSD18(deployer);
        DualPoolAMM amm = new DualPoolAMM(deployer);

        // Approvals for pool seeding
        usd6.approve(address(amm), type(uint256).max);
        usd18.approve(address(amm), type(uint256).max);

        // Pool A: 1:1
        amm.seedPoolA(address(usd18), address(usd6), 10_000 * 1e18, 10_000 * 1e6);
        // Pool B: 1:1.05
        amm.seedPoolB(address(usd18), address(usd6), 10_000 * 1e18, 10_500 * 1e6);

        ArbExecutor arb = new ArbExecutor(address(amm), address(usd18), address(usd6), deployer);

        // Fund the bot with token1 (usd6)
        usd6.transfer(address(arb), 1_000 * 1e6);

        vm.stopBroadcast();

        console.log("MockUSD6:", address(usd6));
        console.log("MockUSD18:", address(usd18));
        console.log("DualPoolAMM:", address(amm));
        console.log("ArbExecutor:", address(arb));
    }
}
