#!/bin/bash
# Prepares ptau, zkey and Solidity verifier for real ZK tests. Run before npm test.
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
BUILD="$ROOT/build"
PTAU="$BUILD/pot12_final.ptau"
CIRCUIT="hello_hash"
VERIFIER_DIR="$ROOT/contracts/verifiers"

mkdir -p "$BUILD" "$VERIFIER_DIR"

if [ ! -f "$PTAU" ]; then
  echo "Generating Powers of Tau (12)..."
  npx snarkjs powersoftau new bn128 12 "$BUILD/pot12_0000.ptau"
  npx snarkjs powersoftau contribute "$BUILD/pot12_0000.ptau" "$BUILD/pot12_0001.ptau" --name="First" -e="$(head -c 64 /dev/urandom | xxd -ps -c 64)"
  npx snarkjs powersoftau beacon "$BUILD/pot12_0001.ptau" "$BUILD/pot12_beacon.ptau" "$(head -c 32 /dev/urandom | xxd -ps -c 32)" 10
  npx snarkjs powersoftau prepare phase2 "$BUILD/pot12_beacon.ptau" "$PTAU" -v
  echo "ptau ready."
fi

if [ ! -f "$BUILD/${CIRCUIT}.r1cs" ]; then
  echo "Compiling ${CIRCUIT}..."
  circom circuits/${CIRCUIT}.circom --r1cs --wasm -o "$BUILD" -l node_modules/opencircom/circuits
  echo "Circuit compiled."
fi

if [ ! -f "$BUILD/${CIRCUIT}_final.zkey" ]; then
  echo "Generating zkey for ${CIRCUIT}..."
  npx snarkjs groth16 setup "$BUILD/${CIRCUIT}.r1cs" "$PTAU" "$BUILD/${CIRCUIT}_0000.zkey"
  npx snarkjs zkey contribute "$BUILD/${CIRCUIT}_0000.zkey" "$BUILD/${CIRCUIT}_final.zkey" --name="Test" -e="$(openssl rand -hex 32)"
  echo "zkey ready."
fi

echo "Exporting Solidity verifier..."
npx snarkjs zkey export solidityverifier "$BUILD/${CIRCUIT}_final.zkey" "$VERIFIER_DIR/HelloHashVerifier.sol"
# Match Solidity version and contract name
sed -i.bak 's/pragma solidity [^;]*/pragma solidity ^0.8.20/' "$VERIFIER_DIR/HelloHashVerifier.sol"
sed -i.bak 's/contract Groth16Verifier/contract HelloHashVerifier/' "$VERIFIER_DIR/HelloHashVerifier.sol"
rm -f "$VERIFIER_DIR/HelloHashVerifier.sol.bak"
echo "ZK setup done. Run npm test to use real verifier."
