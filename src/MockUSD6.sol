// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title MockUSD6
 * @notice Stablecoin mock 6 decimals pour tests Sepolia.
 */
contract MockUSD6 is ERC20, Ownable {
    constructor(address initialOwner) ERC20("Mock USD 6", "mUSD6") Ownable(initialOwner) {
        _mint(initialOwner, 1_000_000 * 10 ** decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
