// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

/**
 * @title Interact
 * @author gnvvs-2003
 * @notice This script is used to interact with the MerkleAirdrop contract which includes claim
 */

contract Interact is Script {
    address MERKLE_AIRDROP_CONTRACT = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;
    address CLAIMING_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 CLAIMING_AMOUNT = 25 * 1e18;
    bytes private SIGNATURE =
        hex"de3ba536fb31b927ef10ae7901ed4cc4267b9924e95d377f832f59857a712e737f46e779c6d7b37b504d6e7997d721af62d29bd714c5248f3ccb5ee24c3bd87c1b";
    bytes32[] PROOF;
    // // 0x  bc4b0a35309255b611eb1544724cbf2eb0914bc323599e7e0602dc2dbf7d33ad  5c28be5aa4c31fd8f56ec317bb848d1a5060fdafdd90844d5d7c3ac958a618431b
    // uint8 v = 27; // if v>=27 => v=v-8
    // bytes32 r = 0xbc4b0a35309255b611eb1544724cbf2eb0914bc323599e7e0602dc2dbf7d33ad;
    // bytes32 s = 0x5c28be5aa4c31fd8f56ec317bb848d1a5060fdafdd90844d5d7c3ac958a618431b;

    function run() external {
        PROOF = new bytes32[](2);
        PROOF[0] = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
        PROOF[1] = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirdrop(MERKLE_AIRDROP_CONTRACT).claim(CLAIMING_ADDRESS, CLAIMING_AMOUNT, PROOF, v, r, s);
        vm.stopBroadcast();
    }

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
