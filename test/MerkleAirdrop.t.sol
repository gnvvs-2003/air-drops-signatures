// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {DeployMerkleAirdrop} from "../script/DeployMerkleAirdrop.s.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol"; // If using foundry-devops
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title MerkleAirdropTest
 * @author gnvvs-2003
 * @notice This contract is used for testing the MerkleAirdrop contract
 * @notice Merkle airdrop relies on the Merkle tree generated off chain
 * @notice The ROOT of the tree is stored in the contract and users provide the PROOF to claim
 */

contract MerkleAirdropTest is ZkSyncChainChecker, Test {
    MerkleAirdrop public airdrop;
    BagelToken public token;

    bytes32 public ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    uint256 public AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public AMOUNT_TO_SEND;

    address user;
    uint256 userPrivateKey;
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] PROOF = [proofOne, proofTwo];

    /// setUp function
    function setUp() public {
        // Check if we are on a ZkSync chain
        if (!isZkSyncChain()) {
            // use deployScript
            DeployMerkleAirdrop deployer = new DeployMerkleAirdrop();
            (airdrop, token) = deployer.deployMerkleAirdrop();
        } else {
            // Manual deployment
            token = new BagelToken();
            airdrop = new MerkleAirdrop(ROOT, IERC20(address(token)));
            /// MINT TOKENS TO THE OWNER
            address owner = address(this);
            /// ASSUMING ONLY 4 ADDRESS WILL BE GIVEN THE AIRDROP
            AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
            token.mint(owner, AMOUNT_TO_SEND);
            /// TRANSFER TOKENS TO THE AIRDROP CONTRACT
            token.transfer(address(airdrop), AMOUNT_TO_SEND);
            /// FLOW OF TOKENS : ERC20 TOKENS GENERATED -> SEND TO OWNER -> SEND TO AIRDROP CONTRACT -> SEND TO CLAIMANTS
        }
        // (user, userPrivateKey) = makeAddrAndKey("testUser");
        user = 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D;
    }

    function test_UsersCanClaim() public {
        uint256 startingBalance = token.balanceOf(user);
        vm.prank(user);
        airdrop.claim(user, AMOUNT_TO_CLAIM, PROOF);
        uint256 endingBalance = token.balanceOf(user);
        console.log(startingBalance);
        console.log(endingBalance);
        assertEq(endingBalance, startingBalance + AMOUNT_TO_CLAIM);
    }
}
