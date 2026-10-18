# SoC 36 · CPU ↔ NPU End-to-End Software / Inference Flow

## 1. 목표

SoC 35에서 완성한 Full NPU Accelerator Hardware를 수정하지 않고,
MicroBlaze V Software부터 Output 검증까지 하나의 실행 흐름으로 완성합니다.

```text
CPU Tensor Fill
    ↓
Descriptor Program
    ↓
Descriptor Valid
    ↓
IRQ Arm
    ↓
START
    ↓
NPU Tensor Read
    ↓
Requantization
    ↓
Tensor Output Write
    ↓
DONE IRQ
    ↓
MicroBlaze V ISR
    ↓
W1C
    ↓
CPU Output Read
    ↓
Reference Compare
```

## 2. Hardware Freeze

SoC 36은 새로운 NPU RTL 기능을 추가하지 않습니다.

SoC 35의 다음 RTL을 그대로 재사용합니다.

- `requantize_s32_to_s8.v`
- `requantize_batch2x4_serial.v`
- `tensor_job_engine.v`
- `npu_full_control_irq.v`
- `axi4lite_reg_bridge.v`
- `bram_clock_reset_adapter.v`
- `npu_full_accelerator_ip.v`

목표는 Hardware 구조 변경이 아니라 Software/Hardware 통합 검증입니다.

## 3. Software Layer

### Low-level Driver

`npu_full.h`

- Register Read/Write
- Descriptor Program
- IRQ Enable
- IRQ Status
- W1C
- START

### End-to-End Helper

`npu_e2e.h`

- Tensor Input Write
- Output Tensor Read
- Result Structure
- Expected Result Compare

### Platform Mapping

`npu_platform.h`

Vivado/Vitis가 생성한 실제 Hardware Symbol을 다음 이름으로 연결합니다.

- `NPU_CTRL_BASEADDR`
- `TENSOR_BRAM_BASEADDR`
- `NPU_INTR_ID`
- Classic flow: `INTC_DEVICE_ID`
- SDT flow: `INTC_BASEADDR`

숫자를 강의자료에서 임의로 고정하지 않습니다.

## 4. Classic / SDT XIntc

현재 AMD embeddedsw의 AXI Interrupt Controller 예제는:

- Classic/non-SDT: Device ID
- SDT: Interrupt Controller Base Address

를 `XIntc_Initialize()`에 전달합니다.

SoC 36 예제도 동일한 분기 구조를 사용합니다.

## 5. Job 0

Input:

- CH0: 16, 32, 48, 64
- CH1: 32, 64, 96, 128

Descriptor:

- INPUT_BASE = 0x200
- OUTPUT_BASE = 0x300
- LENGTH_WORDS = 8

Expected:

- OUT0 = `0x20181008`
- OUT1 = `0x7F7F6333`
- JOB_ID = 1

## 6. Job 1

같은 Hardware를 Reset하지 않고 두 번째 Job을 실행합니다.

Input:

- CH0: 2, 4, 6, 8
- CH1: 4, 8, 12, 16

Descriptor:

- INPUT_BASE = 0x400
- OUTPUT_BASE = 0x500
- LENGTH_WORDS = 8

Expected:

- OUT0 = `0x04030201`
- OUT1 = `0x1B150F09`
- JOB_ID = 2

## 7. Interrupt Completion

Software는 STATUS.DONE을 반복 Polling하지 않습니다.

Main Loop는 ISR이 갱신하는:

- `NpuDoneFlag`
- `NpuErrorFlag`

를 기다립니다.

ISR:

1. `IRQ_STATUS` Read
2. Software Flag Set
3. Peripheral `IRQ_STATUS` W1C
4. Return

Timeout Counter는 교육용 hang 보호 장치이며 완료 확인 Polling Register가 아닙니다.

## 8. Buffer Ownership

각 Job:

```text
CPU_FILL
  ↓
NPU_START
  ↓
NPU_OWNS_BUFFER
  ↓
DONE IRQ
  ↓
CPU_READ
```

NPU BUSY 동안 CPU가 현재 Tensor Buffer를 수정하지 않는 정책을 유지합니다.

## 9. Result Verification

Output 값만 비교하지 않습니다.

`NpuE2E_Verify()`는 다음을 확인합니다.

- OUT0
- OUT1
- READ_WORD_COUNT = 8
- WRITE_WORD_COUNT = 2
- DONE IRQ Pending
- ERROR IRQ 없음
- ERROR_CODE = 0

## 10. Reference Model

두 가지 Reference를 제공합니다.

### Python

`reference/soc36_e2e_reference.py`

### Host C

`reference/soc36_host_reference.c`

Host C Reference는 PC GCC로 실제 실행할 수 있으므로,
MicroBlaze V Software와 같은 C 언어 산술 기준을 별도로 확인할 수 있습니다.

단, Host Reference PASS는 FPGA 실행 PASS를 의미하지 않습니다.

## 11. Self-Checking RTL Regression

`tb_soc36_cpu_npu_e2e.sv`

검증:

- Job 0
- DONE IRQ
- W1C
- Job 1
- JOB_ID 1 → 2
- 두 번째 결과
- ERROR IRQ
- Reject Job이 JOB_ID를 증가시키지 않는지 확인

## 12. 실제 Basys3 실행

필요 절차:

1. SoC 35 Block Design Open
2. Validate Design
3. Generate Bitstream
4. Export Hardware / Platform
5. Vitis Application Project
6. `npu_full.h`, `npu_e2e.h`, `npu_platform.h`, `main_end_to_end.c` 추가
7. 실제 `xparameters.h` Symbol Mapping
8. Build
9. Program FPGA
10. UART Terminal Open
11. Application Run
12. JOB0 PASS / JOB1 PASS / 최종 PASS 확인

## 13. 기대 UART

```text
SoC36 CPU-NPU End-to-End
JOB0 PASS: id=1 out0=0x20181008 out1=0x7F7F6333
JOB1 PASS: id=2 out0=0x04030201 out1=0x1B150F09
SOC36 END-TO-END RESULT: PASS
```

이 출력은 실제 Basys3 실행 전에는 기대 출력입니다.

## 14. Group 7 종료 조건

SoC 36 완료 시 다음 축이 연결됩니다.

- CPU
- AXI Control Plane
- Descriptor
- Tensor BRAM Data Plane
- NPU Arithmetic
- Interrupt
- Driver
- End-to-End Result Check

다음 Group에서는 이 시스템을 대상으로 성능, Sign-off, 확장 NPU 구조를 다룹니다.
