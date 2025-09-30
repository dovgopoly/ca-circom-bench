use std::embedded_curve_ops::{EmbeddedCurvePoint, EmbeddedCurveScalar, fixed_base_scalar_mul, multi_scalar_mul, embedded_curve_add};

pub struct Ciphertext {
    C: EmbeddedCurvePoint,
    D: EmbeddedCurvePoint
}

fn variable_base_mul(point: EmbeddedCurvePoint, scalar: u128) -> EmbeddedCurvePoint {
    multi_scalar_mul([point], [EmbeddedCurveScalar { lo: scalar as Field, hi: 0 as Field }])
}

fn fixed_base_mul(scalar: u128) -> EmbeddedCurvePoint {
    fixed_base_scalar_mul(EmbeddedCurveScalar { lo: scalar as Field, hi: 0 as Field })
}

fn split_into_4_u16_chunks(val: u128) -> [u16; 4] {
    let mut out: [u16; 4] = [0u16; 4];
    let mut tmp: u128 = val;
    let mask: u128 = (1u128 << 16u128) - 1u128;

    for i in 0..4 {
        out[i] = (tmp & mask) as u16;
        tmp = tmp >> 16u128;
    }

    out
}

fn split_into_8_u16_chunks(val: u128) -> [u16; 8] {
    let mut out: [u16; 8] = [0u16; 8];
    let mut tmp: u128 = val;
    let mask: u128 = (1u128 << 16u128) - 1u128;

    for i in 0..8 {
        out[i] = (tmp & mask) as u16;
        tmp = tmp >> 16u128;
    }

    out
}

fn elgamal_encrypt_point(pk: EmbeddedCurvePoint, M: EmbeddedCurvePoint, nonce: u128) -> Ciphertext {
    if M.is_infinite {
        let rG = fixed_base_mul(nonce);
        Ciphertext { C: rG, D: variable_base_mul(pk, nonce) }
    } else {
        let rG = fixed_base_mul(nonce);
        Ciphertext { C: embedded_curve_add(M, rG), D: variable_base_mul(pk, nonce) }
    }
}

pub fn main(
    sk: u128,
    amount: u128,
    amount_nonces: [u128; 4],
    old_balance: u128,
    old_balance_nonces: [u128; 8],
    new_balance_nonces: [u128; 8]
) -> pub (
    EmbeddedCurvePoint,      // pk
    [Ciphertext; 4],         // amountEnc
    [Ciphertext; 8],         // oldBalanceEnc
    [Ciphertext; 8]          // newBalanceEnc
) {
    // derive pk = sk * G
    let pk: EmbeddedCurvePoint = fixed_base_mul(sk);

    // calculate new balance
    let new_balance: u128 = old_balance - amount;

    // split amount and balances into 16-bit chunks
    let amount_chunks: [u16; 4] = split_into_4_u16_chunks(amount);
    let old_chunks: [u16; 8] = split_into_8_u16_chunks(old_balance);
    let new_chunks: [u16; 8] = split_into_8_u16_chunks(new_balance);

    // compute chunk points (chunk * G)
    let mut amount_points: [EmbeddedCurvePoint; 4] = [EmbeddedCurvePoint { x: 0, y: 0, is_infinite: true }; 4];
    for i in 0..4 {
        amount_points[i] = fixed_base_mul(amount_chunks[i] as u128)
    }

    let mut old_points: [EmbeddedCurvePoint; 8] = [EmbeddedCurvePoint { x: 0, y: 0, is_infinite: true }; 8];
    for i in 0..8 {
        old_points[i] = fixed_base_mul(old_chunks[i] as u128);
    }

    let mut new_points: [EmbeddedCurvePoint; 8] = [EmbeddedCurvePoint { x: 0, y: 0, is_infinite: true }; 8];
    for i in 0..8 {
        new_points[i] = fixed_base_mul(new_chunks[i] as u128);
    }

    // encrypt each chunk with its nonce
    let mut amount_enc: [Ciphertext; 4] = [Ciphertext { C: EmbeddedCurvePoint { x: 0, y: 0, is_infinite: true }, D: EmbeddedCurvePoint { x: 0, y: 0, is_infinite: true } }; 4];
    for i in 0..4 {
        amount_enc[i] = elgamal_encrypt_point(pk, amount_points[i], amount_nonces[i]);
    }

    let mut old_enc: [Ciphertext; 8] = [Ciphertext { C: EmbeddedCurvePoint { x: 0, y: 0, is_infinite: true }, D: EmbeddedCurvePoint { x: 0, y: 0, is_infinite: true } }; 8];
    let mut new_enc: [Ciphertext; 8] = [Ciphertext { C: EmbeddedCurvePoint { x: 0, y: 0, is_infinite: true }, D: EmbeddedCurvePoint { x: 0, y: 0, is_infinite: true } }; 8];
    for i in 0..8 {
        old_enc[i] = elgamal_encrypt_point(pk, old_points[i], old_balance_nonces[i]);
        new_enc[i] = elgamal_encrypt_point(pk, new_points[i], new_balance_nonces[i]);
    }

    (pk, amount_enc, old_enc, new_enc)
}