#!/usr/bin/env python3
"""SoC 24 signed fixed-point MAC reference model."""

FRAC_BITS = 7
PRODUCT_FRAC_BITS = FRAC_BITS * 2
ACC_BITS = 32

DIRECTED = [
    (64, -32),
    (127, 127),
    (-128, 127),
    (-128, -128),
    (1, -1),
    (0, 127),
]


def wrap_signed(value: int, bits: int) -> int:
    mask = (1 << bits) - 1
    value &= mask
    sign = 1 << (bits - 1)

    if value & sign:
        value -= 1 << bits

    return value


def mac_step(acc: int, a: int, b: int) -> int:
    product = a * b
    return wrap_signed(acc + product, ACC_BITS)


def to_real_input(raw: int) -> float:
    return raw / float(1 << FRAC_BITS)


def to_real_acc(raw: int) -> float:
    return raw / float(1 << PRODUCT_FRAC_BITS)


def main() -> None:
    acc = 0

    print("a_raw,b_raw,a_real,b_real,product_raw,acc_raw,acc_real")

    for a, b in DIRECTED:
        product = a * b
        acc = mac_step(acc, a, b)

        print(
            f"{a},{b},"
            f"{to_real_input(a):.8f},"
            f"{to_real_input(b):.8f},"
            f"{product},{acc},"
            f"{to_real_acc(acc):.8f}"
        )

    assert 64 * -32 == -2048
    assert to_real_acc(-2048) == -0.125

    print("SOC24 PYTHON FIXED-POINT REFERENCE: PASS")


if __name__ == "__main__":
    main()
