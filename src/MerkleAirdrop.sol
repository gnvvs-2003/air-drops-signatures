// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

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
 * @notice For signatures we will be using openzeppelin EIP712 and ECDSA libraries
 * @custom:library EIP712 produces human readable signatures
 * @custom:library ECDSA is used for verifying the signatures
 */

contract MerkleAirdrop is EIP712 {
    using SafeERC20 for IERC20; // Adding the SafeERC20 library functions to IERC20 token instance

    /// Immutables
    bytes32 private immutable I_MERKLE_ROOT;
    IERC20 private immutable I_AIRDROP_TOKEN;

    // Constants
    // Usually better to compute typehash before keccak256("AirdropClaim(address account,uint256 amount)")
    bytes32 private constant MESSAGE_TYPEHASH = 0x810786b83997ad50983567660c1d9050f79500bb7c2470579e75690d45184163;

    // Structs
    struct AirdropClaim {
        // for EIP712 struct
        address account;
        uint256 amount;
    }

    // Mappings
    mapping(address claimant => bool) private sHasClaimed;

    /// Constructor
    /// @notice sets the merkle root and the airdrop token address
    /// @param merkleRoot : The root hash of the Merkle tree
    /// @param airdropToken : The address of the token to be airdropped
    /// @notice When the `MerkleAirdrop` is deployed it will be permanently configured with specific Merkle root of the allow list and the ERC20 token it is meant to distribute
    constructor(bytes32 merkleRoot, IERC20 airdropToken) EIP712("AirdropClaim", "1") {
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
     * @param v : Signature component : recovery ID for public key
     * @param r : Signature component : O/p of signing algo
     * @param s : Signature component : O/p of signing algo
     * @notice This function allows an eligible user to claim their tokens
     * @notice The function first verifies the signature to ensure the account is authorized
     * @notice If the signature is valid, then verify the merkle proof and then the function transfers the specified amount of tokens to the account
     * @notice The function uses the `verify` function from the `MerkleProof` library to verify the proof
     * @notice CHECK : CHECK IF THE ACCOUNT ALREADY CLAIMED IF NOT CHECK IF THE SIGNATURE IS VALID
     * @notice CHECK : CHECK IF THE ACCOUNT IS ELIGIBLE FOR THE AIRDROP
     * @notice EFFECT : UPDATE THE STATUS OF CLAIMING AND
     * @notice INTERACTIONS : EMIT EVENT AND TRANSFER TOKENS
     */
    function claim(address account, uint256 amount, bytes32[] calldata merkleProof, uint8 v, bytes32 r, bytes32 s)
        external
    {
        // Step-1 : Preventing double claims
        if (sHasClaimed[account]) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        // Step-2 : Construct the digest
        bytes32 digest = getMessageHash(account, amount);
        // Step-3 : Verify the signature
        if (!_isValidSignature(account, digest, v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        // Step-4 : reconstructs the leaf node hash corresponding to claimant's address USING DOUBLE HASHING
        bytes32 leafHash = keccak256(bytes.concat(keccak256(abi.encode(account, amount))));
        // Step-5 : Verifying the Merkle proof
        if (!MerkleProof.verify(merkleProof, I_MERKLE_ROOT, leafHash)) {
            revert MerkleAirdrop__InvalidMerkleProof();
        }

        sHasClaimed[account] = true;
        // Step-4 : Logging claims
        emit Claim(account, amount);
        I_AIRDROP_TOKEN.safeTransfer(account, amount);
    }

    /// Public functions

    /**
     * @param account : The address of the account claiming the tokens
     * @param amount : The amount of tokens the account is eligible to claim
     * @notice This function is used to get the message that needs to be signed by the account
     */
    function getMessage(address account, uint256 amount) public view returns (bytes32) {
        bytes32 structHash = keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount})));
        // Combine the domain seperator with the struct hash
        return _hashTypedDataV4(structHash);
    }

    /**
     * @param account : The address of the account claiming the tokens
     * @param amount : The amount of tokens the account is eligible to claim
     * @notice The contract needs a function, getMessageHash, to construct the EIP-712 typed data hash.
     * @notice This function ensures that what the user signs off-chain matches what the contract expects on-chain.
     */
    function getMessageHash(address account, uint256 amount) public view returns (bytes32) {
        return
            _hashTypedDataV4(keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({account: account, amount: amount}))));
    }

    /// Internal functions
    /**
     * @param expectedSigner : The address of the account that is expected to sign the message
     * @param digest : The digest of the message
     * @param v : Signature component : recovery ID for public key
     * @param r : Signature component : O/p of signing algo
     * @param s : Signature component : O/p of signing algo
     * @notice This function is used to verify the signature
     * @notice It uses the `ECDSA` library to verify the signature
     * @notice It uses the `_hashTypedDataV4` function from the `EIP712` library to verify the signature
     */
    function _isValidSignature(address expectedSigner, bytes32 digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,) = ECDSA.tryRecover(digest, v, r, s);
        return actualSigner != address(0) && actualSigner == expectedSigner;
    }

    /// Getter functions
    function getMerkleRoot() external view returns (bytes32) {
        return I_MERKLE_ROOT;
    }

    function getAirdropToken() external view returns (IERC20) {
        return I_AIRDROP_TOKEN;
    }

    function getHasClaimed(address account) external view returns (bool) {
        return sHasClaimed[account];
    }

    /// Errors
    error MerkleAirdrop__InvalidMerkleProof();
    error MerkleAirdrop__AlreadyClaimed();
    error MerkleAirdrop__InvalidSignature();
}
