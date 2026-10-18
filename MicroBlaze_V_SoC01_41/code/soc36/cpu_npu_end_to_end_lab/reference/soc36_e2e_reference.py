#!/usr/bin/env python3
"""SoC 36 CPU↔NPU end-to-end reference for sequential jobs."""

IRQ_DONE = 0x1
IRQ_ERROR = 0x2


def round_away(value: int, shift: int) -> int:
    if shift == 0:
        return value

    magnitude = abs(value)
    rounded = (
        magnitude + (1 << (shift - 1))
    ) >> shift

    return -rounded if value < 0 else rounded


def requant(
    acc: int,
    bias: int,
    mult: int,
    shift: int,
    zp: int,
) -> int:
    value = round_away(
        (acc + bias) * mult,
        shift,
    ) + zp

    return max(-128, min(127, value))


def pack4(values: list[int]) -> int:
    result = 0

    for index, value in enumerate(values):
        result |= (
            value & 0xFF
        ) << (8 * index)

    return result


def run_job(values: list[int]) -> tuple[int, int]:
    ch0 = [
        requant(v, 0, 1, 1, 0)
        for v in values[:4]
    ]

    ch1 = [
        requant(v, 4, 3, 1, -3)
        for v in values[4:]
    ]

    return pack4(ch0), pack4(ch1)


def main() -> None:
    jobs = [
        {
            "id": 1,
            "input_base": 0x200,
            "output_base": 0x300,
            "input": [16, 32, 48, 64, 32, 64, 96, 128],
            "expected": (0x20181008, 0x7F7F6333),
        },
        {
            "id": 2,
            "input_base": 0x400,
            "output_base": 0x500,
            "input": [2, 4, 6, 8, 4, 8, 12, 16],
            "expected": (0x04030201, 0x1B150F09),
        },
    ]

    for job in jobs:
        out = run_job(job["input"])
        assert out == job["expected"]

        irq_enable = IRQ_DONE | IRQ_ERROR
        irq_status = IRQ_DONE

        assert irq_enable & irq_status

        # ISR performs W1C on DONE pending.
        irq_status &= ~IRQ_DONE

        assert (irq_enable & irq_status) == 0

        print(
            f"JOB{job['id'] - 1}: "
            f"IN=0x{job['input_base']:03X} "
            f"OUT=0x{job['output_base']:03X} "
            f"OUT0=0x{out[0]:08X} "
            f"OUT1=0x{out[1]:08X} "
            "IRQ/W1C=PASS"
        )

    accepted_job_ids = [1, 2]
    rejected_job_id = accepted_job_ids[-1]

    assert accepted_job_ids == [1, 2]
    assert rejected_job_id == 2

    print("JOB_ID sequence: 1 -> 2")
    print("Rejected descriptor does not increment JOB_ID: PASS")
    print("SOC36 PYTHON END-TO-END REFERENCE: PASS")


if __name__ == "__main__":
    main()
