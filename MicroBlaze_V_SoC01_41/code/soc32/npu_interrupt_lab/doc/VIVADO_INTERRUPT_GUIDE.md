# SoC 32 · Vivado Block Design 연결

## 1. 기존 SoC 31 유지

유지:

- MicroBlaze V
- Local BRAM
- Clock / Processor System Reset
- SmartConnect
- `npu_axi_irq_accel_ip`의 `S_AXI`
- SoC31 NPU Base Address

추가:

- NPU `irq`
- AXI Interrupt Controller
- 필요 시 `xlconcat`

## 2. 연결

```text
npu_axi_irq_accel_ip/irq
        ↓
     xlconcat
        ↓
axi_intc/intr
        ↓
axi_intc/irq
        ↓
MicroBlaze V/Interrupt
```

기존 Timer/GPIO/UART Interrupt가 있으면 같은 `xlconcat`의 다른 입력에 연결합니다.

## 3. AXI Interrupt Controller

- `S_AXI`를 MicroBlaze V Peripheral AXI 경로에 연결
- AXI Clock/Reset은 해당 Peripheral Clock Domain과 맞춤
- NPU source는 level-high interrupt로 사용
- `irq` output을 MicroBlaze V Interrupt input에 연결

## 4. Address Editor

NPU와 AXI INTC 모두 주소 공간이 필요합니다.

주소 숫자는 자료에서 임의로 고정하지 않습니다.

Vivado Address Editor 결과를 사용합니다.

## 5. xparameters.h

Build 후 생성된 Symbol을 확인합니다.

필요 항목:

- NPU AXI Base Address
- AXI INTC Device ID
- NPU Interrupt ID

`main_interrupt.c`의:

- `NPU_BASEADDR`
- `INTC_DEVICE_ID`
- `NPU_INTR_ID`

가 실제 Symbol과 연결되어야 합니다.

## 6. ISR 순서

```text
NPU event
  ↓
IRQ_STATUS latch
  ↓
irq high
  ↓
AXI INTC
  ↓
MicroBlaze V exception
  ↓
XIntc_InterruptHandler
  ↓
NpuIsr
  ↓
read IRQ_STATUS
  ↓
set software flag
  ↓
W1C IRQ_STATUS
  ↓
irq low
```

## 7. 확인

정상 실행:

```text
SoC32 NPU interrupt demo
IRQ_STATUS = 0x00000001
OUT_CH0 = 0x20181008
OUT_CH1 = 0x7F7F6333
SAT_COUNT = 2
SOC32 RESULT: PASS
```

## 8. 다음 장

SoC 33에서 Register Input 대신 AXI BRAM Tensor Buffer를 추가합니다.
