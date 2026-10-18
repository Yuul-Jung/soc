#!/usr/bin/env python3
"""SoC 25 4-lane signed fixed-point dot-product / PE reference."""

FRAC_BITS = 7
DOT_FRAC_BITS = 14
DSP48E1_COUNT_XC7A35T = 90
LANES = 4


def wrap_signed(value: int, bits: int) -> int:
    mask = (1 << bits) - 1
    value &= mask
    sign = 1 << (bits - 1)

    if value & sign:
        value -= 1 << bits

    return value


def dot4(a: list[int], b: list[int]) -> int:
    assert len(a) == LANES
    assert len(b) == LANES

    return sum(x * y for x, y in zip(a, b))


def acc_step(acc: int, a: list[int], b: list[int]) -> int:
    return wrap_signed(acc + dot4(a, b), 32)


def real_from_raw(raw: int) -> float:
    return raw / float(1 << DOT_FRAC_BITS)


def main() -> None:
    vectors = [
        (
            [64, 64, 64, 64],
            [64, 64, 64, 64],
            "four lanes of 0.5 * 0.5"
        ),
        (
            [64, -64, 32, -32],
            [64, 64, 64, 64],
            "mixed sign cancellation"
        ),
        (
            [-128, -128, -128, -128],
            [-128, -128, -128, -128],
            "worst positive lane products"
        ),
        (
            [-128, -128, -128, -128],
            [127, 127, 127, 127],
            "large negative dot product"
        ),
    ]

    acc = 0

    print("case,dot_raw,dot_real,acc_raw,acc_real")

    for a, b, label in vectors:
        d = dot4(a, b)
        acc = acc_step(acc, a, b)

        print(
            f"{label},{d},{real_from_raw(d):.8f},"
            f"{acc},{real_from_raw(acc):.8f}"
        )

    # Width proof for four signed 8x8 products.
    max_positive_dot = 4 * ((-128) * (-128))
    min_negative_dot = 4 * ((-128) * 127)

    assert max_positive_dot == 65536
    assert min_negative_dot == -65024

    # Signed 17-bit max is 65535, so 18 bits are required.
    assert max_positive_dot > (2**16 - 1)
    assert max_positive_dot <= (2**17 - 1)

    pe4_groups_by_dsp_only = DSP48E1_COUNT_XC7A35T // LANES
    used_dsp = pe4_groups_by_dsp_only * LANES
    remaining_dsp = DSP48E1_COUNT_XC7A35T - used_dsp

    clock_hz = 100_000_000
    products_per_second = LANES * clock_hz
    ops_per_second_mul_plus_add = 2 * LANES * clock_hz

    print()
    print(f"4-lane max positive dot raw = {max_positive_dot}")
    print(f"4-lane min negative dot raw = {min_negative_dot}")
    print("dot4 exact signed width = 18 bits")
    print()
    print(
        "DSP-only theoretical PE4 groups on XC7A35T = "
        f"{pe4_groups_by_dsp_only} groups "
        f"({used_dsp} DSP used, {remaining_dsp} remaining)"
    )
    print(
        "At 100 MHz: 4-lane product throughput = "
        f"{products_per_second:,} products/s"
    )
    print(
        "If multiply and add are counted as separate operations: "
        f"{ops_per_second_mul_plus_add / 1e9:.3f} GOPS"
    )
    print(
        "GOPS counting conventions vary; this is a theoretical arithmetic-rate "
        "illustration, not measured NPU performance."
    )
    print("SOC25 PYTHON PE4 REFERENCE: PASS")


if __name__ == "__main__":
    main()
