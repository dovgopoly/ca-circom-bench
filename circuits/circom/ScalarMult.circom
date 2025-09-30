pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/babyjub.circom";

template ScalarMult() {
    // Private input: scalar 'a' (253 bits for BabyJubJub)
    signal input scalar;

    // Output: point aG on BabyJubJub curve
    signal output publicKey[2];

    // Perform scalar multiplication: scalar * BASE8 = publicKey
    component pbk = BabyPbk();
    pbk.in <== scalar;

    // Connect outputs
    publicKey[0] <== pbk.Ax;
    publicKey[1] <== pbk.Ay;
}

// component main = ScalarMult();
