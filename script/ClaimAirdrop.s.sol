// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

/**
 * @title ClaimAirdrop
 * @author gnvvs-2003
 * @notice This script is used to claim the airdrop for the most recently deployed MerkleAirdrop contract.
 * @dev The script retrieves the most recently deployed MerkleAirdrop contract address using DevOpsTools and then calls the claimAirdrop function on that contract.
 */

contract ClaimAirdrop is Script {
    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployed);
    }

    /// Public functions

    /**
     * @param airdropContract The address of the MerkleAirdrop contract to claim the airdrop from.
     * @notice This function claims the airdrop from the specified MerkleAirdrop contract. It starts broadcasting transactions to the network, calls the claim function on the MerkleAirdrop contract, and then stops broadcasting.
     * @custom:merkle-claim-function Claim function call from the MerkleAirdrop contract requires
     * 1. CLAIMING_ADDRESS
     * 2. AMOUNT
     * 3. PROOF
     * 4. v,r,s (signature parameters for ECDSA signature verification)
     */

    function claimAirdrop(address airdropContract) public {
        address CLAIMING_ADDRESS = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D; // one of the claimants in input.json
        uint256 CLAIMING_AMOUNT = 25 * 1e18; // 25 tokens with 18 decimals
        bytes32 PROOF_ONE = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
        bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
        bytes32[] memory PROOF = new bytes32[](2);
        PROOF[0] = PROOF_ONE;
        PROOF[1] = PROOF_TWO; // Merkle proof for the claimant
        vm.startBroadcast(); // preparing foundry to send transactions
        // Actual claim function call from the MerkleAirdrop contract
        // MerkleAirdrop(airdropContract).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, PROOF, v, r, s);
        vm.stopBroadcast();
    }
}
