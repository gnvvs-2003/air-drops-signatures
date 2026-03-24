TODO : BUilding an advanced Merkle Airdrop with foundry and Digital signatures

GOAL : Build an efficient system for token distribution that allows for eligibility verification via merkle proofs and authorized and potentially gasless claims using cryptographic signatures

# Airdrop
Process where a token development team distribution team distributes their tokens to the community for free, usually to reward early adopters, increase token liquidity, or bootstrap network effects.

For this project we will be using ERC20 tokens for airdropping

# Project overview
`src/BagelToken.sol` : ERC20 token which will be distributed through airdrop

`src/MerkleAirdrop.sol` : Contract to handle the airdrop

This contract handles 
1. Merkle proof verification
2. `claim` function
3. Gasless claims
4. Signature verification : checks the V,R,S components of the ECDSA signature preventing the unauthorized claims

`script/GenerateInput.s.sol` : Used for preparing the data (list of eligible addresses and amounts) and generating the merkle tree

`script/MakeMerkle.s.sol` : Used for constructing merkle tree from the input data.Generates individual merkle proofs for each address and computing the merkle root hash
These root hash are stored in `src/MerkleAirdrop.sol`

`script/DeployMerkleAirdrop.s.sol` : A deployment script for the MerkleAirdrop.sol contract.

`script/Interact.s.sol` : Used for interacting with the deployed airdrop contract, primarily for making claims.

`script/SplitSignature.s.sol` : A helper script or contract, possibly for dissecting a packed signature into its V, R, and S components for use in the smart contract.

# Learning Obj
1. Merkle Trees and Merkle Proofs
2. Digital signatures
3. ECDSA
4. Transaction types

# Project flow
1. Deploy the `BagelToken.sol` contract
2. Deploy the `MerkleAirdrop.sol` contract
3. Sign Message
4. Fund contracts
5. Claim tokens
    Verification process for claiming
    1. Submit their claim details(incl. address and amount they are eligible for) to the smart contract 
    2. Submit their Merkle Proof : Merkle proof contains a small set of hashes from the merkle tree
    3. Smart contract then uses the users submitted data and the provided merkle proof to recalculate the merkle root hash
    4. If this recalculated root matches the Merkle root stored in the contract, it cryptographically proves that the user's data (address and amount) was part of the original dataset used to generate the tree. This verification occurs without iterating through any lists on-chain.
6. Verify balance

# Used libraries 
1. OpenZeppelin Contracts for standard functionalities like ERC20 tokens and Access control

```bash
forge install openzeppelin/openzeppelin-contracts
```

2. Adding to remappings

```foundry.toml
remappings = [
    "@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/"
]
```

# Structure of Merkle Tree
Merkle tree is a hierarchical data structure built from hashed data.

* Merkle Trees
![alt text](<Merkle Trees.png>)

The primary issue with the Naive approach is that it requires storing all the data on-chain, which can be expensive and inefficient. 

Merkle Trees can solve this problem by storing only the root hash of the tree on chain

When a user claims, they provide their address (the leaf data) and the corresponding Merkle proof. The contract then performs a fixed number of hashing operations to verify the proof. 

The number of operations is proportional to the depth of the tree (log N, where N is the number of leaves), which is significantly more scalable and gas-efficient than iterating through N elements.

# Key functionalities in `MerkleProof.sol` 
1. `verify`

```solidity
function verify(bytes32[] memory proof /** Merkle Proof*/,bytes32 root,bytes32 leaf) internal pure returns(bool){
    return processProof(proof,leaf) == root;
}
```
The merkle proof contains the array of sibling hashes

2. `processProof`

```solidity
function processProof(bytes32[] memory proof,bytes32 leaf) internal pure returns(bytes32 computedHash){
    bytes32 computedHash = leaf;
    for(uint i = 0;i<=proof.length;i++){
        computedHash = _hashPair(comptedHash,proof[i]);
    }
    return computedHash;
}
```

3. `_hashPair`

```solidity
function _hashPair(bytes32 a,bytes32 b) internal pure returns(bytes32){
    return a<b?keccak256(abi.encode(a,b)):keccak256(abi.encode(b,a));
}
```
> Openzeppelin's actual implementation i.e `_efficientHash` uses assembly for optimized `keccak256` hashing

For generating the Merkle Trees and proofs within our foundry project we will use `murky` library available at 
```
https://github.com/dmfxyz/murky
```
This library provides tools for constructing Merkle trees and generating proofs directly within Foundry scripts.

# DS for Merkle Tree Generation
We will use 2 `json` files to manage the Merkle tree data these files are stored in `script/target` folder

1. `input.json` : Contains the raw data genertad by `script/GenerateInput.s.sol`
2. `output.json` : Generated Merkle Tree information genertad by `script/MakeMerkle.s.sol`

Example of `input.json`

```json
{
  "types": [
    "address", // for account address
    "uint" // for amount
  ],
  "count": 4, // number of leaf nodes
  "values": { // leaf node data
    "0": { // leaf node -0
      "0": "0x6CA6d1e2D5347Bfab1d91e883F1915560e891290", // addr
      "1": "2500000000000000000" // amt
    },
    "1": { // leaf node -1
      "0": "0xAnotherAddress...", // addr
      "1": "1000000000000000000" // amt
    }
    // ... other values up to count-1
  }
}
```

Example of `output.json`

```json
{
  "inputs": [
    "0x6CA6d1e2D5347Bfab1d91e883F1915560e891290", // addr
    "2500000000000000000" // amt
  ],
  "proof": [ // hashes to make the Merkle root i.e sibling hashes
    "0xfd7c981d30bece61f7499702bf5903114a0e06b51ba2c53abdf7b62986c00aef", // sibling hash
    "0x46f4c7c1c21e8a0c03949be8a51d2d02d1ec75b55d97a9993c3dbaf3a5a1e2f4" // sibling hash
  ],
  "root": "0x474d994c59e37b12805fd7bcbbcd046cf1907b90de3b7fb083cf3636c0ebfb1a", // merkle root hash
  "leaf": "0xd1445c931158119d00449ffcac3c947d828c359c34a6646b995962b35b5c6adc" // leaf node hash
}
// This structure is repeated for each leaf in the airdrop.
```

Installing the `murky` library

```bash
forge install dmfxyz/murky
```

Output json file generation flow:
1. GenerateInput.s.sol Execution: This script creates script/target/input.json, which lists all airdrop recipients (addresses) and their corresponding token amounts.

2. MakeMerkle.s.sol Reads Input: This script ingests the input.json file.

3. Leaf Hash Calculation: For each address/amount pair from input.json:

4. The address and amount are ABI-encoded (after necessary type conversions to bytes32).

5. The ABI-encoded data is trimmed (e.g., using ltrim64) to remove encoding overhead.

6. This trimmed data is then double-hashed (keccak256(bytes.concat(keccak256(trimmed_data)))) to produce the final bytes32 leaf hash.

7. Merkle Tree Construction with murky: MakeMerkle.s.sol uses the murky library, providing it with all the generated leaf hashes. murky then:

8. Calculates the single Merkle root for the entire dataset.

9. Generates the unique Merkle proof for each individual leaf.

10. output.json Generation: All the generated data—original inputs, the proof for each leaf, the common Merkle root, and each leaf's hash—is written to script/target/output.json.

To integrate the deployed contracts with the tests install `foundry-devops`

```bash
forge install cyfrin/foundry-devops
```