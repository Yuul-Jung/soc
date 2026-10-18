# SoC 35 · Full NPU Accelerator Integration

## 1. 목표

SoC 32~34에서 분리한 기능을 하나의 Accelerator IP로 통합합니다.

- SoC 32: IRQ / ISR
- SoC 33: Tensor BRAM Data Plane
- SoC 34: Job Descriptor / Validation

최종 NPU IP Interface:

- `S_AXI` : Control Plane
- `BRAM` : Data Plane
- `irq` : Completion/Error Notification

## 2. 전체 구조

`MicroBlaze V → SmartConnect → NPU S_AXI`

`MicroBlaze V → AXI BRAM Controller → Tensor BRAM Port A`

`NPU BRAM Port → Tensor BRAM Port B`

`NPU irq → xlconcat → AXI Interrupt Controller → MicroBlaze V`

## 3. Register Map

SoC 34 Register Map 유지:

- 0x00 CONTROL
- 0x04 STATUS
- 0x08 VERSION
- 0x0C JOB_ID
- 0x10 INPUT_BASE
- 0x14 OUTPUT_BASE
- 0x18 LENGTH_WORDS
- 0x1C ERROR_CODE
- 0x20~0x30 PARAMETERS
- 0x34~0x3C ACTIVE SNAPSHOT
- 0x40 READ_WORD_COUNT
- 0x44 WRITE_WORD_COUNT

SoC 35 추가:

- 0x48 IRQ_ENABLE
- 0x4C IRQ_STATUS W1C

## 4. Job Sequence

1. CPU가 Tensor BRAM Input 작성
2. CPU가 Descriptor 작성
3. Descriptor Valid 확인
4. IRQ pending clear
5. IRQ enable
6. START
7. Descriptor Active Snapshot
8. NPU Port B에서 Input 읽기
9. Requantization 실행
10. Output BRAM write
11. DONE pending
12. level IRQ
13. MicroBlaze V ISR
14. ISR W1C
15. CPU가 Output BRAM read

## 5. Buffer Ownership

CPU와 NPU가 같은 Buffer를 동시에 수정하지 않습니다.

`CPU_FILL → NPU_OWNS → DONE → CPU_READ`

## 6. 통합 Regression

Self-checking test:

- AXI AW/W 3가지 순서
- descriptor validation
- active snapshot
- shadow update during BUSY
- Tensor BRAM input/output
- DONE IRQ
- W1C deassert
- descriptor ERROR IRQ
- rejected job JOB_ID 유지

## 7. 실제 Vivado

실제 Block Design에서는 `tensor_bram_tdp_4k_model.v`를 사용하지 않습니다.

대신:

- AXI BRAM Controller
- Block Memory Generator True Dual-Port
- NPU BRAM Interface

를 연결합니다.

AXI BRAM Controller는 CPU-side Port A만 사용하고 NPU는 BMG의 다른 Native Port를 사용하도록 구성합니다.

## 8. 다음 단계

SoC 36:

- MicroBlaze V Software
- Tensor input
- Job launch
- Interrupt
- Output verify

를 실제 End-to-End Software Flow로 정리합니다.
