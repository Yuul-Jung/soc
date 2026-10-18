#!/usr/bin/env python3
"""SoC38 static baseline vs pipelined-BRAM-read comparison.

These are cycle-schedule results from engine START acceptance to IRQ pending.
They are not post-route timing or Basys3 runtime measurements.
"""

CLOCK_HZ = 100_000_000
CLOCK_NS = 10.0

BASELINE_READ = 16
FAST_READ = 9

REQUANT = 14
FINISH_IRQ = 5


def main() -> None:
    baseline_cycles = (
        BASELINE_READ +
        REQUANT +
        FINISH_IRQ
    )

    fast_cycles = (
        FAST_READ +
        REQUANT +
        FINISH_IRQ
    )

    saved_cycles = baseline_cycles - fast_cycles

    latency_reduction_pct = (
        saved_cycles /
        baseline_cycles *
        100.0
    )

    baseline_jobs_s = (
        CLOCK_HZ /
        baseline_cycles
    )

    fast_jobs_s = (
        CLOCK_HZ /
        fast_cycles
    )

    throughput_gain_pct = (
        fast_jobs_s /
        baseline_jobs_s -
        1.0
    ) * 100.0

    assert baseline_cycles == 35
    assert fast_cycles == 28
    assert saved_cycles == 7

    print("SoC38 STATIC OPTIMIZATION COMPARISON")
    print(f"clock = {CLOCK_HZ / 1e6:.0f} MHz")
    print()
    print(
        f"baseline read = {BASELINE_READ} cycles, "
        f"total = {baseline_cycles} cycles "
        f"({baseline_cycles * CLOCK_NS:.1f} ns)"
    )
    print(
        f"fast read = {FAST_READ} cycles, "
        f"total = {fast_cycles} cycles "
        f"({fast_cycles * CLOCK_NS:.1f} ns)"
    )
    print(f"saved = {saved_cycles} cycles")
    print(
        "static latency reduction = "
        f"{latency_reduction_pct:.1f}%"
    )
    print(
        "baseline upper jobs/s = "
        f"{baseline_jobs_s:,.3f}"
    )
    print(
        "optimized upper jobs/s = "
        f"{fast_jobs_s:,.3f}"
    )
    print(
        "static upper throughput gain = "
        f"{throughput_gain_pct:.1f}%"
    )
    print()
    print("ASSUMPTION:")
    print("- synchronous BRAM Port-B read latency = 1 clock")
    print("- no extra optional BMG output pipeline beyond this model")
    print("- same 100 MHz target")
    print()
    print("NOT MEASURED:")
    print("- WNS/TNS")
    print("- resource delta")
    print("- power delta")
    print("- MicroBlaze V/ISR latency")
    print("- board throughput")
    print("SOC38 STATIC OPTIMIZATION REFERENCE: PASS")


if __name__ == "__main__":
    main()
