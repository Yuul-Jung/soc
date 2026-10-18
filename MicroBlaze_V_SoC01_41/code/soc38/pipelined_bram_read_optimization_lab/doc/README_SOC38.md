# SoC 38 · Bottleneck Analysis / Pipelined BRAM Read Optimization

## 1. 목표

SoC 37 Baseline을 그대로 보존한 상태에서 첫 번째 구조 최적화를 수행합니다.

대상:

`8 Word × READ_REQ / READ_CAPTURE = 16 cycles`

개선:

`매 Clock Read Address 발행 + Read Valid Pipeline`

1-cycle synchronous BRAM read 기준:

`16 cycles → 9 cycles`

Engine START accept → IRQ pending 기준 전체 Static Job:

`35 cycles → 28 cycles`

## 2. 왜 이 구간을 먼저 선택하는가

SoC 37 정적 Cycle Schedule:

- BRAM Read: 16 cycles
- Requant: 14 cycles
- Finish / IRQ: 5 cycles

Read 구간이 가장 큰 단일 구간입니다.

다만 실제 Vivado/Post-Route/Basys3 실측이 없는 상태이므로
“실제 가장 큰 Bottleneck”이라고 확정하지 않습니다.

이번 장은 정적 구조상 가장 명확한 후보를 먼저 개선하는 실습입니다.

## 3. Baseline

```text
word0: READ_REQ → READ_CAPTURE
word1: READ_REQ → READ_CAPTURE
word2: READ_REQ → READ_CAPTURE
...
word7: READ_REQ → READ_CAPTURE
```

8 Word:

`8 × 2 → 16 cycles`

## 4. Optimized

```text
cycle 1 : issue word0
cycle 2 : issue word1
cycle 3 : issue word2 + capture word0
cycle 4 : issue word3 + capture word1
...
cycle 8 : issue word7 + capture word6
cycle 9 :               capture word7
```

따라서:

`8 words + 1-cycle pipeline drain → 9 cycles`

## 5. 핵심 원칙

BRAM을 asynchronous read로 바꾸지 않습니다.

동기식 BRAM과 Output Register를 유지하면서
Read Request를 매 Clock 연속 발행합니다.

AMD UG949는 Block RAM의 Output Register 사용을 Timing Closure 관점에서 권장하고,
Dedicated Block 주변 경로를 Pipelining하는 것을 권장합니다.

따라서 이번 최적화는:

`register 제거`

가 아니라:

`latency hiding + request pipelining`

입니다.

## 6. BRAM_READ_LATENCY

Optimized Engine:

```verilog
parameter integer BRAM_READ_LATENCY = 1
```

기본 실습:

- synchronous BRAM Port-B read latency = 1
- 8 Word read phase = 9 cycles

실제 Block Memory Generator에서 추가 Output Pipeline Register를 사용해
Read Latency를 변경하면 Parameter와 기대 Cycle을 함께 변경해야 합니다.

## 7. 유지하는 것

다음은 SoC 37과 동일합니다.

- Requantizer
- Control / Descriptor
- IRQ
- AXI4-Lite Bridge
- Register Map
- Tensor Layout
- Software Contract
- Expected Result
- 100 MHz Target

## 8. 변경하는 것

기능적 변경 대상은 Job Engine Read Scheduler 하나입니다.

Baseline:

`tensor_job_engine.v`

Optimized:

`tensor_job_engine_pipelined_read.v`

Full Accelerator Wrapper는 Engine Instance만 교체합니다.

## 9. Static Comparison

| Metric | Baseline | Optimized |
|---|---:|---:|
| Read Phase | 16 | 9 |
| Requant | 14 | 14 |
| Finish/IRQ | 5 | 5 |
| Total | 35 | 28 |
| @100 MHz | 350 ns | 280 ns |

Static Latency:

`-20.0%`

Static Upper Throughput:

`+25.0%`

실측값이 아닙니다.

## 10. Functional Regression

Optimized Design은 기존 기능을 그대로 유지해야 합니다.

- JOB0 Output
- JOB1 Output
- JOB_ID
- Read/Write Counter
- DONE IRQ/W1C
- ERROR IRQ
- Descriptor Validation

## 11. Vivado 비교

동일 조건으로 Baseline/Optimized를 각각 구현합니다.

```text
same device
same 100 MHz clock
same Vivado version
same implementation flow
same power activity assumption
```

비교:

- WNS/TNS
- WHS/THS
- LUT/FF
- DSP48
- BRAM
- Power
- Design Analysis

## 12. 예상 Trade-off

추가될 수 있는 것:

- issue/capture index register
- valid pipeline
- issue_done control

따라서 Cycle은 줄어도 LUT/FF가 소폭 증가할 수 있습니다.

Timing/Power 결과는 실제 Vivado Report로 판단합니다.

## 13. 다음 단계

SoC 39에서는:

- Requant Serial Feed
- Data/Compute Overlap
- Prefetch / Double Buffer

중 다음 Bottleneck을 같은 방식으로 분석합니다.
