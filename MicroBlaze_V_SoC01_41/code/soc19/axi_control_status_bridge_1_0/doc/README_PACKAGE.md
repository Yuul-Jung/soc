# AXI Control / Status Bridge 1.0

## 목적

AXI4-Lite Register Space와 기능 RTL 사이를 범용 Control/Status + Ready/Valid Interface로 연결합니다.

Packaging Top:
- `axi_control_status_bridge_ip`

Demo Top:
- `axi_control_status_bridge_demo_top`

## 표준 기능 인터페이스

- `control_o[31:0]`
- `status_i[31:0]`
- `in_data_o[31:0]`
- `in_valid_o`
- `in_ready_i`
- `out_data_i[31:0]`
- `out_valid_i`
- `out_ready_o`
- `irq_o`

이 READY/VALID Interface는 AXI4-Stream 전체 규격이 아니라 동일한 Handshake 의미를 차용한 경량 내부 Interface입니다.

## Register Map

- 0x00 CONTROL        RW
- 0x04 CORE_STATUS    RO
- 0x08 BRIDGE_STATUS  RO
- 0x0C IN_DATA        RW Shadow
- 0x10 COMMAND        W1P
- 0x14 OUT_DATA       RO Latched
- 0x18 EVENT_STATUS   W1C
- 0x1C VERSION        RO
- 0x20 ID             RO

COMMAND:
- bit0 SUBMIT
- bit1 POP_OUT
- bit2 CLEAR_ERROR

EVENT_STATUS:
- bit0 IN_ACCEPTED
- bit1 OUT_CAPTURED
- bit2 ERROR

## Buffer 정책

Input:
- Software writes IN_DATA shadow.
- SUBMIT copies shadow data into a one-word pending buffer.
- in_valid remains asserted until in_ready is accepted.

Output:
- Bridge asserts out_ready while its output buffer is empty.
- out_valid && out_ready captures one word.
- Software reads OUT_DATA and executes POP_OUT.

## Packaging

Vivado IP Packager에서 `axi_control_status_bridge_ip`를 Top으로 Package합니다.
`component.xml`은 Vivado가 생성하며 수동으로 만들지 않습니다.
