#!/bin/bash
set -e
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
mkdir -p build
OPENCIRCOM="${OPENCIRCOM:-$ROOT/node_modules/opencircom/circuits}"
if [ ! -d "$OPENCIRCOM" ]; then
  echo "Run npm install first (opencircom not found at $OPENCIRCOM)"
  exit 1
fi
echo "Compiling circuits (opencircom at $OPENCIRCOM)..."
circom circuits/hello_hash.circom --r1cs --wasm -o build -l node_modules/opencircom/circuits
echo "Done. R1CS and WASM in build/."
