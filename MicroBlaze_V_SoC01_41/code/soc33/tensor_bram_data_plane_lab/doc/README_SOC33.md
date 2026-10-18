# SoC 33 · AXI BRAM Tensor Buffer / Control Plane & Data Plane

## 1. 목표

SoC 31~32의 Register 중심 제어 구조에서 실제 Tensor Memory 구조로 확장합니다.

Control Plane:

`MicroBlaze V → AXI4-Lite → Register / IRQ`

Data Plane:

`MicroBlaze V → AXI BRAM Controller → True Dual-Port BRAM ← NPU`

## 2. 왜 Register 입력을 버리는가

`ACC_IN0..7` Register는 Register Map 학습에는 적합하지만 Tensor 크기가 커질수록 확장성이 없습니다.

Tensor는 Memory에 두고, Control Register에는 주소/길이/명령만 두는 방향으로 이동합니다.

## 3. SoC 33 Memory Map

4 KB Tensor BRAM, 32-bit word.

Input:

- 0x000 CH0 sample0
- 0x004 CH0 sample1
- 0x008 CH0 sample2
- 0x00C CH0 sample3
- 0x010 CH1 sample0
- 0x014 CH1 sample1
- 0x018 CH1 sample2
- 0x01C CH1 sample3

Output:

- 0x100 OUT_CH0 packed int8 x4
- 0x104 OUT_CH1 packed int8 x4

SoC 34에서는 이 고정 주소를 Descriptor Register로 바꿉니다.

## 4. True Dual-Port

Port A:

- MicroBlaze V
- AXI BRAM Controller
- Software Tensor Read/Write

Port B:

- NPU Native BRAM Interface
- Tensor Read
- Output Write

## 5. Ownership Rule

같은 Buffer를 CPU와 NPU가 동시에 수정하지 않습니다.

Software 흐름:

1. CPU가 Input Tensor Write
2. CPU가 Buffer ownership을 NPU에 넘김
3. NPU BUSY
4. CPU는 해당 Buffer 접근 금지
5. NPU DONE
6. CPU가 Buffer ownership 회수
7. Output Tensor Read

이 규칙은 같은 주소를 두 Port에서 동시에 접근하는 충돌을 피합니다.

## 6. Read Latency

BRAM은 synchronous read입니다.

Engine:

`READ_REQ → READ_CAPTURE`

두 상태로 1-cycle read latency를 명확히 처리합니다.

## 7. NPU Data Plane

Engine은:

- 8개 int32 Input Word Read
- SoC30 Requantizer 실행
- CH0/CH1 Packed int8 결과 생성
- 0x100/0x104에 결과 Write

합니다.

## 8. 검증 기준

- CPU-side Port A input write/readback
- NPU Port B read 8 words
- NPU Port B write 2 words
- CPU idle during NPU ownership
- OUT_CH0 = 0x20181008
- OUT_CH1 = 0x7F7F6333
- input data preservation

## 9. 실제 Vivado Block Design

Simulation/OOC에서는 `tensor_bram_tdp_4k_model.v`를 사용합니다.

실제 Block Design에서는:

- AXI BRAM Controller
- Block Memory Generator
- True Dual-Port RAM

으로 교체합니다.

Port A는 AXI BRAM Controller에 연결하고 Port B는 NPU Native Port에 연결합니다.

## 10. 다음 단계

SoC 34:

- INPUT_BASE
- OUTPUT_BASE
- LENGTH
- command / descriptor
- programmable tensor job
