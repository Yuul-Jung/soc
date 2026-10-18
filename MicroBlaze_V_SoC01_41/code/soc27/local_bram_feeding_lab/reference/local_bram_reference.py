#!/usr/bin/env python3
"""SoC 27 local BRAM / address generator reference."""

LANES = 4
ADDR_WIDTH = 8
DEPTH_WORDS = 1 << ADDR_WIDTH
MAX_ELEMENTS = DEPTH_WORDS * LANES


def ceil_div4(n: int) -> int:
    return (n + 3) // 4


def signed8(value: int) -> int:
    value &= 0xFF
    return value - 256 if value >= 128 else value


def gen_a(index: int) -> int:
    return signed8((index * 29) + 17)


def gen_b(index: int) -> int:
    return signed8((index * 47) + 91)


def dot(length: int) -> int:
    return sum(
        gen_a(i) * gen_b(i)
        for i in range(length)
    )


def raw_local_bandwidth_bits_per_sec(
    clock_hz: int
) -> int:
    # Activation 32 bit + Weight 32 bit each cycle.
    return 64 * clock_hz


def main() -> None:
    lengths = [0, 1, 2, 3, 4, 5, 10, 16, 17, 31, 64]

    print("length,groups,result_raw")

    for length in lengths:
        print(
            f"{length},"
            f"{ceil_div4(length)},"
            f"{dot(length)}"
        )

    assert DEPTH_WORDS == 256
    assert MAX_ELEMENTS == 1024
    assert ceil_div4(MAX_ELEMENTS) == 256

    demo_result = sum(range(1, 11))
    assert demo_result == 55

    bw = raw_local_bandwidth_bits_per_sec(
        100_000_000
    )

    print()
    print(f"buffer depth = {DEPTH_WORDS} x 32 bit per BRAM array")
    print(f"maximum scalar elements = {MAX_ELEMENTS}")
    print("length 1025 -> range error")
    print("demo length 10 -> expected raw result 55 -> LED 0x0037")
    print(
        "100 MHz local read payload = "
        f"{bw / 1e9:.3f} Gbit/s = {bw / 8 / 1e6:.1f} MB/s"
    )
    print(
        "Bandwidth number is an interface payload rate, "
        "not measured external-memory performance."
    )
    print("SOC27 PYTHON LOCAL BRAM REFERENCE: PASS")


if __name__ == "__main__":
    main()
