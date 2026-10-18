#!/usr/bin/env python3
"""SoC 29 weight-stationary / activation-broadcast / tiling reference."""

BATCH = 4
OUT_CH = 2
K = 16
TILE_K = 4


def signed8(value: int) -> int:
    value &= 0xFF
    return value - 256 if value >= 128 else value


def w0(k: int) -> int:
    return signed8(((k * 3) + 5) % 17 - 8)


def w1(k: int) -> int:
    return signed8(((k * 5) + 2) % 19 - 9)


def act(sample: int, k: int) -> int:
    return signed8(
        (((sample + 1) * 7) + (k * 4)) % 23 - 11
    )


def reference_results() -> tuple[list[int], list[int]]:
    ch0 = []
    ch1 = []

    for sample in range(BATCH):
        ch0.append(
            sum(act(sample, k) * w0(k) for k in range(K))
        )
        ch1.append(
            sum(act(sample, k) * w1(k) for k in range(K))
        )

    return ch0, ch1


def traffic() -> dict[str, float]:
    # Scalar int8 traffic only.
    naive_weight = BATCH * OUT_CH * K
    naive_activation = BATCH * OUT_CH * K

    ws_weight = OUT_CH * K
    broadcast_activation = BATCH * K

    naive_total = naive_weight + naive_activation
    optimized_total = ws_weight + broadcast_activation

    return {
        "naive_weight": naive_weight,
        "ws_weight": ws_weight,
        "weight_reuse": naive_weight / ws_weight,
        "naive_activation": naive_activation,
        "broadcast_activation": broadcast_activation,
        "activation_reuse": naive_activation / broadcast_activation,
        "naive_total": naive_total,
        "optimized_total": optimized_total,
        "total_reduction": naive_total / optimized_total,
    }


def board_demo() -> tuple[list[int], list[int]]:
    # CH0 weights = 1, CH1 weights = 2.
    # Each sample contains 16 copies of sample+1.
    ch0 = [16 * (s + 1) for s in range(BATCH)]
    ch1 = [32 * (s + 1) for s in range(BATCH)]
    return ch0, ch1


def main() -> None:
    ch0, ch1 = reference_results()
    t = traffic()
    demo0, demo1 = board_demo()

    print("sample,ch0_raw,ch1_raw")
    for sample in range(BATCH):
        print(f"{sample},{ch0[sample]},{ch1[sample]}")

    print()
    print(f"BATCH={BATCH}, OUT_CH={OUT_CH}, K={K}, TILE_K={TILE_K}")
    print(f"K tiles = {K // TILE_K}")
    print(f"total MACs = {BATCH * OUT_CH * K}")
    print(f"weight scalar traffic naive = {t['naive_weight']:.0f}")
    print(f"weight scalar traffic stationary = {t['ws_weight']:.0f}")
    print(f"weight reuse factor = {t['weight_reuse']:.1f}x")
    print(f"activation scalar traffic naive = {t['naive_activation']:.0f}")
    print(
        "activation scalar traffic with broadcast = "
        f"{t['broadcast_activation']:.0f}"
    )
    print(f"activation reuse factor = {t['activation_reuse']:.1f}x")
    print(f"input scalar traffic naive = {t['naive_total']:.0f}")
    print(f"input scalar traffic optimized = {t['optimized_total']:.0f}")
    print(f"input traffic reduction = {t['total_reduction']:.3f}x")

    print()
    print(f"board demo CH0 = {demo0}")
    print(f"board demo CH1 = {demo1}")
    print("board demo selected LED result = CH1 sample3 = 128 = 0x0080")

    assert t["weight_reuse"] == 4.0
    assert t["activation_reuse"] == 2.0
    assert t["naive_total"] == 256
    assert t["optimized_total"] == 96
    assert demo1[3] == 128

    print("SOC29 PYTHON WEIGHT-STATIONARY REFERENCE: PASS")


if __name__ == "__main__":
    main()
