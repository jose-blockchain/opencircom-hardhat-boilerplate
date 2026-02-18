const { expect } = require("chai");
const hre = require("hardhat");
const fs = require("fs");
const path = require("path");
const snarkjs = require("snarkjs");
const { buildPoseidon } = require("circomlibjs");

describe("HelloHash (Hardhat + opencircom)", function () {
  const buildDir = path.join(__dirname, "..", "build");
  const circuitName = "hello_hash";

  it("circuit compiles and WASM exists", function () {
    expect(fs.existsSync(path.join(buildDir, "hello_hash_js", "hello_hash.wasm"))).to.be.true;
  });

    it("real ZK: generate proof and verify with deployed HelloHashVerifier", async function () {
    const zkeyPath = path.join(buildDir, `${circuitName}_final.zkey`);
    const wasmPath = path.join(buildDir, `${circuitName}_js`, `${circuitName}.wasm`);
    if (!fs.existsSync(zkeyPath) || !fs.existsSync(wasmPath)) {
      this.skip();
      return;
    }

    const poseidon = await buildPoseidon();
    const a = 1;
    const b = 2;
    const out = poseidon.F.toObject(poseidon([a, b])).toString();

    const input = { a, b, out };
    const { proof, publicSignals } = await snarkjs.groth16.fullProve(input, wasmPath, zkeyPath);
    expect(publicSignals.length).to.equal(1);
    expect(publicSignals[0].toString()).to.equal(out);

    const HelloHashVerifier = await hre.ethers.getContractFactory("HelloHashVerifier");
    const verifier = await HelloHashVerifier.deploy();
    const PoseidonProofGateway = await hre.ethers.getContractFactory("PoseidonProofGateway");
    const gateway = await PoseidonProofGateway.deploy(await verifier.getAddress());

    const calldata = await snarkjs.groth16.exportSolidityCallData(proof, publicSignals);
    const argv = JSON.parse("[" + calldata + "]");
    const [pA, pB, pC, pubSignals] = argv;

    const okDirect = await verifier.verifyProof.staticCall(pA, pB, pC, pubSignals);
    expect(okDirect).to.be.true;

    const okGateway = await gateway.submitProof.staticCall(pA, pB, pC, pubSignals);
    expect(okGateway).to.be.true;

    await gateway.submitProof(pA, pB, pC, pubSignals);
    expect(await gateway.lastVerifiedHash()).to.equal(publicSignals[0].toString());
  });
});
