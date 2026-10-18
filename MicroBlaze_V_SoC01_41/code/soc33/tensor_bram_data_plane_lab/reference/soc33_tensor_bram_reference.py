#!/usr/bin/env python3
"""SoC33 tensor-BRAM data-plane reference."""

INPUT = {
    0x000: 16,
    0x004: 32,
    0x008: 48,
    0x00C: 64,
    0x010: 32,
    0x014: 64,
    0x018: 96,
    0x01C: 128,
}

OUTPUT_CH0 = 0x100
OUTPUT_CH1 = 0x104


def round_away_from_zero_div_pow2(
    value: int,
    shift: int,
) -> int:
    if shift == 0:
        return value

    mag = abs(value)
    rounded_mag = (
        mag + (1 << (shift - 1))
    ) >> shift

    return -rounded_mag if value < 0 else rounded_mag


def requant(
    acc: int,
    bias: int,
    mult: int,
    shift: int,
    zp: int,
) -> int:
    product = (acc + bias) * mult
    rounded = round_away_from_zero_div_pow2(
        product,
        shift,
    )
    shifted = rounded + zp

    return max(-128, min(127, shifted))


def pack_s8(values: list[int]) -> int:
    packed = 0

    for index, value in enumerate(values):
        packed |= (
            value & 0xFF
        ) << (index * 8)

    return packed


def main() -> None:
    assert len(INPUT) == 8
    assert all((addr % 4) == 0 for addr in INPUT)

    ch0_acc = [INPUT[x] for x in [0x000, 0x004, 0x008, 0x00C]]
    ch1_acc = [INPUT[x] for x in [0x010, 0x014, 0x018, 0x01C]]

    ch0_q = [
        requant(x, 0, 1, 1, 0)
        for x in ch0_acc
    ]

    ch1_q = [
        requant(x, 4, 3, 1, -3)
        for x in ch1_acc
    ]

    assert ch0_q == [8, 16, 24, 32]
    assert ch1_q == [51, 99, 127, 127]

    out0 = pack_s8(ch0_q)
    out1 = pack_s8(ch1_q)

    assert out0 == 0x20181008
    assert out1 == 0x7F7F6333

    print("Tensor input addresses:")
    for addr, value in INPUT.items():
        print(f"  0x{addr:03X} -> {value}")

    print()
    print(f"OUTPUT_CH0 address = 0x{OUTPUT_CH0:03X}")
    print(f"OUTPUT_CH1 address = 0x{OUTPUT_CH1:03X}")
    print(f"OUT_CH0 = 0x{out0:08X}")
    print(f"OUT_CH1 = 0x{out1:08X}")
    print("NPU BRAM reads = 8 words")
    print("NPU BRAM writes = 2 words")
    print("CPU/NPU ownership rule: no same-buffer access while NPU BUSY")
    print("SOC33 PYTHON TENSOR-BRAM REFERENCE: PASS")


if __name__ == "__main__":
    main()
