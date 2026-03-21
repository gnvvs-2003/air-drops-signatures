// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BagelToken
 * @author gnvvs-2003
 * @notice This contract is a standard ERC20 token
 * @notice This contract only supports minting functionality since it is an airdrop contract
 */

contract BagelToken is ERC20, Ownable {
    /// @notice ERC20 token name : Bagel
    /// @notice ERC20 token symbol : BAGEL
    /// @notice Ownable(msg.sender) sets the deployer of the contract i.e msg.sender as the initial owner
    constructor() ERC20("Bagel", "BAGEL") Ownable(msg.sender) {}

    /// @param to To address
    /// @param amount amount of tokens to be minted to `to` address
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}