#!/usr/bin/env python3
"""SoC35 full accelerator integration reference."""

IRQ_DONE = 0x1
IRQ_ERROR = 0x2


def requant(
    acc: int,
    bias: int,
    mult: int,
    shift: int,
    zp: int,
) -> int:
    value = (acc + bias) * mult

    if shift:
        mag = abs(value)
        mag = (mag + (1 << (shift - 1))) >> shift
        value = -mag if value < 0 else mag

    value += zp
    return max(-128, min(127, value))


def pack_s8(values: list[int]) -> int:
    packed = 0

    for index, value in enumerate(values):
        packed |= (value & 0xFF) << (index * 8)

    return packed


def main() -> None:
    tensor = {
        0x200: 16,
        0x204: 32,
        0x208: 48,
        0x20C: 64,
        0x210: 32,
        0x214: 64,
        0x218: 96,
        0x21C: 128,
    }

    active = {
        "input_base": 0x200,
        "output_base": 0x300,
        "length_words": 8,
    }

    shadow = active.copy()

    # Current job snapshot stays stable.
    shadow["input_base"] = 0x400
    shadow["output_base"] = 0x500

    assert active["input_base"] == 0x200
    assert active["output_base"] == 0x300

    ch0 = [
        tensor[active["input_base"] + i * 4]
        for i in range(4)
    ]

    ch1 = [
        tensor[active["input_base"] + (i + 4) * 4]
        for i in range(4)
    ]

    q0 = [requant(x, 0, 1, 1, 0) for x in ch0]
    q1 = [requant(x, 4, 3, 1, -3) for x in ch1]

    out0 = pack_s8(q0)
    out1 = pack_s8(q1)

    assert out0 == 0x20181008
    assert out1 == 0x7F7F6333

    irq_enable = IRQ_DONE | IRQ_ERROR
    irq_status = IRQ_DONE

    assert (irq_enable & irq_status) != 0

    # ISR W1C
    irq_status &= ~IRQ_DONE
    assert (irq_enable & irq_status) == 0

    print("Control Plane: AXI4-Lite descriptor + IRQ")
    print("Data Plane: Tensor BRAM native Port B")
    print("active INPUT_BASE = 0x200")
    print("active OUTPUT_BASE = 0x300")
    print("shadow change during BUSY does not affect active snapshot: PASS")
    print(f"OUT_CH0 = 0x{out0:08X}")
    print(f"OUT_CH1 = 0x{out1:08X}")
    print("DONE pending + enable -> level IRQ: PASS")
    print("W1C DONE -> IRQ deassert: PASS")
    print("descriptor reject -> ERROR IRQ path: required by RTL/TB")
    print("SOC35 PYTHON FULL-INTEGRATION REFERENCE: PASS")


if __name__ == "__main__":
    main()
