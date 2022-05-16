//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import { PoseidonT3 } from "./Poseidon.sol"; //an existing library to perform Poseidon hash on solidity
import "./verifier.sol"; //inherits with the MerkleTreeInclusionProof verifier contract

contract MerkleTree is Verifier {
    uint256[] public hashes; // the Merkle tree in flattened array form
    uint256 public index = 0; // the current index of the first unfilled leaf
    uint256 public root; // the current Merkle root

    // initialization of constant describing property of Merkel tree
    uint256 internal DEPTH_OF_TREE = 3;

    constructor() {
        // [assignment] initialize a Merkle tree of 8 with blank leaves
        // Array initialized to 0s automatically
        hashes = new uint256[] (2 ** (DEPTH_OF_TREE+1) - 1); // calculating array size of tree nodes based on depth_of_tree

        uint256 starting_position = 0;

        // compute hashes of non-leaf nodes
        for(uint256 i=DEPTH_OF_TREE; i>0; i--) {    // Looping through each level of merkel tree
            uint256 next_starting_position = starting_position + 2**i;
            // Looping through each pair nodes of a level to compute hash
            for (uint256 current=0; current<2**i; current += 2) {
                hashes[starting_position + (current/2)] = PoseidonT3.poseidon([hashes[starting_position+current], hashes[starting_position+current+1]]);
            }
            starting_position = next_starting_position;
        }
    }

    function insertLeaf(uint256 hashedLeaf) public returns (uint256) {
        // [assignment] insert a hashed leaf into the Merkle tree
        // checking condition whether the leaf can be inserted in a tree or not
        require(index < 2**DEPTH_OF_TREE, "No more leaf can be inserted in the tree");

        uint256 starting_position = 0; // starting index of each level
        uint256 current_position = index; // it is the index where the leaf is to be inserted
        uint256 computeHashResult;

        // Loop through the level of tree and compute hash value corresponding to the inserted leaf position of level
        for (uint256 i=DEPTH_OF_TREE; i>0; i--) {
            hashes[index++] = hashedLeaf;
            uint256 j = starting_position + current_position;
            if (j % 2 != 0) {
                computeHashResult = PoseidonT3.poseidon([hashes[j-1], hashes[j]]);
            } else {
                computeHashResult = PoseidonT3.poseidon([hashes[j], hashes[j+1]]);
            }

            // Update starting_position and current_position for next level of tree
            starting_position += 2**i;
            current_position /= 2;

            // Store the hashes value of parent level of tree
            hashes[starting_position+current_position] = computeHashResult;
        }
        return computeHashResult;
    }

    function verify(
            uint[2] memory a,
            uint[2][2] memory b,
            uint[2] memory c,
            uint[1] memory input
        ) public view returns (bool) {

        // [assignment] verify an inclusion proof and check that the proof root matches current root
        return verifyProof(a, b, c, input); // Called verifyProof function of Verifier.sol to verify the proof
    }
}
