# SoC 40 · SoC39 Sequential vs SoC40 Overlap

## 1. 동일 조건

- Device: xc7a35tcpg236-1
- Clock: 100 MHz
- Vivado Version:
- Implementation Strategy:
- Power Activity:
- Tensor:
- Descriptor:

## 2. Static Schedule

| Metric | SoC39 | SoC40 | Delta |
|---|---:|---:|---:|
| Read | 9 | 9 | 0 |
| Requant | 8 | 4-stage per group | overlap |
| Finish/IRQ | 5 | overlapped write + finish | overlap |
| Total | 22 cycles | 16 cycles | -6 |
| @100 MHz | 220 ns | 160 ns | -60 ns |
| Static Latency | 기준 |  | -27.3% |
| Upper jobs/s | 4.545 M | 6.250 M | +37.5% |

## 3. Functional Regression

| Check | SoC39 | SoC40 |
|---|---|---|
| JOB0 OUT0 | 0x20181008 | 0x20181008 |
| JOB0 OUT1 | 0x7F7F6333 | 0x7F7F6333 |
| JOB1 OUT0 | 0x04030201 | 0x04030201 |
| JOB1 OUT1 | 0x1B150F09 | 0x1B150F09 |
| JOB_ID | 1 → 2 | 1 → 2 |
| Read Count | 8 | 8 |
| Write Count | 2 | 2 |
| DONE/W1C | 유지 | 유지 |
| ERROR IRQ | 유지 | 유지 |

## 4. Post-Route

| Metric | SoC39 | SoC40 | Delta |
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

## 5. Runtime

| Metric | SoC39 | SoC40 | Delta |
|---|---:|---:|---:|
| START → ISR avg |  |  |  |
| Full E2E avg |  |  |  |
| min |  |  |  |
| max |  |  |  |

## 6. Acceptance

- Functional:
- Timing:
- Resource:
- Power:
- Runtime:
- Accepted:
