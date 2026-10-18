# SoC 38 · Baseline vs Optimized Comparison Record

## 1. 동일 조건

두 설계를 비교할 때 다음을 동일하게 유지합니다.

- Device: xc7a35tcpg236-1
- Target Clock: 100 MHz
- Vivado Version:
- Constraint:
- Synthesis/Implementation Strategy:
- Power Activity Source:
- Ambient / Voltage:
- Test Vector:
- Software/Descriptor:
- Input Tensor:

## 2. Static RTL Schedule

| Metric | Baseline | Optimized | Difference |
|---|---:|---:|---:|
| BRAM Read Phase | 16 cycles | 9 cycles | -7 cycles |
| Requant Phase | 14 cycles | 14 cycles | 0 |
| Finish / IRQ | 5 cycles | 5 cycles | 0 |
| Total | 35 cycles | 28 cycles | -7 cycles |
| @100 MHz | 350 ns | 280 ns | -70 ns |
| Static Latency | 기준 |  | -20.0% |
| Upper jobs/s | 2.857 M | 3.571 M | +25.0% |

위 값은 Frozen RTL 구조에서 계산한 예상값이며 실제 Vivado/보드 측정값이 아닙니다.

## 3. Functional Regression

| Check | Baseline | Optimized |
|---|---|---|
| JOB0 OUT0 | 0x20181008 | 0x20181008 |
| JOB0 OUT1 | 0x7F7F6333 | 0x7F7F6333 |
| JOB1 OUT0 | 0x04030201 | 0x04030201 |
| JOB1 OUT1 | 0x1B150F09 | 0x1B150F09 |
| JOB_ID | 1 → 2 | 1 → 2 |
| Read Count | 8 | 8 |
| Write Count | 2 | 2 |
| DONE IRQ/W1C | PASS intent | PASS intent |
| ERROR IRQ | PASS intent | PASS intent |

## 4. Vivado Post-Route

| Metric | Baseline | Optimized | Delta |
|---|---:|---:|---:|
| WNS |  |  |  |
| TNS |  |  |  |
| WHS |  |  |  |
| THS |  |  |  |
| LUT |  |  |  |
| FF |  |  |  |
| DSP48E1 |  |  |  |
| BRAM |  |  |  |
| Vectorless Power |  |  |  |

## 5. Basys3 Runtime

| Metric | Baseline | Optimized | Delta |
|---|---:|---:|---:|
| START → ISR avg |  |  |  |
| Full E2E avg |  |  |  |
| min |  |  |  |
| max |  |  |  |

## 6. BRAM Read Latency 조건

현재 Optimized RTL의 기본값:

`BRAM_READ_LATENCY = 1`

실제 Block Memory Generator에서 추가 Output Pipeline을 켜 Read Latency가 달라지면
Parameter와 Cycle 기대값을 함께 변경해야 합니다.

AMD는 Block RAM Output Register가 Timing Closure에 유리하다고 권장하므로,
최적화 목적은 Register 제거가 아니라 연속 Read Request로 Latency를 숨기는 것입니다.

## 7. 최종 판단

실제 Report가 채워진 뒤 판단:

- Function:
- Timing:
- Resource:
- Power:
- Runtime:
- Optimization accepted:
