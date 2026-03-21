// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {BagelToken} from "./BagelToken.sol";

/**
 * @title NaiveMerkleAirdrop
 * @author gnvvs-2003
 * @notice Using Naive approach
 * @notice This contract handles the airdrop logic of BagelToken
 * @notice This contract manages the list of addresses and corresponding token amount eligible for airdrop
 * @notice This contract provides a mechanism for eligible users to claim their allocated tokens
 * @custom:warning This naive approach suffers from High gas costs and has DoS(Denial of Service) when the arrays are large to iterate
 * @notice To overcome the high gas costs and DoS we use Merkle Trees and Merkle Proofs as used in `MerkleAirdrop.sol`
 */

contract MerkleAirdrop {
    address[] public claimAddr;
    mapping(address => uint256) public addressOfUserToEligibleAmounts;
    mapping(address => bool) public addressHasClaimedTokens;
    BagelToken token = new BagelToken();

    function claim() external {
        bool isEligible = false;
        for (uint256 i = 0; i < claimAddr.length; i++) {
            if (claimAddr[i] == msg.sender) {
                isEligible = true;
                break;
            }
        }
        uint256 amountEligible = addressOfUserToEligibleAmounts[msg.sender];
        addressHasClaimedTokens[msg.sender] = true;
        // Transfer tokens
        token.mint(msg.sender, amountEligible);
    }
}
