# SoC 41 · Group 8 Cumulative Sign-off Matrix

## 1. 정적 성능 진행

| 단계 | 핵심 변경 | Static Cycle | @100 MHz | 단계 Latency 개선 | Baseline 대비 Latency | Baseline 대비 Upper Throughput |
|---|---|---:|---:|---:|---:|---:|
| SoC 37 | Baseline | 35 | 350 ns | - | - | - |
| SoC 38 | BRAM Read Pipeline | 28 | 280 ns | -20.0% | -20.0% | +25.0% |
| SoC 39 | Parallel4 Requant | 22 | 220 ns | -21.4% | -37.1% | +59.1% |
| SoC 40 | Data/Compute Overlap | 16 | 160 ns | -27.3% | -54.3% | +118.8% |

위 표는 RTL Static Schedule입니다.

Vivado Post-Route 또는 Basys3 Runtime 측정값이 아닙니다.

## 2. Functional Sign-off

| Check | Actual |
|---|---|
| RTL self-check regression |  |
| JOB0 expected outputs |  |
| JOB1 expected outputs |  |
| JOB_ID 1 → 2 |  |
| DONE IRQ / W1C |  |
| Descriptor ERROR IRQ |  |
| Read Count 8 |  |
| Write Count 2 |  |

## 3. Timing Sign-off

AMD UG906 기준 Post-Route Timing Sign-off를 수행합니다.

| Metric | Actual | 기본 판정 |
|---|---:|---|
| WNS |  | >= 0 ns |
| TNS |  | 0 ns |
| WHS |  | >= 0 ns |
| THS |  | 0 ns |
| Unconstrained Paths |  | 0 |
| Pulse Width Violations |  | 0 |
| Timing Critical Warnings |  | 0 |

`report_timing_summary` 외에 `check_timing` 결과도 확인합니다.

Bus-skew constraint를 사용하는 설계라면 `report_bus_skew`도 별도 확인합니다.

## 4. Methodology / DRC / CDC

| Metric | Actual |
|---|---:|
| Methodology Critical Warnings |  |
| DRC Errors |  |
| CDC Critical |  |

CDC가 없는 Single Clock 설계라도 Report 결과 또는 해당 없음의 근거를 기록합니다.

## 5. Resource

| Resource | Used | Available | Utilization |
|---|---:|---:|---:|
| LUT |  |  |  |
| FF |  |  |  |
| BRAM |  |  |  |
| DSP48E1 |  |  |  |

Source-level Core 개수로 실제 DSP/LUT 사용량을 추정하지 않습니다.

## 6. Power / Thermal

| Metric | Actual |
|---|---:|
| Activity Source |  |
| Total On-Chip Power |  |
| Dynamic Power |  |
| Device Static Power |  |
| Junction Temperature |  |
| Ambient |  |
| Airflow |  |
| User Power Budget |  |
| User Junction Limit |  |

Power PASS/FAIL 기준은 설계 요구사항의 Budget을 사용합니다.

임의의 Budget을 강의자료에서 만들지 않습니다.

## 7. Runtime

| Metric | Actual |
|---|---:|
| Measurement Method |  |
| Repeats |  |
| START → ISR average |  |
| Full E2E average |  |
| Full E2E minimum |  |
| Full E2E maximum |  |

UART 출력은 측정구간에서 제외합니다.

## 8. Final Gate

| Gate | Status |
|---|---|
| Functional | INCOMPLETE |
| Timing | INCOMPLETE |
| Methodology / DRC / CDC | INCOMPLETE |
| Resource | INCOMPLETE |
| Power / Thermal | INCOMPLETE |
| Runtime | INCOMPLETE |
| Overall | INCOMPLETE |

실제 값을 입력하기 전에는 PASS로 표시하지 않습니다.
