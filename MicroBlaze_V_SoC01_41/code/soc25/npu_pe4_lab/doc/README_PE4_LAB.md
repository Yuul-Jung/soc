# SoC 25 · PE / Parallel MAC / Vector Dot Product

## 1. 목적

SoC 24의 MAC 1개를 4개 병렬 Lane으로 확장하여 NPU Processing Element의 기본 구조를 만듭니다.

핵심 구조:

`4 × signed 8x8 multiply → balanced adder tree → 18-bit dot4 → 32-bit accumulator`

## 2. Fixed-Point

SoC 24 규칙을 그대로 유지합니다.

- signed input width: 8 bit
- input fractional bits: 7
- product width: 16 bit
- product fractional bits: 14
- accumulator fractional bits: 14

4개의 Product를 더해도 Binary Point는 이동하지 않습니다.
Bit Width만 확장합니다.

## 3. Width Growth

각 Product:
- signed 16 bit

Pair Sum:
- signed 17 bit

4-way Dot Product:
- signed 18 bit

이유:

`(-128 × -128) × 4 = 65536`

signed 17-bit의 최대값은 65535이므로 18 bit가 필요합니다.

## 4. Balanced Adder Tree

Serial:

`(((p0 + p1) + p2) + p3)`

Add depth = 3

Balanced:

`(p0 + p1) + (p2 + p3)`

Add depth = 2

NPU처럼 Lane 수가 커질수록 Tree Reduction과 Pipeline이 중요해집니다.

## 5. Pipelined PE4

Stage 1:
- Product ×4

Stage 2:
- Pair Sum ×2

Stage 3:
- Dot4 Sum

Stage 4:
- Accumulator

Valid도 `valid_s1_q → valid_s2_q → valid_s3_q → valid_o`로 동일하게 이동합니다.

## 6. Throughput

100 MHz, 4 Lane 기준 이론값:

- 400,000,000 products/s
- Multiply와 Add를 각각 1 Operation으로 세면 0.8 GOPS

주의:
- GOPS 계산 관습은 구현/문헌에 따라 다릅니다.
- 이는 Clock와 Lane 수로 계산한 이론 Arithmetic Rate입니다.
- 실제 NPU 성능은 Memory Bandwidth, Stall, Control, Utilization에 의해 낮아질 수 있습니다.

## 7. DSP Budget

XC7A35T:
- DSP48E1 = 90

Multiplier 1 Lane이 DSP 1개를 사용한다고 가정한 산술상 값:

- 4-Lane PE = DSP 4개
- 90 // 4 = PE4 22개
- 88 DSP 사용, 2 DSP 잔여

이 값은 실제 구현 한계가 아닙니다.
Vivado 실제 DSP Mapping, Routing, BRAM, LUT, Timing, Power를 함께 확인해야 합니다.

## 8. Vivado

```bash
cd npu_pe4_lab
chmod +x scripts/run_all_pe4_cases.sh
./scripts/run_all_pe4_cases.sh
```

핵심 Report:

- `01_utilization_post_synth.rpt`
- `02_dsp48_cells_post_synth.rpt`
- `05_timing_summary_post_route.rpt`
- `07_design_analysis_post_route.rpt`
- `08_power_normalized_activity.rpt`

## 9. 다음 단계

SoC 26에서는 Vector Length가 4보다 큰 경우를 처리하는 Controller를 추가합니다.

예:

- vector length = 16
- 4 lanes / cycle
- 4 cycles accumulation
- start / busy / done
- tail handling
- result_valid
