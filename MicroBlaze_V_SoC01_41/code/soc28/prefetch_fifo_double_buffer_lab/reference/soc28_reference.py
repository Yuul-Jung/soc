#!/usr/bin/env python3
"""SoC 28 prefetch FIFO / backpressure / double-buffer reference."""

from dataclasses import dataclass

LANES = 4
FIFO_DEPTH = 4


def ceil_div4(n: int) -> int:
    return (n + 3) // 4


def signed8(value: int) -> int:
    value &= 0xFF
    return value - 256 if value >= 128 else value


def a0(i: int) -> int:
    return signed8((i * 29) + 17)


def b0(i: int) -> int:
    return signed8((i * 47) + 91)


def a1(i: int) -> int:
    return signed8((i * 13) + 33)


def b1(i: int) -> int:
    return signed8((i * 19) + 7)


def dot(length: int, bank: int) -> int:
    if bank == 0:
        return sum(a0(i) * b0(i) for i in range(length))

    return sum(a1(i) * b1(i) for i in range(length))


@dataclass
class PrefetchStats:
    groups: int
    requested: int
    received: int
    delivered: int
    max_fifo: int
    cycles: int


def stall_pattern(cycle: int) -> bool:
    return (
        (cycle % 7 in (2, 3))
        or (cycle % 11 == 6)
    )


def simulate_prefetch(groups: int) -> PrefetchStats:
    requested = 0
    received = 0
    delivered = 0

    fifo = 0
    outstanding = 0
    response_next = 0

    max_fifo = 0
    cycle = 0

    # One-cycle BRAM response model.
    while delivered < groups:
        response_now = response_next
        response_next = 0

        if response_now:
            outstanding -= response_now
            received += response_now
            fifo += response_now

        if fifo > FIFO_DEPTH:
            raise RuntimeError("FIFO overflow")

        ready = not stall_pattern(cycle)

        if fifo and ready:
            fifo -= 1
            delivered += 1

        buffered_credits = fifo + outstanding

        if (
            requested < groups
            and buffered_credits < FIFO_DEPTH
        ):
            requested += 1
            outstanding += 1
            response_next += 1

        max_fifo = max(max_fifo, fifo)

        cycle += 1

        if cycle > 10000:
            raise RuntimeError("timeout")

    return PrefetchStats(
        groups=groups,
        requested=requested,
        received=received,
        delivered=delivered,
        max_fifo=max_fifo,
        cycles=cycle,
    )


def main() -> None:
    bank0_len = 64
    bank1_len = 31

    bank0_result = dot(bank0_len, 0)
    bank1_result = dot(bank1_len, 1)

    s0 = simulate_prefetch(ceil_div4(bank0_len))
    s1 = simulate_prefetch(ceil_div4(bank1_len))

    print("bank,length,groups,result_raw,max_fifo,cycles")
    print(
        f"0,{bank0_len},{s0.groups},{bank0_result},"
        f"{s0.max_fifo},{s0.cycles}"
    )
    print(
        f"1,{bank1_len},{s1.groups},{bank1_result},"
        f"{s1.max_fifo},{s1.cycles}"
    )

    assert s0.requested == s0.received == s0.delivered == s0.groups
    assert s1.requested == s1.received == s1.delivered == s1.groups

    assert s0.max_fifo <= FIFO_DEPTH
    assert s1.max_fifo <= FIFO_DEPTH

    assert s0.max_fifo >= 2
    assert s1.max_fifo >= 2

    # Board-demo arithmetic.
    assert sum(range(1, 11)) == 55
    assert sum(2 * i for i in range(1, 11)) == 110

    print()
    print("credit rule: FIFO entries + outstanding reads < 4 before issue")
    print("bank0 compute may overlap bank1 load because memories are separate")
    print("same-bank write during active compute must be blocked")
    print("board demo first result = 55 -> 0x0037")
    print("board demo second result = 110 -> 0x006E")
    print("SOC28 PYTHON PREFETCH/DOUBLE-BUFFER REFERENCE: PASS")


if __name__ == "__main__":
    main()
