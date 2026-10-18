#!/usr/bin/env python3
"""SoC39 static serial-vs-parallel requant comparison.

Cycle origin:
engine START acceptance / busy rising -> IRQ pending.

This is a structural RTL schedule model, not a Vivado or board measurement.
"""

CLOCK_HZ = 100_000_000
CLOCK_NS = 10.0

READ_PHASE = 9
SERIAL_REQUANT = 14
PARALLEL4_REQUANT = 8
FINISH_IRQ = 5


def main() -> None:
    soc38_cycles = (
        READ_PHASE +
        SERIAL_REQUANT +
        FINISH_IRQ
    )

    soc39_cycles = (
        READ_PHASE +
        PARALLEL4_REQUANT +
        FINISH_IRQ
    )

    saved = soc38_cycles - soc39_cycles

    latency_reduction = (
        saved /
        soc38_cycles *
        100.0
    )

    soc38_jobs_s = CLOCK_HZ / soc38_cycles
    soc39_jobs_s = CLOCK_HZ / soc39_cycles

    throughput_gain = (
        soc39_jobs_s /
        soc38_jobs_s -
        1.0
    ) * 100.0

    assert soc38_cycles == 28
    assert soc39_cycles == 22
    assert saved == 6

    print("SoC39 STATIC PARALLEL-REQUANT COMPARISON")
    print(f"clock = {CLOCK_HZ / 1e6:.0f} MHz")
    print()
    print(
        f"SoC38 read/requant/finish = "
        f"{READ_PHASE}/{SERIAL_REQUANT}/{FINISH_IRQ}"
    )
    print(
        f"SoC39 read/requant/finish = "
        f"{READ_PHASE}/{PARALLEL4_REQUANT}/{FINISH_IRQ}"
    )
    print()
    print(
        f"SoC38 total = {soc38_cycles} cycles "
        f"({soc38_cycles * CLOCK_NS:.1f} ns)"
    )
    print(
        f"SoC39 total = {soc39_cycles} cycles "
        f"({soc39_cycles * CLOCK_NS:.1f} ns)"
    )
    print(f"saved = {saved} cycles")
    print(
        "static latency reduction vs SoC38 = "
        f"{latency_reduction:.1f}%"
    )
    print(
        "SoC38 upper jobs/s = "
        f"{soc38_jobs_s:,.3f}"
    )
    print(
        "SoC39 upper jobs/s = "
        f"{soc39_jobs_s:,.3f}"
    )
    print(
        "static upper throughput gain vs SoC38 = "
        f"{throughput_gain:.1f}%"
    )
    print()
    print("SPATIAL TRADE-OFF:")
    print("- requant core instances: 1 -> 4")
    print("- actual DSP48 count is NOT assumed")
    print("- 33x16 multiply is wider than one 25x18 DSP48E1 multiplier input")
    print("- synthesis must report the actual DSP/LUT mapping")
    print()
    print("NOT MEASURED:")
    print("- WNS/TNS/WHS/THS")
    print("- DSP48/LUT/FF delta")
    print("- power delta")
    print("- Basys3 runtime")
    print("SOC39 STATIC PARALLEL4 REFERENCE: PASS")


if __name__ == "__main__":
    main()
