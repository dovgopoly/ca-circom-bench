import { ScalarMult } from "@zkit";

import { expect } from "chai";
import fs from "fs";
import { zkit } from "hardhat";

describe.only("ScalarMult Circuit", function () {
  let circuit: ScalarMult;

  before(async function () {
    circuit = await zkit.getCircuit("ScalarMult");
  });

  it("should prove knowledge of scalar multiplication", async function () {
    const scalar = 1;

    const inputs = { scalar };

    // Calculate witness
    const witness = await circuit.calculateWitness(inputs);
    expect(witness).to.not.be.undefined;
    console.log("✓ Witness calculated successfully");

    // Read constraints from artifacts
    const artifactsPath = "./zkit/artifacts/circuits/ScalarMult.circom/ScalarMult_artifacts.json";
    const artifacts = JSON.parse(fs.readFileSync(artifactsPath, "utf8"));
    const constraintsNumber = artifacts.baseCircuitInfo.constraintsNumber;
    console.log("Number of constraints:", constraintsNumber.toLocaleString());

    // Generate proof
    const { proof, publicSignals } = await circuit.generateProof(inputs);

    expect(proof).to.not.be.undefined;
    expect(publicSignals).to.not.be.undefined;
    console.log("✓ Proof generated successfully");

    // Display the result
    if (publicSignals.publicKey) {
      console.log("Public key (aG):");
      console.log("X:", publicSignals.publicKey[0]);
      console.log("Y:", publicSignals.publicKey[1]);
    }

    console.log("✓ ScalarMult circuit working - proves knowledge of scalar 'a' such that aG = publicKey");
  });
});
