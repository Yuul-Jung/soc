# SoC 36 · Basys3 / Vitis 실행 절차

## 1. Vivado Hardware

SoC 35의 Hardware를 그대로 사용합니다.

확인:

- `npu_full_accelerator_ip/S_AXI`
- Tensor BRAM Port A: AXI BRAM Controller
- Tensor BRAM Port B: NPU
- `npu_full_accelerator_ip/irq`
- AXI Interrupt Controller
- MicroBlaze V
- 100 MHz common clock

## 2. Address Editor

CPU-visible 영역:

- NPU Control Register Address Segment
- Tensor BRAM Address Segment

Descriptor의:

- `INPUT_BASE`
- `OUTPUT_BASE`

는 Tensor BRAM 내부 Offset입니다.

CPU가 Tensor Memory에 접근할 때는:

`TENSOR_BRAM_BASEADDR + Descriptor Offset`

을 사용합니다.

## 3. Generate Bitstream

- Validate Design
- Generate Output Products
- Generate Bitstream
- Hardware Platform 생성/Export

## 4. Vitis Project

Standalone Application을 생성하고 다음 파일을 추가합니다.

```text
software/
├── npu_full.h
├── npu_e2e.h
├── npu_platform.h
└── main_end_to_end.c
```

## 5. npu_platform.h Symbol Mapping

현재 Platform이 생성한 Header를 확인합니다.

필요 의미:

- NPU Control Base
- Tensor BRAM Base
- NPU Interrupt Vector ID
- AXI INTC Device ID 또는 Base Address

Instance 이름에 따라 Symbol 이름이 달라질 수 있으므로
강의자료의 예시 주소/ID를 직접 복사하지 않습니다.

## 6. AXI Interrupt Controller

MicroBlaze V에서는 AXI Interrupt Controller를 사용합니다.

여러 Interrupt Source가 있으면 `xlconcat`으로 합쳐
AXI INTC `intr` 입력으로 전달합니다.

## 7. Classic vs SDT

현재 AMD XIntc 예제 기준:

Classic:

```c
XIntc_Initialize(&Intc, INTC_DEVICE_ID);
```

SDT:

```c
XIntc_Initialize(&Intc, INTC_BASEADDR);
```

SoC 36 Software는 `#ifndef SDT` 분기를 사용합니다.

## 8. Build

Build Error가 발생하면 먼저 확인합니다.

- `NPU_CTRL_BASEADDR`
- `TENSOR_BRAM_BASEADDR`
- `NPU_INTR_ID`
- `INTC_DEVICE_ID` / `INTC_BASEADDR`

## 9. FPGA Program / Run

1. Basys3 연결
2. FPGA Program
3. MicroBlaze V Application Run
4. UART Terminal 연결

## 10. 기대 결과

```text
SoC36 CPU-NPU End-to-End
JOB0 PASS: id=1 out0=0x20181008 out1=0x7F7F6333
JOB1 PASS: id=2 out0=0x04030201 out1=0x1B150F09
SOC36 END-TO-END RESULT: PASS
```

## 11. 실제 결과 기록

실제 보드 실행 후 기록:

- Vivado Version
- Vitis Version
- Bitstream Build
- NPU Control Base
- Tensor BRAM Base
- NPU Intr ID
- JOB0 Output
- JOB1 Output
- UART Log
- WNS/TNS
- LUT/FF/DSP/BRAM
- Power

실측하지 않은 값은 PASS나 측정값으로 기록하지 않습니다.
