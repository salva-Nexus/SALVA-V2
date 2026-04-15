// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title MockUSDC
 * @dev Minimal ERC20 for Salva testing.
 * Note: USDC uses 6 decimals, so we override the default 18.
 */
contract MockUSDC is ERC20, Ownable {
    constructor() ERC20("Mock USDC", "mUSDC") Ownable(msg.sender) {
        // Mint 1 million tokens to the deployer initially
        _mint(msg.sender, 1_000_000 * 10 ** decimals());
    }

    /**
     * @dev USDC uses 6 decimals.
     */
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    /**
     * @dev Simple mint function so you can fund your Safe wallets
     * during development/testing.
     */
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
