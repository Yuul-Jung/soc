# SoC 35 · Vivado Block Design Guide

## 1. 목표

```text
                         +----------------------+
MicroBlaze V -- AXI ------>| NPU S_AXI            |
                         |                       |
Tensor BRAM Port B <---->| NPU BRAM native      |
                         |                       |
AXI INTC <---------------| irq                   |
                         +----------------------+
```

CPU Data Plane:

`MicroBlaze V → AXI BRAM Controller → Block Memory Generator Port A`

NPU Data Plane:

`NPU BRAM → Block Memory Generator Port B`

## 2. AXI BRAM Controller

이번 설계에서는 CPU가 한 Memory Port를 사용하고 다른 Port를 NPU가 직접 사용해야 합니다.

따라서 AXI BRAM Controller의 BRAM Interface 수와 Block Memory Generator True Dual-Port 설정을 확인합니다.

Connection Automation이 두 BRAM Port를 모두 AXI BRAM Controller에 연결하도록 구성하지 않도록 주의합니다.

## 3. Clock

교육 기준:

- MicroBlaze V peripheral AXI = 100 MHz
- NPU S_AXI = 100 MHz
- Tensor BRAM Port A/B = 100 MHz
- NPU Engine = 100 MHz

SoC 35에서는 단일 Clock Domain으로 유지합니다.

다른 Clock Domain으로 확장할 때는 SoC 20의 CDC/Reset 구조를 적용합니다.

## 4. Interrupt

`npu_full_accelerator_ip/irq`

→ `xlconcat`

→ `axi_intc/intr`

→ `axi_intc/irq`

→ `MicroBlaze V/Interrupt`

NPU irq는 level-high입니다.

## 5. Address Editor

두 종류의 CPU-visible 주소 공간을 할당합니다.

1. NPU Control Register Base
2. Tensor BRAM Base

Software에서는 `xparameters.h`에서 생성된 실제 Symbol을 사용합니다.

Descriptor의 INPUT_BASE/OUTPUT_BASE는 Tensor BRAM 내부 Offset입니다.

예:

- Tensor BRAM CPU Base = Vivado가 할당한 시스템 주소
- Descriptor INPUT_BASE = 0x200
- Descriptor OUTPUT_BASE = 0x300

## 6. Validate Design

확인:

- S_AXI 연결
- BRAM Port Width
- BRAM Address Width
- Port A / Port B ownership
- irq polarity/type
- Clock/Reset
- Address Segment
- no dangling interface

## 7. Software

필요 Symbol:

- `NPU_CTRL_BASEADDR`
- `TENSOR_BRAM_BASEADDR`
- `INTC_DEVICE_ID`
- `NPU_INTR_ID`

실제 이름은 Block Design Instance 이름에 따라 달라지므로 숫자를 임의로 하드코딩하지 않습니다.
