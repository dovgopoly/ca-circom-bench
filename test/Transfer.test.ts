import { Transfer } from "@zkit";

import { expect } from "chai";
import fs from "fs";
import { zkit } from "hardhat";

describe.only("Transfer Circuit", function () {
  let circuit: Transfer;

  before(async function () {
    circuit = await zkit.getCircuit("Transfer");
  });

  it("should prove confidential transfer", async function () {
    const sk = 182814471818777738062409159736290962539n;
    const amount = 10010893507048974456n;
    const amountNonces = [
      1111814471818777738062409159736290962539n,
      2222814471818777738062409159736290962539n,
      3333814471818777738062409159736290962539n,
      4444814471818777738062409159736290962539n,
    ];
    const oldBalance = 200202413469333032889230n;
    const oldBalanceNonces = [
      5552814471818777738062409159736290962539n,
      6662814471818777738062409159736290962539n,
      7772814471818777738062409159736290962539n,
      8882814471818777738062409159736290962539n,
      9992814471818777738062409159736290962539n,
      1002814471818777738062409159736290962539n,
      1112814471818777738062409159736290962539n,
      2222814471818777738062409159736290962539n,
    ];
    const newBalanceNonces = [
      2222814471818777738062409159736290962539n,
      3332814471818777738062409159736290962539n,
      4442814471818777738062409159736290962539n,
      5552814471818777738062409159736290962539n,
      6662814471818777738062409159736290962539n,
      7772814471818777738062409159736290962539n,
      8882814471818777738062409159736290962539n,
      9992814471818777738062409159736290962539n,
    ];

    const inputs = { sk, amount, amountNonces, oldBalance, oldBalanceNonces, newBalanceNonces };

    // Calculate witness
    const witness = await circuit.calculateWitness(inputs);
    expect(witness).to.not.be.undefined;
    console.log("✓ Witness calculated successfully");

    // Read constraints from artifacts
    const artifactsPath = "./zkit/artifacts/circuits/Transfer.circom/Transfer_artifacts.json";
    const artifacts = JSON.parse(fs.readFileSync(artifactsPath, "utf8"));
    const constraintsNumber = artifacts.baseCircuitInfo.constraintsNumber;
    console.log("Number of constraints:", constraintsNumber.toLocaleString());

    // Generate proof
    const { proof, publicSignals } = await circuit.generateProof(inputs);

    expect(proof).to.not.be.undefined;
    expect(publicSignals).to.not.be.undefined;
    console.log("✓ Proof generated successfully");

    // Display the result
    if (publicSignals.pk) {
      console.log("Public key (skG):");
      console.log("X:", publicSignals.pk[0]);
      console.log("Y:", publicSignals.pk[1]);
    }

    console.log("✓ Transfer circuit working");
  });
});
