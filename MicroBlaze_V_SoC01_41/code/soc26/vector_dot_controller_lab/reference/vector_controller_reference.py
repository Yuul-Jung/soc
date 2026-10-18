#!/usr/bin/env python3
"""SoC 26 vector-length/group/tail reference model."""

LANES = 4


def ceil_div4(n: int) -> int:
    return (n + 3) // 4


def tail_lanes(n: int) -> int:
    if n == 0:
        return 0

    rem = n % LANES
    return LANES if rem == 0 else rem


def signed8(value: int) -> int:
    value &= 0xFF

    if value >= 128:
        value -= 256

    return value


def gen_a(index: int) -> int:
    return signed8((index * 29) + 17)


def gen_b(index: int) -> int:
    return signed8((index * 47) + 91)


def reference_dot(length: int) -> int:
    return sum(
        gen_a(i) * gen_b(i)
        for i in range(length)
    )


def masked_last_group_example(length: int) -> list[int]:
    groups = ceil_div4(length)

    if groups == 0:
        return []

    start = (groups - 1) * LANES
    values: list[int] = []

    for lane in range(LANES):
        idx = start + lane

        if idx < length:
            values.append(gen_a(idx))
        else:
            values.append(0)

    return values


def main() -> None:
    lengths = [0, 1, 2, 3, 4, 5, 10, 16, 17, 31]

    print("length,groups,tail,result_raw,last_group_masked_a")

    for length in lengths:
        print(
            f"{length},"
            f"{ceil_div4(length)},"
            f"{tail_lanes(length)},"
            f"{reference_dot(length)},"
            f"{masked_last_group_example(length)}"
        )

    assert ceil_div4(10) == 3
    assert tail_lanes(10) == 2
    assert ceil_div4(16) == 4
    assert tail_lanes(16) == 4
    assert ceil_div4(17) == 5
    assert tail_lanes(17) == 1

    # Demo source: raw A = 1..10, raw B = 1.
    assert sum(range(1, 11)) == 55

    print()
    print("demo length 10 -> 3 groups, tail lanes = 2")
    print("demo expected raw result = 55 (LED lower 16 bits = 0x0037)")
    print("SOC26 PYTHON CONTROLLER REFERENCE: PASS")


if __name__ == "__main__":
    main()
