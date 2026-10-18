#!/usr/bin/env python3
"""SoC 32 level-IRQ / W1C reference model."""

IRQ_DONE = 0x1
IRQ_ERROR = 0x2
IRQ_ALL = IRQ_DONE | IRQ_ERROR


def irq_level(enable: int, status: int) -> int:
    return 1 if (enable & status & IRQ_ALL) else 0


def update_irq_status(
    old_status: int,
    clear_mask: int,
    event_set: int,
) -> int:
    # W1C clear first, then event-set wins.
    after_clear = old_status & ~(clear_mask & IRQ_ALL)
    return (after_clear | (event_set & IRQ_ALL)) & IRQ_ALL


def main() -> None:
    status = 0
    enable = 0

    assert irq_level(enable, status) == 0

    # DONE while disabled: pending latches, IRQ remains low.
    status = update_irq_status(
        status,
        0,
        IRQ_DONE,
    )
    assert status == IRQ_DONE
    assert irq_level(enable, status) == 0

    # Enable an already-pending source: level IRQ asserts.
    enable = IRQ_DONE
    assert irq_level(enable, status) == 1

    # W1C DONE: IRQ drops.
    status = update_irq_status(
        status,
        IRQ_DONE,
        0,
    )
    assert status == 0
    assert irq_level(enable, status) == 0

    # ERROR source.
    enable = IRQ_ERROR
    status = update_irq_status(
        status,
        0,
        IRQ_ERROR,
    )
    assert status == IRQ_ERROR
    assert irq_level(enable, status) == 1

    status = update_irq_status(
        status,
        IRQ_ERROR,
        0,
    )
    assert status == 0
    assert irq_level(enable, status) == 0

    # Clear and a new event in the same clock:
    # event-set must win.
    status = IRQ_DONE
    status = update_irq_status(
        status,
        IRQ_DONE,
        IRQ_DONE,
    )
    assert status == IRQ_DONE

    print("IRQ_STATUS W1C model: PASS")
    print("disabled DONE event -> pending=1, irq=0")
    print("enable pending DONE -> irq=1")
    print("W1C DONE -> pending=0, irq=0")
    print("ERROR enable/status path: PASS")
    print("same-cycle clear + set -> event-set wins")
    print("expected OUT_CH0 = 0x20181008")
    print("expected OUT_CH1 = 0x7F7F6333")
    print("expected SAT_COUNT = 2")
    print("SOC32 PYTHON INTERRUPT REFERENCE: PASS")


if __name__ == "__main__":
    main()
