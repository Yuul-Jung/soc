# SoC 32 · NPU Done Interrupt / AXI Interrupt Controller / ISR

## 1. 목표

SoC 31의 Polling 방식:

`START → STATUS.DONE 반복 읽기`

를 Interrupt 방식으로 바꿉니다.

구조:

`NPU event → IRQ_STATUS → IRQ_ENABLE → irq → AXI Interrupt Controller → MicroBlaze V ISR`

## 2. Register Map 추가

기존 SoC 31 Offset은 유지합니다.

| Offset | Name | Type | 역할 |
|---:|---|---|---|
| 0x6C | IRQ_ENABLE | RW | bit0 DONE, bit1 ERROR |
| 0x70 | IRQ_STATUS | RO/W1C | bit0 DONE pending, bit1 ERROR pending |

## 3. IRQ는 Level 방식

`irq = OR(IRQ_STATUS & IRQ_ENABLE)`

DONE은 한 Clock Event이지만 `IRQ_STATUS.DONE`에 저장됩니다.

따라서 CPU가 ISR에 진입할 때까지 interrupt condition이 사라지지 않습니다.

ISR에서:

1. IRQ_STATUS 읽기
2. software flag 갱신
3. IRQ_STATUS에 같은 bit를 1로 Write
4. W1C로 pending clear
5. irq deassert

## 4. 왜 W1C인가

여러 interrupt source가 같은 Status Register에 있을 때 필요한 source만 clear할 수 있습니다.

예:

- DONE = bit0
- ERROR = bit1

DONE만 clear:

`write 0x00000001 to IRQ_STATUS`

## 5. Event-set 우선

IRQ_STATUS clear와 새 event가 같은 Clock에 겹치면 새 event가 사라지면 안 됩니다.

SoC 32 next-state:

`next = (old & ~clear_mask) | event_set`

따라서 event-set이 clear보다 우선합니다.

## 6. AXI Write 보강

AW와 W는 독립적으로 capture합니다.

둘 다 확보된 Clock에:

- Register Write
- BVALID

를 같이 발생시킵니다.

따라서 Write Response가 실제 Register Commit보다 먼저 나가지 않도록 합니다.

## 7. MicroBlaze V Interrupt

MicroBlaze V standalone 흐름:

1. `XIntc_Initialize`
2. `XIntc_Connect`
3. `XIntc_Start(..., XIN_REAL_MODE)`
4. `XIntc_Enable`
5. `Xil_ExceptionInit`
6. `Xil_ExceptionRegisterHandler`
7. `Xil_ExceptionEnable`

NPU ISR은 Peripheral의 `IRQ_STATUS`를 읽고 W1C clear합니다.

## 8. Block Design

MicroBlaze V에서는 AXI Interrupt Controller를 사용합니다.

권장 연결:

`NPU irq → xlconcat → axi_intc/intr`

`axi_intc/irq → MicroBlaze V Interrupt`

Interrupt source가 NPU 하나뿐이면 단순 연결도 가능하지만,
기존 GPIO/Timer/UART Interrupt와 함께 사용할 경우 `xlconcat`로 묶습니다.

NPU IRQ는 level-high source입니다.

## 9. Software Symbol

주소와 Interrupt ID는 고정 숫자를 쓰지 않습니다.

생성된 `xparameters.h`에서:

- NPU Base Address
- AXI INTC Device ID
- NPU Interrupt ID

를 확인합니다.

`main_interrupt.c`는 `NPU_INTR_ID`를 임의로 가정하지 않고 명시적으로 요구합니다.

## 10. Testbench

검증 항목:

- SoC31 WSTRB regression
- DONE event with IRQ disabled
- pending source enable 후 IRQ assert
- DONE W1C 후 IRQ deassert
- normal interrupt-driven DONE
- output result 유지
- ERROR-only interrupt
- START while BUSY → ERROR pending
- DONE disabled 상태에서 DONE pending이 IRQ를 올리지 않는지 확인

## 11. 기대 결과

- OUT_CH0 = `0x20181008`
- OUT_CH1 = `0x7F7F6333`
- SAT_COUNT = `2`
- ISR에서 DONE pending 확인
- ISR W1C 뒤 IRQ Low

## 12. 다음 단계

SoC 33:

- AXI BRAM Tensor Buffer
- Control Plane / Data Plane 분리
- Register 8개 입력에서 Tensor Memory로 확장
