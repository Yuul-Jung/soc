#!/usr/bin/env python3
"""SoC40 static overlap schedule reference.

Cycle origin:
engine START acceptance / busy rising -> IRQ pending.

This models the intended RTL schedule and is not board measurement.
"""

CLOCK_HZ = 100_000_000
CLOCK_NS = 10.0

SOC39_TOTAL = 22
SOC40_TOTAL = 16


def main() -> None:
    saved = SOC39_TOTAL - SOC40_TOTAL

    latency_reduction = (
        saved / SOC39_TOTAL * 100.0
    )

    soc39_jobs_s = CLOCK_HZ / SOC39_TOTAL
    soc40_jobs_s = CLOCK_HZ / SOC40_TOTAL

    throughput_gain = (
        soc40_jobs_s / soc39_jobs_s - 1.0
    ) * 100.0

    assert saved == 6

    print("SoC40 STATIC DATA-COMPUTE OVERLAP")
    print(f"clock = {CLOCK_HZ / 1e6:.0f} MHz")
    print()
    print("key schedule:")
    print("E1..E8  : continuous read issue")
    print("E2..E9  : continuous read capture")
    print("E6       : launch CH0 group after ping buffer ready")
    print("E10      : write CH0 + launch CH1")
    print("E14      : write CH1")
    print("E15      : engine done pulse")
    print("E16      : control IRQ pending visible")
    print()
    print(f"SoC39 total = {SOC39_TOTAL} cycles ({SOC39_TOTAL * CLOCK_NS:.1f} ns)")
    print(f"SoC40 total = {SOC40_TOTAL} cycles ({SOC40_TOTAL * CLOCK_NS:.1f} ns)")
    print(f"saved = {saved} cycles")
    print(f"static latency reduction vs SoC39 = {latency_reduction:.1f}%")
    print(f"SoC39 upper jobs/s = {soc39_jobs_s:,.3f}")
    print(f"SoC40 upper jobs/s = {soc40_jobs_s:,.3f}")
    print(f"static upper throughput gain vs SoC39 = {throughput_gain:.1f}%")
    print()
    print("OVERLAP PRINCIPLE:")
    print("- ping buffer: CH0 words 0..3")
    print("- pong buffer: CH1 words 4..7")
    print("- CH0 compute overlaps CH1 prefetch")
    print("- BRAM remains synchronous")
    print("- no board/runtime measurement is claimed")
    print("SOC40 STATIC OVERLAP REFERENCE: PASS")


if __name__ == "__main__":
    main()
