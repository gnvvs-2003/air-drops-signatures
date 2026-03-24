// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 private S_MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 private S_AMOUNT_TO_TRANSFER = 4 * 25 * 1e18; // 4 users

    /// run function
    function run() external returns (MerkleAirdrop, BagelToken) {
        return deployMerkleAirdrop();
    }

    /// PUBLIC FUNCTIONS

    /**
     * @return MerkleAirdrop
     * @return BagelToken
     * @notice Initially mints the tokens to the owner of the token
     * @notice Then transfers the tokens to the airdrop contract
     * @custom:deploy This function deploys the contracts
     */

    function deployMerkleAirdrop() public returns (MerkleAirdrop, BagelToken) {
        vm.startBroadcast();
        BagelToken token = new BagelToken();
        MerkleAirdrop airdrop = new MerkleAirdrop(S_MERKLE_ROOT, IERC20(address(token)));
        // mint tokens
        token.mint(token.owner(), S_AMOUNT_TO_TRANSFER);
        // transfer tokens to the airdrop contract
        token.transfer(address(airdrop), S_AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
        return (airdrop, token);
    }
}
