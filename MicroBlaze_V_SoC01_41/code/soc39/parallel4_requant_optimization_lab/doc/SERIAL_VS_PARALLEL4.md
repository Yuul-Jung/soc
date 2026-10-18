# SoC 39 · SoC38 Serial vs SoC39 Parallel4 Comparison

## 1. 동일 조건

- Device: xc7a35tcpg236-1
- Target Clock: 100 MHz
- Vivado Version:
- Implementation Strategy:
- Power Activity Source:
- Ambient / Voltage:
- Input Tensor:
- Descriptor:

## 2. Static Schedule

| Metric | SoC38 Serial | SoC39 Parallel4 | Delta |
|---|---:|---:|---:|
| BRAM Read | 9 cycles | 9 cycles | 0 |
| Requant | 14 cycles | 8 cycles | -6 |
| Finish / IRQ | 5 cycles | 5 cycles | 0 |
| Total | 28 cycles | 22 cycles | -6 |
| @100 MHz | 280 ns | 220 ns | -60 ns |
| Static Latency | 기준 |  | -21.4% |
| Upper jobs/s | 3.571 M | 4.545 M | +27.3% |

## 3. Source Structure

| Metric | SoC38 | SoC39 |
|---|---:|---:|
| Requant core instances | 1 | 4 |
| Feed clocks | 8 | 2 |
| Pipeline stages/core | 4 | 4 |

## 4. Functional Regression

| Check | SoC38 | SoC39 |
|---|---|---|
| JOB0 OUT0 | 0x20181008 | 0x20181008 |
| JOB0 OUT1 | 0x7F7F6333 | 0x7F7F6333 |
| JOB1 OUT0 | 0x04030201 | 0x04030201 |
| JOB1 OUT1 | 0x1B150F09 | 0x1B150F09 |
| JOB_ID | 1 → 2 | 1 → 2 |
| Read Count | 8 | 8 |
| Write Count | 2 | 2 |
| DONE IRQ/W1C | 유지 | 유지 |
| ERROR IRQ | 유지 | 유지 |

## 5. Vivado Post-Route

| Metric | SoC38 | SoC39 | Delta |
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

## 6. Basys3 Runtime

| Metric | SoC38 | SoC39 | Delta |
|---|---:|---:|---:|
| START → ISR avg |  |  |  |
| Full E2E avg |  |  |  |
| min |  |  |  |
| max |  |  |  |

## 7. Resource 판단

Source상 requant core는 1 → 4개입니다.

하지만 실제 DSP48E1 사용량은 소스 Instance 수로 결정하지 않습니다.

33×16 signed multiply가 단일 25×18 DSP48E1에 그대로 들어가지 않으므로
Vivado 합성 결과에서 DSP/LUT Mapping을 확인합니다.

## 8. Optimization Acceptance

실제 Report 작성 후:

- Function:
- Timing:
- Resource:
- Power:
- Runtime:
- Accepted:
