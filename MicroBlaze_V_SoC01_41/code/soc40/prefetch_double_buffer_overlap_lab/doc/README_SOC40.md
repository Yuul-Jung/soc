# SoC 40 · Prefetch / Ping-Pong Buffer / Data-Compute Overlap

## 1. 목표

SoC 39:

`Read 9 → Requant 8 → Finish/IRQ 5`

를 순차적으로 수행했습니다.

SoC 40에서는 CH0 4 Word를 먼저 확보한 순간 계산을 시작하고,
동시에 CH1 4 Word를 계속 Prefetch합니다.

핵심:

`Read 전체 완료 후 Compute`

에서

`Read Group0 완료 → Compute Group0 + Prefetch Group1`

로 바꿉니다.

## 2. Ping / Pong Group Buffer

- Ping Buffer → CH0 Word 0~3
- Pong Buffer → CH1 Word 4~7

두 Buffer는 128-bit Register Group입니다.

이번 단계는 작은 교육용 Double Buffer입니다.
대용량 Tensor 전체를 두 개의 BRAM Bank로 복제하는 구조는 아닙니다.

## 3. Static Schedule

기준:

`Engine START acceptance / busy rising → IRQ pending`

예상:

- E1~E8: Read address issue
- E2~E9: Read data capture
- E6: Ping/CH0 Compute launch
- E10: CH0 result write + Pong/CH1 Compute launch
- E14: CH1 result write
- E15: Engine done
- E16: IRQ pending

따라서:

- SoC39 → 22 cycles
- SoC40 → 16 cycles

100 MHz:

- SoC39 → 220 ns
- SoC40 → 160 ns

Static latency reduction:

`27.3%`

Static upper-throughput improvement:

`37.5%`

실측값이 아닙니다.

## 4. 핵심 구조

```text
BRAM Stream
   │
   ├── Word0..3 → Ping Buffer ──→ Group4 Requant
   │                               │
   └── Word4..7 → Pong Buffer ─────┘
                    ↑
           CH0 compute와 겹침
```

## 5. Group4 Requant

SoC39의 4-lane Arithmetic Core를 유지하되
Batch Controller를 없애고 하나의 4-word Group을
`valid/tag`로 직접 넣습니다.

Interface:

- valid_i
- tag_i
- acc_group_i[127:0]
- bias/mult/shift/zp
- valid_o
- tag_o
- q_group_o[31:0]

## 6. Tag

- tag 0 → CH0
- tag 1 → CH1

Tag는 Arithmetic Pipeline과 같은 깊이로 이동합니다.

## 7. Memory Port Scheduling

Input Read가 끝나기 전에는 BRAM Port를 Read에 사용합니다.

CH0 Result가 돌아오는 시점은 마지막 Read가 끝난 직후이므로
동일 Native Port에서 Output Write를 시작할 수 있습니다.

## 8. BRAM은 그대로 동기식

AMD UG949는 Block RAM Output Register를 Timing Closure 관점에서 권장합니다.

이번 최적화는:

- Asynchronous RAM 전환 아님
- Output Register 제거 아님
- Prefetch / Pipeline Scheduling 개선

입니다.

## 9. 유지하는 것

- `requantize_s32_to_s8.v`
- 4-lane arithmetic structure
- BRAM synchronous read
- AXI Control Plane
- Descriptor
- IRQ
- Job0/Job1 Expected Result
- Register Map
- 100 MHz target

## 10. Functional Regression

유지:

- JOB0 OUT0 = 0x20181008
- JOB0 OUT1 = 0x7F7F6333
- JOB1 OUT0 = 0x04030201
- JOB1 OUT1 = 0x1B150F09
- JOB_ID 1 → 2
- Read Count = 8
- Write Count = 2
- DONE/W1C
- ERROR IRQ

## 11. Resource Trade-off

추가:

- Ping 128-bit Register
- Pong 128-bit Register
- ready/launched state
- read-valid state
- group result scheduling

SoC39도 CH0/CH1 Batch Register 256-bit를 사용하므로
단순히 256-bit가 새로 추가된다고 보면 안 됩니다.

실제 LUT/FF 차이는 Vivado Report로 판단합니다.

## 12. Timing Trade-off

Overlap Control이 추가되므로:

- group-ready fanout
- tag path
- BRAM address/write select
- result write priority

경로를 Post-Route에서 확인합니다.

AMD는 BRAM/DSP 같은 Dedicated Block 주변에
충분한 Pipelining을 권장합니다.

## 13. 다음 단계

SoC 41에서는 Group 8을 마무리하면서:

- SoC37 35 cycles
- SoC38 28 cycles
- SoC39 22 cycles
- SoC40 16 cycles

의 누적 성능 개선을 하나의 Sign-off Matrix로 정리하고
Timing/Resource/Power/Runtime 측정 항목을 통합합니다.
