pragma circom 2.1.6;

include "./ScalarMult.circom";
include "./SplitAmount.circom";
include "./ElGamal.circom";

template Transfer() {
    signal input sk;

    signal input amount; // 64-bit scalar
    signal input amountNonces[4];

    signal input oldBalance; // 128-bit scalar
    signal input oldBalanceNonces[8];

    signal input newBalanceNonces[8];

    signal output pk[2];
    signal output amountEnc[4][2][2];       // 4 chunks: [C[x,y], D[x,y]]
    signal output oldBalanceEnc[8][2][2];   // 8 chunks: [C[x,y], D[x,y]]
    signal output newBalanceEnc[8][2][2];   // 8 chunks: [C[x,y], D[x,y]]

    // check pk = sk * G
    component skCheck = ScalarMult();
    skCheck.scalar <== sk;

    pk[0] <== skCheck.publicKey[0];
    pk[1] <== skCheck.publicKey[1];

    // calculate new balance
    signal newBalance;
    newBalance <== oldBalance - amount;

    // split amount and balances into 16-bit chunks
    signal amountChunks[4];
    signal oldBalanceChunks[8];
    signal newBalanceChunks[8];

    component splitAmount = SplitAmount(4);
    splitAmount.amount <== amount;

    amountChunks <== splitAmount.chunks;

    component splitOldBalance = SplitAmount(8);
    splitOldBalance.amount <== oldBalance;

    oldBalanceChunks <== splitOldBalance.chunks;

    component splitNewBalance = SplitAmount(8);
    splitNewBalance.amount <== newBalance;

    newBalanceChunks <== splitNewBalance.chunks;

    // calculate chunk amount and balance points
    component mulAmount[4];
    component mulOld[8];
    component mulNew[8];

    signal amountPoints[4][2];
    signal oldBalancePoints[8][2];
    signal newBalancePoints[8][2];

    for (var i = 0; i < 4; i++) {
        mulAmount[i] = ScalarMult();
        mulAmount[i].scalar <== amountChunks[i];

        amountPoints[i] <== mulAmount[i].publicKey;
    }

    for (var i = 0; i < 8; i++) {
        mulOld[i] = ScalarMult();
        mulOld[i].scalar <== oldBalanceChunks[i];

        oldBalancePoints[i] <== mulOld[i].publicKey;

        mulNew[i] = ScalarMult();
        mulNew[i].scalar <== newBalanceChunks[i];

        newBalancePoints[i] <== mulNew[i].publicKey;
    }

    // check correct amount and balances encryption
    component elgamalAmount[4];
    component elgamalOld[8];
    component elgamalNew[8];

    for (var i = 0; i < 4; i++) {
        elgamalAmount[i] = ElGamal();
        elgamalAmount[i].pk <== pk;
        elgamalAmount[i].M <== amountPoints[i];
        elgamalAmount[i].nonce <== amountNonces[i];

        amountEnc[i][0] <== elgamalAmount[i].C;
        amountEnc[i][1] <== elgamalAmount[i].D;
    }

    for (var i = 0; i < 8; i++) {
        elgamalOld[i] = ElGamal();
        elgamalOld[i].pk <== pk;
        elgamalOld[i].M <== oldBalancePoints[i];
        elgamalOld[i].nonce <== oldBalanceNonces[i];

        oldBalanceEnc[i][0] <== elgamalOld[i].C;
        oldBalanceEnc[i][1] <== elgamalOld[i].D;

        elgamalNew[i] = ElGamal();
        elgamalNew[i].pk <== pk;
        elgamalNew[i].M <== newBalancePoints[i];
        elgamalNew[i].nonce <== newBalanceNonces[i];

        newBalanceEnc[i][0] <== elgamalNew[i].C;
        newBalanceEnc[i][1] <== elgamalNew[i].D;
    }
}

component main = Transfer();
