#!/usr/bin/env python3
"""SoC31 register-map / software-hardware contract reference."""

REG = {
    "CONTROL": 0x00,
    "STATUS": 0x04,
    "VERSION": 0x08,
    "SAT_COUNT": 0x0C,
    "BIAS_CH0": 0x10,
    "BIAS_CH1": 0x14,
    "SCALE_CH0": 0x18,
    "SCALE_CH1": 0x1C,
    "ZERO_POINT": 0x20,
    "ACC_IN0": 0x40,
    "ACC_IN1": 0x44,
    "ACC_IN2": 0x48,
    "ACC_IN3": 0x4C,
    "ACC_IN4": 0x50,
    "ACC_IN5": 0x54,
    "ACC_IN6": 0x58,
    "ACC_IN7": 0x5C,
    "OUT_CH0": 0x60,
    "OUT_CH1": 0x64,
    "CYCLE_COUNT": 0x68,
}


def apply_wstrb(old: int, new: int, strobe: int) -> int:
    result = old & 0xFFFFFFFF

    for lane in range(4):
        if strobe & (1 << lane):
            mask = 0xFF << (lane * 8)
            result = (
                (result & ~mask)
                | (new & mask)
            )

    return result & 0xFFFFFFFF


def pack_scale(mult: int, shift: int) -> int:
    return (
        (mult & 0xFFFF)
        | ((shift & 0x3F) << 16)
    )


def pack_zp(ch0: int, ch1: int) -> int:
    return (
        (ch0 & 0xFFFF)
        | ((ch1 & 0xFFFF) << 16)
    )


def main() -> None:
    offsets = list(REG.values())

    assert len(offsets) == len(set(offsets))
    assert all((x % 4) == 0 for x in offsets)

    assert REG["CONTROL"] == 0x00
    assert REG["STATUS"] == 0x04
    assert REG["ACC_IN0"] == 0x40
    assert REG["ACC_IN7"] == 0x5C
    assert REG["OUT_CH0"] == 0x60
    assert REG["OUT_CH1"] == 0x64

    # AXI WSTRB byte semantics.
    old = 0x11223344
    new = 0xAABBCCDD

    assert apply_wstrb(old, new, 0b0001) == 0x112233DD
    assert apply_wstrb(old, new, 0b0010) == 0x1122CC44
    assert apply_wstrb(old, new, 0b0100) == 0x11BB3344
    assert apply_wstrb(old, new, 0b1000) == 0xAA223344
    assert apply_wstrb(old, new, 0b1111) == 0xAABBCCDD

    assert pack_scale(1, 1) == 0x00010001
    assert pack_scale(3, 1) == 0x00010003
    assert pack_zp(0, -3) == 0xFFFD0000

    print("Register map:")
    for name, offset in REG.items():
        print(f"{name:12s} 0x{offset:02X}")

    print()
    print("WSTRB partial-write model: PASS")
    print("scale CH0 demo = 0x%08X" % pack_scale(1, 1))
    print("scale CH1 demo = 0x%08X" % pack_scale(3, 1))
    print("zero-point demo = 0x%08X" % pack_zp(0, -3))
    print("expected OUT_CH0 = 0x20181008")
    print("expected OUT_CH1 = 0x7F7F6333")
    print("expected SAT_COUNT = 2")
    print("SOC31 PYTHON REGISTER-MAP REFERENCE: PASS")


if __name__ == "__main__":
    main()
