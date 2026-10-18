#!/usr/bin/env python3
"""SoC41 Group-8 cumulative static-performance reference.

These values are derived from the RTL schedule used in SoC37..40.
They are not Vivado post-route measurements and not Basys3 runtime data.
"""

CLOCK_HZ = 100_000_000
CLOCK_NS = 10.0

stages = [
    ("SoC37 Baseline", 35, "Baseline"),
    ("SoC38 BRAM Read Pipeline", 28, "Read bubble removal"),
    ("SoC39 Parallel4 Requant", 22, "Spatial parallelism"),
    ("SoC40 Data/Compute Overlap", 16, "Prefetch + overlap"),
]


def pct_reduction(old: float, new: float) -> float:
    return (old - new) / old * 100.0


def pct_gain(old: float, new: float) -> float:
    return (new / old - 1.0) * 100.0


def main() -> None:
    print("SoC41 GROUP-8 STATIC PROGRESSION")
    print(f"clock = {CLOCK_HZ / 1e6:.0f} MHz")
    print()

    previous_cycles = None
    baseline_cycles = stages[0][1]
    baseline_jobs_s = CLOCK_HZ / baseline_cycles

    for name, cycles, change in stages:
        latency_ns = cycles * CLOCK_NS
        jobs_s = CLOCK_HZ / cycles

        if previous_cycles is None:
            step_latency = 0.0
        else:
            step_latency = pct_reduction(
                previous_cycles,
                cycles,
            )

        cumulative_latency = pct_reduction(
            baseline_cycles,
            cycles,
        )

        cumulative_throughput = pct_gain(
            baseline_jobs_s,
            jobs_s,
        )

        print(
            f"{name}: "
            f"{cycles} cycles, "
            f"{latency_ns:.1f} ns, "
            f"{jobs_s:,.3f} upper jobs/s"
        )
        print(
            f"  change = {change}"
        )
        print(
            f"  step latency reduction = "
            f"{step_latency:.1f}%"
        )
        print(
            f"  cumulative latency reduction = "
            f"{cumulative_latency:.1f}%"
        )
        print(
            f"  cumulative upper-throughput gain = "
            f"{cumulative_throughput:.1f}%"
        )

        previous_cycles = cycles

    assert stages[0][1] == 35
    assert stages[-1][1] == 16

    saved = stages[0][1] - stages[-1][1]

    assert saved == 19

    print()
    print("GROUP-8 STATIC RESULT")
    print("35 -> 16 cycles")
    print("350.0 ns -> 160.0 ns @ 100 MHz")
    print("19 cycles saved")
    print("cumulative static latency reduction = 54.3%")
    print("cumulative static upper-throughput gain = 118.8%")
    print()
    print("IMPORTANT:")
    print("- These are RTL schedule values.")
    print("- WNS/TNS/WHS/THS are not measured here.")
    print("- LUT/FF/DSP/BRAM are not measured here.")
    print("- Power/thermal are not measured here.")
    print("- Basys3 START->ISR and end-to-end latency are not measured here.")
    print("SOC41 GROUP8 STATIC REFERENCE: PASS")


if __name__ == "__main__":
    main()
