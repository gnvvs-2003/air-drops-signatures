// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MerkleAirdrop
 * @author gnvvs-2003
 * @notice This contract handles the airdrop logic of BagelToken
 * @notice This contract manages the list of addresses and corresponding token amount eligible for airdrop
 * @notice This contract provides a mechanism for eligible users to claim their allocated tokens
 * @notice This uses MerkleTrees and Merkle Proofs
 * @notice This cryptographic technique allows for efficient verification of data inclusion without storing the entire dataset on-chain
 * @notice Instead of embedding the complete lists of eligible addr we perform
 * 1. Off-chain construction : A off chain Merkle Tree is constructed off chain
 * 2. On-chain root : Only the Merkle root is stored in the smart contract
 * @notice Merkle root : 32-bit hash of the entire data set
 * @notice This contract instead store the Merkle root of the airdrop distribution and the addr of the BagelToken
 * @notice The claim function will then accept the claimant's details along with a Merkle proof to verify eligibility before transferring tokens.
 */

contract MerkleAirdrop {

}
