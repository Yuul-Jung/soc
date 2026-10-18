#!/usr/bin/env python3
"""SoC 30 integer-only requantization reference."""

from dataclasses import dataclass


@dataclass
class RequantResult:
    q: int
    rounded: int
    shifted: int
    sat_pos: bool
    sat_neg: bool


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
    multiplier: int,
    shift: int,
    zero_point: int,
) -> RequantResult:
    biased = acc + bias
    product = biased * multiplier

    rounded = round_away_from_zero_div_pow2(
        product,
        shift,
    )

    shifted = rounded + zero_point

    sat_pos = shifted > 127
    sat_neg = shifted < -128

    if sat_pos:
        q = 127
    elif sat_neg:
        q = -128
    else:
        q = shifted

    return RequantResult(
        q=q,
        rounded=rounded,
        shifted=shifted,
        sat_pos=sat_pos,
        sat_neg=sat_neg,
    )


def run_directed() -> None:
    cases = [
        (3, 0, 1, 1, 0, 2),
        (-3, 0, 1, 1, 0, -2),
        (1, 0, 1, 1, 0, 1),
        (-1, 0, 1, 1, 0, -1),
        (200, 0, 1, 0, 0, 127),
        (-200, 0, 1, 0, 0, -128),
        (10, 0, 1, 0, 5, 15),
        (-10, 0, 1, 0, 5, -5),
    ]

    for case in cases:
        acc, bias, mult, shift, zp, expected = case
        actual = requant(
            acc,
            bias,
            mult,
            shift,
            zp,
        )

        assert actual.q == expected, (
            case,
            actual,
        )


def board_demo() -> None:
    ch0_acc = [16, 32, 48, 64]
    ch1_acc = [32, 64, 96, 128]

    ch0 = [
        requant(x, 0, 1, 1, 0)
        for x in ch0_acc
    ]

    ch1 = [
        requant(x, 4, 3, 1, -3)
        for x in ch1_acc
    ]

    ch0_q = [x.q for x in ch0]
    ch1_q = [x.q for x in ch1]

    assert ch0_q == [8, 16, 24, 32]
    assert ch1_q == [51, 99, 127, 127]

    sat_count = sum(
        x.sat_pos or x.sat_neg
        for x in [*ch0, *ch1]
    )

    assert sat_count == 2

    print(f"CH0 int32 -> int8 = {ch0_q}")
    print(f"CH1 int32 -> int8 = {ch1_q}")
    print(f"saturation count = {sat_count}")
    print("selected LED = 0x207F")


def main() -> None:
    run_directed()

    print("rounding midpoint checks:")
    print(
        "+3 / 2 ->",
        requant(3, 0, 1, 1, 0).q,
    )
    print(
        "-3 / 2 ->",
        requant(-3, 0, 1, 1, 0).q,
    )
    print(
        "+1 / 2 ->",
        requant(1, 0, 1, 1, 0).q,
    )
    print(
        "-1 / 2 ->",
        requant(-1, 0, 1, 1, 0).q,
    )

    print()
    board_demo()

    print()
    print(
        "formula: saturate_int8("
        "round_away_from_zero((acc+bias)*mult / 2^shift)"
        " + zero_point)"
    )
    print("SOC30 PYTHON REQUANTIZATION REFERENCE: PASS")


if __name__ == "__main__":
    main()
