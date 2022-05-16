pragma circom 2.0.0;

include "../node_modules/circomlib/circuits/poseidon.circom";
include "../node_modules/circomlib/circuits/mux1.circom";

// template to compute poseidon hash of two inputs
template ComputePoseidonHash() {
    // input signals which hash are to be computed
    signal input left;
    signal input right;

    signal output resultHash;

    // number of inputs to hash i.e. in our case 2
    var numberOfInputs = 2;

    // component instantiation to Poseidon template
    component computeHash = Poseidon(numberOfInputs);

    // constraints definition of component computeHash
    computeHash.inputs[0] <== left;
    computeHash.inputs[1] <== right;

    resultHash <== computeHash.out;
}

template CheckRoot(n) { // compute the root of a MerkleTree of n Levels 
    signal input leaves[2**n];
    signal output root;

    //[assignment] insert your code here to calculate the Merkle root from 2^n leaves
    var numLeafHashing = 2**n / 2; // indicates number of hashing to be done in leaf level
    var numIntermediateHashing = numLeafHashing - 1; // indicatest the number of hashing to be done except at leaf level
    var computeHashNumber = 2**n - 1; // indicates total number of hashing to be done to compute root hash

    // array of component initialization for ComputePoseidonHash template
    component hashCompute[computeHashNumber];

    // compute poseidon hashes in leaf level of Merkel Tree
    for (var i=0; i<numLeafHashing; i++) {
        hashCompute[i] = ComputePoseidonHash(); // component instantiation to ComputePoseidonHash template

        hashCompute[i].left <== leaves[i*2];
        hashCompute[i].right <== leaves[i*2+1];
    }

    // compute Poseidon hashes except leaf level of Merkel tree
    var j = 0;
    for (var i=numLeafHashing; i<computeHashNumber; i++) {
        hashCompute[i] = ComputePoseidonHash();

        hashCompute[i].left <== hashCompute[j*2].resultHash;
        hashCompute[i].right <== hashCompute[j*2+1].resultHash;

        j++;
    }

    // constraints for root hash of Merkel tree
    root <== hashCompute[computeHashNumber-1].resultHash;
}

template MerkleTreeInclusionProof(n) {
    signal input leaf;
    signal input path_elements[n];
    signal input path_index[n]; // path index are 0's and 1's indicating whether the current element is on the left or right
    signal output root; // note that this is an OUTPUT signal

    //[assignment] insert your code here to compute the root from a leaf and elements along the path
    // array of component initialization for ComputePoseidonHash template
    component hashCompute[n];

    // array of component initialization for MultiMux1 template
    component multiplexer[n];

    signal hashLevel[n+1]; // intermediate signal array to store hash computed in each level
    hashLevel[0] <== leaf;

    // compute hash at each level to get root hash
    for (var i=0; i<n; i++) {
        hashCompute[i] = ComputePoseidonHash(); // component instantiation for ComputePoseidonHash template
        multiplexer[i] = MultiMux1(2); // component instantiation for MultiMux1 template where 2 is argument to the template

        // constraints and input for MultiMux1 template
        multiplexer[i].c[0][0] <== hashLevel[i];
        multiplexer[i].c[0][1] <== path_elements[i];
        multiplexer[i].c[1][0] <== path_elements[i];
        multiplexer[i].c[1][1] <== hashLevel[i];
        multiplexer[i].s <== path_index[i];

        // constraints define and input assignment for ComputePoseidonHash template
        hashCompute[i].left <== multiplexer[i].out[1];
        hashCompute[i].right <== multiplexer[i].out[0];

        hashLevel[i+1] <== hashCompute[i].resultHash;
    }

    // constraints for root hash of Merkel tree
    root <== hashLevel[n];
}