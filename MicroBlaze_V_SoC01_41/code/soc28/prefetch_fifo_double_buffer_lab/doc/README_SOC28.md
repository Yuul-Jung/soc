# SoC 28 · Prefetch / FIFO / Double Buffer / Stall-safe Feeding

## 1. 목적

SoC 27의 제한:

`Consumer가 FEED 동안 READY를 계속 유지`

를 제거합니다.

SoC 28 구조:

`Ping-Pong BRAM → Prefetch Credit → 64-bit FIFO → READY/VALID → SoC26 Controller/PE4`

## 2. Prefetch

BRAM Read를 Consumer가 필요해진 뒤 시작하지 않고,
FIFO 공간이 있으면 미리 요청합니다.

장점:

- BRAM Read Latency 숨김
- 짧은 Consumer Stall 흡수
- Compute Datapath와 Memory Request 분리

## 3. Credit

FIFO Depth = 4.

새 Read 요청 조건:

`fifo_count + outstanding_reads < 4`

여기서:

- `fifo_count`: 이미 도착해 FIFO에 있는 Item
- `outstanding_reads`: 요청했지만 아직 BRAM Response가 안 온 Item

Outstanding을 빼먹으면 FIFO Full 상태에서 이미 날아간 Response가 도착해 Overflow할 수 있습니다.

## 4. FIFO

- width: 64 bit
- depth: 4
- payload: `{weight[31:0], activation[31:0]}`
- push: paired BRAM response
- pop: `VALID && READY`

Tiny FIFO는 Local BRAM과 분리하여 Elastic Buffer 역할을 합니다.

## 5. Backpressure

Consumer가 READY를 내리면:

- FIFO Data는 유지
- pop 중단
- FIFO가 차면 Prefetch Read Issue 중단
- READY 복귀 후 FIFO부터 다시 소비

## 6. Double Buffer

Bank 0과 Bank 1 각각:

- Activation BRAM
- Weight BRAM

동작:

1. Bank 0 Load
2. Bank 0 Compute + Bank 1 Load
3. Bank Swap
4. Bank 1 Compute + Bank 0 Load 가능

Compute 중인 Bank에 Write를 시도하면 Write를 차단하고 `bank_conflict_o`를 발생합니다.

## 7. Board Demo

Bank 0:
- A = 1..10
- B = 1
- result = 55 = `0x0037`

Bank 0을 Compute하는 동안 Bank 1 Load:

Bank 1:
- A = 2,4,...,20
- B = 1
- result = 110 = `0x006E`

최종 LED는 두 번째 결과 `0x006E`.

## 8. Verification

Testbench:

- Bank 0 length 64
- deterministic backpressure
- compute bank0 while loading bank1
- same-bank invalid write → conflict check
- FIFO occupancy > 1 확인
- no response mismatch
- no FIFO overflow
- Bank 1 length 31 compute
- range error length 1025

Python model:

- FIFO credit algorithm
- one-cycle response model
- stall pattern
- FIFO max occupancy
- requested=received=delivered

## 9. Vivado

Generic OOC:

```bash
vivado -mode batch   -source scripts/run_soc28_generic_ooc.tcl
```

Board implementation:

```bash
vivado -mode batch   -source scripts/run_soc28_board_analysis.tcl
```

Simulation:

```bash
vivado -mode batch   -source scripts/prepare_soc28_simulation.tcl
```

## 10. 다음 단계

SoC 29:

- Data Reuse
- Weight Stationary
- Activation Broadcast
- Tiling
- PE Array memory traffic reduction
