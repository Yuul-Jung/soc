#!/usr/bin/env python3
"""SoC37 static RTL cycle schedule and throughput reference.

This is a deterministic schedule model derived from the frozen SoC35/36 RTL.
It is not a Vivado timing measurement and not a Basys3 hardware measurement.
"""

CLOCK_HZ = 100_000_000
CLOCK_NS = 10.0

INPUT_WORDS = 8
OUTPUT_WORDS = 2


def main() -> None:
    # From tensor_job_engine start_i sampled high to IRQ_STATUS.DONE visible.
    #
    # 16 cycles : 8 synchronous BRAM reads
    #             READ_REQ + READ_CAPTURE per word
    #
    # 14 cycles : requant launch + serial feed + 4-stage pipeline drain
    #
    #  5 cycles : result handoff + 2 output writes + DONE + IRQ latch
    #
    # Total = 35 cycles.
    read_cycles = 16
    requant_cycles = 14
    finish_cycles = 5

    total_cycles = (
        read_cycles +
        requant_cycles +
        finish_cycles
    )

    total_ns = total_cycles * CLOCK_NS

    jobs_per_sec_upper = CLOCK_HZ / total_cycles
    scalar_outputs_per_sec_upper = (
        jobs_per_sec_upper * 8
    )

    assert total_cycles == 35
    assert total_ns == 350.0

    print("SoC37 STATIC RTL SCHEDULE")
    print(f"clock = {CLOCK_HZ / 1e6:.0f} MHz ({CLOCK_NS:.1f} ns)")
    print(f"BRAM read phase = {read_cycles} cycles")
    print(f"requant phase = {requant_cycles} cycles")
    print(f"finish/IRQ phase = {finish_cycles} cycles")
    print(f"engine START accept -> IRQ pending = {total_cycles} cycles")
    print(f"static schedule time = {total_ns:.1f} ns")
    print(f"upper-bound jobs/s = {jobs_per_sec_upper:,.3f}")
    print(
        "upper-bound scalar outputs/s = "
        f"{scalar_outputs_per_sec_upper:,.3f}"
    )
    print()
    print("IMPORTANT:")
    print("- This excludes AXI START transaction latency.")
    print("- This excludes CPU Tensor fill/read.")
    print("- This excludes ISR/software overhead.")
    print("- This is not WNS/TNS or post-route timing.")
    print("- Actual performance must be measured in Vivado/board.")
    print("SOC37 STATIC PERFORMANCE REFERENCE: PASS")


if __name__ == "__main__":
    main()
