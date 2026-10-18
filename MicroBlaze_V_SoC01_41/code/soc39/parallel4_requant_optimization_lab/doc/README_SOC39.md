# SoC 39 · 4-Lane Parallel Requantization Optimization

## 1. 목표

SoC 38에서 BRAM Read를 16 → 9 cycles로 줄였습니다.

SoC 39에서는 남은 가장 큰 정적 구간인 Requant 14 cycles를 대상으로
Serial Feed를 4-lane 병렬 구조로 바꿉니다.

Baseline:

`1 requant core × 8 serial feed clocks`

Optimized:

`4 requant cores × 2 group feed clocks`

정적 Requant Phase:

`14 cycles → 8 cycles`

전체 Static Job:

`28 cycles → 22 cycles`

## 2. 왜 4-lane인가

8개 Core를 동시에 복제할 수도 있지만 Resource 증가가 큽니다.

이번 구조는 기존 2-channel × 4-sample Batch에 맞춰:

- CH0 sample 0~3 → 4-lane 동시 입력
- CH1 sample 0~3 → 다음 Clock 4-lane 동시 입력

으로 구성합니다.

Feed:

`8 clocks → 2 clocks`

Core Pipeline은 그대로 4-stage입니다.

## 3. 유지하는 것

- `requantize_s32_to_s8.v` 산술식
- Rounding
- Zero Point
- Saturation
- BRAM Read Pipeline
- Descriptor
- AXI4-Lite
- IRQ
- Register Map
- Job0/Job1 Expected Result

## 4. 변경하는 것

- `requantize_batch2x4_serial.v`
- → `requantize_batch2x4_parallel4.v`

그리고 Job Engine에서 Batch Requantizer Instance만 교체합니다.

## 5. 4-lane 구조

```text
             CH0 또는 CH1 4개 Sample
                       │
        ┌──────────────┼──────────────┐
        │              │              │
      Lane0          Lane1          Lane2          Lane3
        │              │              │              │
  requant core    requant core    requant core    requant core
        │              │              │              │
        └──────────────┼──────────────┘
                       │
                    Pack 32-bit
```

## 6. Static Schedule

SoC 38:

- Read 9
- Requant 14
- Finish/IRQ 5
- Total 28

SoC 39:

- Read 9
- Requant 8
- Finish/IRQ 5
- Total 22

100 MHz:

- SoC38: 280 ns
- SoC39: 220 ns

정적 Latency:

`-21.4%`

정적 Upper Throughput:

`+27.3%`

실측값이 아닙니다.

## 7. Resource Trade-off

Source structure:

- SoC38: requant core 1개
- SoC39: requant core 4개

하지만 실제 DSP48 개수는 소스 Instance 수와 동일하다고 가정하지 않습니다.

`requantize_s32_to_s8`의 Multiply는 33×16 signed입니다.

7-Series DSP48E1 단일 Multiplier 입력 폭은 25×18이므로
실제 33×16 곱셈은 한 개 DSP48E1에 완전히 들어가지 않을 수 있습니다.

따라서 실제 DSP/LUT Mapping은 반드시 Vivado Synthesis Report로 확인합니다.

## 8. Pipelining

AMD UG949는 DSP48에 매핑되는 산술을 충분히 Pipeline하도록 권장합니다.

현재 `requantize_s32_to_s8`는:

1. Bias
2. Multiply
3. Round / Shift
4. Zero Point / Saturation

4-stage Pipeline을 유지합니다.

이번 최적화는 Pipeline 깊이를 줄이는 것이 아니라
동일 Pipeline을 4-lane으로 복제해 Spatial Parallelism을 높입니다.

## 9. Functional Regression

반드시 유지:

- JOB0 OUT0 = 0x20181008
- JOB0 OUT1 = 0x7F7F6333
- JOB1 OUT0 = 0x04030201
- JOB1 OUT1 = 0x1B150F09
- JOB_ID 1 → 2
- Read Count 8
- Write Count 2
- DONE IRQ/W1C
- ERROR IRQ

## 10. Standalone Batch Regression

`tb_requantize_batch2x4_parallel4.sv`

확인:

- CH0 Packed Result
- CH1 Packed Result
- Saturation Count = 2

## 11. Integrated Regression

`tb_soc39_parallel4_regression.sv`

Expected internal schedule:

`engine START acceptance → IRQ pending = 22 cycles`

Job0/Job1 모두 같은 값을 기대합니다.

## 12. Vivado Compare

동일 조건:

- xc7a35tcpg236-1
- 100 MHz
- same Vivado version
- same flow
- same power activity assumptions

비교:

- WNS/TNS/WHS/THS
- LUT/FF
- DSP48E1
- BRAM
- Power
- Design Analysis

## 13. 다음 단계

SoC 40에서는:

`Read 9 cycles + Requant 8 cycles`

를 순차적으로 수행하는 현재 구조에서
Read와 Compute를 일부 Overlap할 수 있는지 검토합니다.

후보:

- Prefetch
- Double Buffer
- Streaming Data/Compute Overlap
