# SoC 31 · NPU Register Map / MicroBlaze V Control / Accelerator Integration

## 1. 목표

SoC 30까지 만든 NPU Output Datapath를 MicroBlaze V가 Memory-Mapped Peripheral처럼 제어합니다.

구조:

`MicroBlaze V → SmartConnect → AXI4-Lite → NPU Register Bank → SoC30 Accelerator`

## 2. Register Map

| Offset | Name | Type | 역할 |
|---:|---|---|---|
| 0x00 | CONTROL | W1P | START/CLEAR_DONE/CLEAR_ERROR |
| 0x04 | STATUS | RO | BUSY/DONE/ERROR/SATURATED |
| 0x08 | VERSION | RO | 0x00010000 |
| 0x0C | SAT_COUNT | RO | saturation count |
| 0x10 | BIAS_CH0 | RW | signed int32 |
| 0x14 | BIAS_CH1 | RW | signed int32 |
| 0x18 | SCALE_CH0 | RW | multiplier + shift |
| 0x1C | SCALE_CH1 | RW | multiplier + shift |
| 0x20 | ZERO_POINT | RW | CH0/CH1 packed |
| 0x40~0x5C | ACC_IN0..7 | RW | int32 input buffer |
| 0x60 | OUT_CH0 | RO | packed int8 ×4 |
| 0x64 | OUT_CH1 | RO | packed int8 ×4 |
| 0x68 | CYCLE_COUNT | RO | operation cycle counter |

## 3. CONTROL

- bit0 START: Write One Pulse
- bit1 CLEAR_DONE: Write One Pulse
- bit2 CLEAR_ERROR: Write One Pulse

START while BUSY:

- command rejected
- ERROR_STICKY set

## 4. STATUS

- bit0 BUSY
- bit1 DONE_STICKY
- bit2 ERROR_STICKY
- bit3 SATURATED_ANY

DONE/ERROR는 Software가 읽기 전에 사라지지 않도록 Sticky로 유지합니다.

## 5. AXI4-Lite Write

AW와 W는 독립 채널입니다.

따라서:

- AW 먼저
- W 먼저
- 동시에

모두 처리합니다.

주소와 Data를 각각 Pending Register에 저장한 뒤 둘 다 확보되면 Register Write를 Commit합니다.

## 6. WSTRB

`WSTRB[n]`은 `WDATA[n*8 +: 8]` Byte Lane의 유효 여부입니다.

Register Bank의 RW Register는 Partial Byte Write를 지원합니다.

## 7. MicroBlaze V Driver

`npu_accel.h`는:

- `Xil_Out32`
- `Xil_In32`

기반의 최소 Driver입니다.

Base Address는 Vivado Address Editor에서 할당하고 생성된 `xparameters.h` Symbol을 사용합니다.

## 8. Demo

SoC29 int32:

- CH0 = [16,32,48,64]
- CH1 = [32,64,96,128]

SoC30 Parameters 적용 후:

- OUT_CH0 = `0x20181008`
- OUT_CH1 = `0x7F7F6333`
- SAT_COUNT = `2`

## 9. 검증

AXI Testbench:

- AW/W simultaneous
- AW first
- W first
- WSTRB partial write
- VERSION read
- configuration readback
- START/BUSY/DONE
- START while BUSY error
- result read
- sticky clear

## 10. 다음 단계

SoC 32:

- NPU interrupt
- AXI Interrupt Controller
- interrupt-driven completion
