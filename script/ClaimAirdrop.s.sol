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
    address CLAIMING_ADDRESS = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D;
    uint256 CLAIMING_AMOUNT = 25 * 1e18;
    bytes32 PROOF_ONE = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] PROOF = [PROOF_ONE, PROOF_TWO];
    bytes private SIGNATURE =
        hex"bc4b0a35309255b611eb1544724cbf2eb0914bc323599e7e0602dc2dbf7d33ad5c28be5aa4c31fd8f56ec317bb848d1a5060fdafdd90844d5d7c3ac958a618431b";

    function run() external {
        address mostRecentlyDeployed = DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        MerkleAirdrop merkleAirdrop = MerkleAirdrop(mostRecentlyDeployed);
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        merkleAirdrop.claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, PROOF, v, r, s);
        vm.stopBroadcast();
    }

    // function claimAirdrop(address airdropContract) public {
    //     address CLAIMING_ADDRESS = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D; // one of the claimants in input.json
    //     uint256 CLAIMING_AMOUNT = 25 * 1e18; // 25 tokens with 18 decimals
    //     bytes32 PROOF_ONE = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    //     bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    //     bytes32[] memory PROOF = new bytes32[](2);
    //     PROOF[0] = PROOF_ONE;
    //     PROOF[1] = PROOF_TWO; // Merkle proof for the claimant
    //     vm.startBroadcast(); // preparing foundry to send transactions
    //     // Actual claim function call from the MerkleAirdrop contract
    //     // MerkleAirdrop(airdropContract).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, PROOF, v, r, s);
    //     vm.stopBroadcast();
    // }

    function splitSignature(bytes memory _signature) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (_signature.length != 65) {
            revert Interact__InvalidSignature();
        }
        assembly {
            r := mload(add(_signature, 0x20)) // 0x20 is 32 in hexadecimal
            s := mload(add(_signature, 0x40)) // 0x40 is 64 in hexadecimal
            v := byte(0, mload(add(_signature, 0x60))) // 0x60 is 96 in hexadecimal
        }
        if (v < 27) {
            v += 27;
        }
    }

    /// Errors
    error Interact__InvalidSignature();
}
