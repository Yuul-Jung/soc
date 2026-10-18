# SoC 27 · Local BRAM / Address Generator / Data Feeding

## 1. 목표

SoC 26의 외부 Vector Stream을 Local Memory 기반 Feeding으로 바꿉니다.

구조:

`Activation BRAM + Weight BRAM → Address Generator → SoC26 Controller/PE4 → Result`

## 2. Local Buffer

각 Buffer:

- depth: 256 words
- width: 32 bit
- one word: 4 × signed int8
- capacity: 1024 scalar elements

RTL:

```verilog
(* ram_style = "block" *)
reg [31:0] mem [0:255];
```

실제 RAMB18/RAMB36 Mapping은 `report_ram_utilization`로 확인합니다.

## 3. Simple-Dual-Port

Write:
- Host/Loader가 Local Buffer 채움

Read:
- Compute Address Generator가 Vector Word 읽음

같은 Clock을 사용합니다.

## 4. Synchronous Read

Block RAM Read는 동기식입니다.

Address/Enable을 Clock에 넣은 뒤 Registered Data/Valid가 다음 단계에서 나옵니다.

따라서 Address Generator는 Data가 같은 Cycle에 즉시 나온다고 가정하면 안 됩니다.

## 5. Address Generator

Group address:

`0, 1, 2, ... ceil(vector_length/4)-1`

SoC 26 Controller가 FEED 상태에서 READY를 유지하므로
BRAM feeder는 FEED 구간에서 매 Clock 한 Group을 요청할 수 있습니다.

## 6. Capacity Guard

ADDR_WIDTH=8:

- 256 words
- 4 lanes / word
- maximum = 1024 scalar elements

Length 1025 이상은 `range_error_o`로 거부합니다.

## 7. Bandwidth

100 MHz, PE4 기준:

- Activation = 32 bit/cycle
- Weight = 32 bit/cycle
- total local payload = 64 bit/cycle

따라서 이론 Interface Payload:

- 6.4 Gbit/s
- 800 MB/s

이는 Local Bus 산술값이지 실제 외부 Memory 측정값이 아닙니다.

## 8. 검증

Self-checking lengths:

`0,1,2,3,4,5,10,16,17,31,64`

추가:

- unused Tail Lane에 garbage 저장
- BRAM write/read 경유
- requested/delivered/accepted/completed count 비교
- length 1025 range error

## 9. Vivado

Generic BRAM inference:

```bash
vivado -mode batch   -source scripts/run_soc27_memory_inference.tcl
```

Board implementation:

```bash
vivado -mode batch   -source scripts/run_soc27_board_analysis.tcl
```

## 10. 다음 단계

SoC 28:

- BRAM output pipeline
- prefetch/FIFO
- stall-safe streaming
- double buffering
- compute/memory overlap
