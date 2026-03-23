// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
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
    using SafeERC20 for IERC20; // Adding the SafeERC20 library functions to IERC20 token instance

    /// Immutables
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_AIRDROP_TOKEN;

    // Mappings
    mapping(address claimant => bool) private sHasClaimed;

    /// Constructor
    /// @notice sets the merkle root and the airdrop token address
    /// @param merkleRoot : The root hash of the Merkle tree
    /// @param airdropToken : The address of the token to be airdropped
    /// @notice When the `MerkleAirdrop` is deployed it will be permanently configured with specific Merkle root of the allow list and the ERC20 token it is meant to distribute
    constructor(bytes32 merkleRoot, IERC20 airdropToken) {
        I_MERKLE_ROOT = merkleRoot;
        I_AIRDROP_TOKEN = airdropToken;
    }

    /// Events
    event Claim(address indexed account, uint256 indexed amount);

    /// External functions
    /**
     * @param account : The address of the account claiming the tokens
     * @param amount : The amount of tokens the account is eligible to claim
     * @param merkleProof : The Merkle proof for the account
     * @notice This function allows an eligible user to claim their tokens
     * @notice The function first verifies the Merkle proof to ensure the account is eligible
     * @notice If the proof is valid, the function transfers the specified amount of tokens to the account
     * @notice The function uses the `verify` function from the `MerkleProof` library to verify the proof
     * @notice CHECK : CHECK IF THE ACCOUNT ALREADY CLAIMED IF NOT CHECK IF THE MERKLE PROOF IS VALID
     * @notice CHECK : CHECK IF THE ACCOUNT IS ELIGIBLE FOR THE AIRDROP
     * @notice EFFECT : UPDATE THE STATUS OF CLAIMING AND
     * @notice INTERACTIONS : EMIT EVENT AND TRANSFER TOKENS
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof) external {
        // Step-1 : Preventing double claims
        if (sHasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // Step-2 : reconstructs the leaf node hash corresponding to claimant's address USING DOUBLE HASHING
        bytes32 leafHash = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        // Step-3 : Verifying the Merkle proof
        if (!MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leafHash)) {
            revert MerkleAirdrop__InvalidMerkleProof();
        }

        sHasClaimed[account] = true;
        // Step-4 : Logging claims
        emit Claim(account, amount);
        I_AIRDROP_TOKEN.safeTransfer(account, amount);
    }

    /// Errors
    error MerkleAirdrop__InvalidMerkleProof();
    error MerkleAirdrop__AlreadyClaimed();
}
