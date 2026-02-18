// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./verifiers/HelloHashVerifier.sol";

/// @title PoseidonProofGateway
/// @notice Example contract that calls the ZK verifier. Submitting a valid proof stores the verified public signal (Poseidon hash).
contract PoseidonProofGateway {
    HelloHashVerifier public immutable verifier;

    /// Last verified public signal (hash output) from a valid proof.
    uint256 public lastVerifiedHash;

    event ProofVerified(uint256 indexed hashOutput);

    constructor(HelloHashVerifier _verifier) {
        verifier = _verifier;
    }

    /// @notice Submit a Groth16 proof; on success, updates lastVerifiedHash and emits ProofVerified.
    /// @return True if the proof was valid.
    function submitProof(
        uint256[2] calldata pA,
        uint256[2][2] calldata pB,
        uint256[2] calldata pC,
        uint256[1] calldata pubSignals
    ) external returns (bool) {
        bool ok = verifier.verifyProof(pA, pB, pC, pubSignals);
        if (ok) {
            lastVerifiedHash = pubSignals[0];
            emit ProofVerified(pubSignals[0]);
        }
        return ok;
    }
}
