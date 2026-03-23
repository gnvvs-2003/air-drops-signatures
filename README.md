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

