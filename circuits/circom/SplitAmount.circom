pragma circom 2.1.6;

include "../node_modules/circomlib/circuits/bitify.circom";

template SplitAmount(nChunks) {
    signal input amount;
    signal output chunks[nChunks];

    component amountBits = Num2Bits(16 * nChunks);
    amountBits.in <== amount;

    component range[nChunks];

    for (var i = 0; i < nChunks; i++) {
        var tmpChunk = 0;

        for (var j = 0; j < 16; j++) {
            tmpChunk += amountBits.out[i*16 + j] * (1 << j);
        }

        chunks[i] <== tmpChunk;

        range[i] = Num2Bits(16);
        range[i].in <== chunks[i];
    }

    var reconstructed = 0;

    for (var i = 0; i < nChunks; i++) {
        reconstructed += chunks[i] * (1 << (16*i));
    }

    amount === reconstructed;
}
