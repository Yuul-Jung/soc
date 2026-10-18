# UART TX AXI4-Lite IP

기존 UART TX RTL을 수정하지 않고 Adapter + Register Bank + 공통 AXI4-Lite Adapter로 IP화합니다.

Packaging Top: `uart_tx_axi4lite_ip`

권장 VLNV:
- Vendor: user.org
- Library: user
- Name: uart_tx_ip
- Version: 1.0

Register Map:
- 0x00 CONTROL
- 0x04 STATUS
- 0x08 TX_DATA
- 0x0C COMMAND
- 0x10 IRQ_STATUS
- 0x14 BAUD_DIV
- 0x18 VERSION
- 0x1C ID

`component.xml`은 Vivado IP Packager가 생성합니다.
