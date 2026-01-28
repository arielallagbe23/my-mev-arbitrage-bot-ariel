// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSD18
 * @notice Stablecoin mock 18 decimals pour tests Sepolia.
 */
contract MockUSD18 is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Mock USD 18", "mUSD18") Ownable(initialOwner) {
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
