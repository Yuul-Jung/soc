# SoC 26 · Vector Dot Product Controller

## 1. 목적

SoC 25의 4-Lane PE를 실제 명령 기반 Vector 연산기로 확장합니다.

핵심 흐름:

`start → vector_length → group count → tail mask → FEED → pipeline DRAIN → FINALIZE → result_valid/done`

## 2. Interface

Command:
- `start_i`
- `vector_length_i[15:0]`

Input Stream:
- `vec_valid_i`
- `vec_ready_o`
- `a_vec_i[31:0]`
- `b_vec_i[31:0]`

Status / Result:
- `busy_o`
- `done_o`
- `result_valid_o`
- `result_o[31:0]`

## 3. Group Count

PE4는 Clock당 4 Scalar Element를 처리합니다.

`groups = ceil(vector_length / 4)`

정수 Hardware 표현:

`groups = (vector_length + 3) >> 2`

16-bit 최대 Length 65535도 안전하도록 `vector_length + 3`은 17-bit 중간값으로 계산합니다.

## 4. Tail Lane

`vector_length mod 4`:

- 1 → lane0만 사용
- 2 → lane0~1 사용
- 3 → lane0~2 사용
- 0 → 네 Lane 전부 사용

마지막 Group에서 사용하지 않는 Lane은 A/B 모두 0으로 Mask합니다.

## 5. FSM

- IDLE
- CLEAR
- FEED
- DRAIN
- FINALIZE

`CLEAR`를 별도 상태로 둔 이유:
PE Pipeline/Accumulator가 완전히 Clear된 다음 첫 Vector Group을 받기 위해서입니다.

`DRAIN`을 별도 상태로 둔 이유:
마지막 Input Group을 받은 뒤에도 PE Pipeline 내부에 아직 처리 중인 Group이 있기 때문입니다.

## 6. Latency 독립 Controller

Controller는 “PE latency = 4 clocks” 같은 숫자를 사용하지 않습니다.

- accepted count → `vec_valid_i && vec_ready_o`
- completed count → `pe_valid_o`

따라서 Pipeline Stage를 변경하더라도 Completion Protocol을 유지하기 쉽습니다.

## 7. Zero Length

`vector_length = 0` 정책:

- result = 0
- busy = 0
- done = one-cycle pulse
- result_valid = one-cycle pulse

## 8. Demo

Basys3 Board Demo:

- vector length = 10
- raw A = 1,2,...,10
- raw B = 1
- groups = 3
- tail lanes = 2
- expected raw result = 55
- LED[15:0] = `0x0037`

Final Group의 unused lane에는 non-zero garbage를 넣어 Tail Mask가 실제 필요하도록 만들었습니다.

## 9. Verification

Lengths:

`0, 1, 2, 3, 4, 5, 10, 16, 17, 31`

Testbench:
- all tail sizes
- multi-group vectors
- intentional garbage in unused tail lanes
- source-valid gaps
- accepted/completed group counters
- one-cycle result_valid
- busy/done behavior
- independent mathematical reference

## 10. 다음 단계

SoC 27:
- local vector buffer
- weight/activation BRAM
- address generator
- controller fetch
- compute/data movement separation
