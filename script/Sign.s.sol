// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script, console} from "forge-std/Script.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";

contract Sign is Script {
    function run() external {
        address MERKLE_AIRDROP_CONTRACT = 0x5FC8d32690cc91D4c39d9d3abcBD16989F875707;
        address claimer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        uint256 amount = 25 * 1e18;

        MerkleAirdrop airdrop = MerkleAirdrop(MERKLE_AIRDROP_CONTRACT);
        bytes32 digest = airdrop.getMessageHash(claimer, amount);

        uint256 pvKey = 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(pvKey, digest);

        bytes memory sig = abi.encodePacked(r, s, v);
        console.log("RAW SIG:");
        console.logBytes(sig);
    }
}
