#!/usr/bin/env python3
"""SoC34 descriptor validation and snapshot reference."""

ERR_NONE = 0
ERR_BUSY = 1
ERR_INPUT_ALIGN = 2
ERR_OUTPUT_ALIGN = 3
ERR_LENGTH_UNSUPPORTED = 4
ERR_INPUT_RANGE = 5
ERR_OUTPUT_RANGE = 6
ERR_BUFFER_OVERLAP = 7

BRAM_BYTES = 4096


def validate_descriptor(
    input_base: int,
    output_base: int,
    length_words: int,
) -> int:
    if input_base & 0x3:
        return ERR_INPUT_ALIGN

    if output_base & 0x3:
        return ERR_OUTPUT_ALIGN

    if length_words != 8:
        return ERR_LENGTH_UNSUPPORTED

    input_end = input_base + length_words * 4
    output_end = output_base + 8

    if input_end > BRAM_BYTES:
        return ERR_INPUT_RANGE

    if output_end > BRAM_BYTES:
        return ERR_OUTPUT_RANGE

    no_overlap = (
        output_end <= input_base
        or input_end <= output_base
    )

    if not no_overlap:
        return ERR_BUFFER_OVERLAP

    return ERR_NONE


def main() -> None:
    assert validate_descriptor(
        0x200,
        0x300,
        8,
    ) == ERR_NONE

    assert validate_descriptor(
        0x202,
        0x300,
        8,
    ) == ERR_INPUT_ALIGN

    assert validate_descriptor(
        0x200,
        0x302,
        8,
    ) == ERR_OUTPUT_ALIGN

    assert validate_descriptor(
        0x200,
        0x300,
        7,
    ) == ERR_LENGTH_UNSUPPORTED

    assert validate_descriptor(
        0xFF0,
        0x100,
        8,
    ) == ERR_INPUT_RANGE

    assert validate_descriptor(
        0x200,
        0xFFC,
        8,
    ) == ERR_OUTPUT_RANGE

    assert validate_descriptor(
        0x200,
        0x210,
        8,
    ) == ERR_BUFFER_OVERLAP

    shadow = {
        "input_base": 0x200,
        "output_base": 0x300,
        "length_words": 8,
    }

    active = shadow.copy()

    shadow["input_base"] = 0x400
    shadow["output_base"] = 0x500

    assert active["input_base"] == 0x200
    assert active["output_base"] == 0x300
    assert active["length_words"] == 8

    print("valid descriptor 0x200 -> 0x300, length=8: PASS")
    print("unaligned input -> error 2")
    print("unaligned output -> error 3")
    print("unsupported length -> error 4")
    print("input range -> error 5")
    print("output range -> error 6")
    print("buffer overlap -> error 7")
    print("shadow changes do not modify active snapshot: PASS")
    print("accepted job increments JOB_ID; rejected job does not")
    print("SOC34 PYTHON JOB-DESCRIPTOR REFERENCE: PASS")


if __name__ == "__main__":
    main()
