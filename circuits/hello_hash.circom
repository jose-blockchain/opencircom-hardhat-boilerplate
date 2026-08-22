pragma circom 2.0.0;

// Minimal circuit using opencircom: hash two inputs and output the result.
// Poseidon is a ZK-friendly hash - much cheaper to prove in-circuit than keccak256/sha256.
include "hashing/poseidon.circom";

// Proves you know two private inputs a and b whose Poseidon hash equals the
// public value out, without revealing a or b.
template HelloHash() {
    signal input a;
    signal input b;
    signal input out;  // public: claimed hash
    component h = Poseidon(2);
    h.inputs[0] <== a;
    h.inputs[1] <== b;
    h.out === out;
}

component main {public [out]} = HelloHash();
