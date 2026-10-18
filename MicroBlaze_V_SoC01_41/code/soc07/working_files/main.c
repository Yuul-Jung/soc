#include "xparameters.h"
#include "xuartlite_l.h"
#include "xil_types.h"

/*
 * SoC 07 - AXI UART Lite Polling Echo
 *
 * Hardware setting:
 *   Baud Rate : 115200
 *   Data Bits : 8
 *   Parity    : None
 *   Stop Bit  : 1
 *
 * PC terminal:
 *   115200 8N1
 *   Flow control : None
 *   Local echo   : Off
 */

#ifndef SDT
#define UARTLITE_BASEADDR XPAR_UARTLITE_0_BASEADDR
#else
#define UARTLITE_BASEADDR XPAR_XUARTLITE_0_BASEADDR
#endif

volatile u8  last_rx  = 0U;
volatile u32 rx_count = 0U;
volatile u32 tx_count = 0U;

static void uart_puts(const char *text)
{
    while (*text != '\0') {
        XUartLite_SendByte(UARTLITE_BASEADDR, (u8)*text);
        tx_count++;
        text++;
    }
}

int main(void)
{
    /*
     * CTRL_REG bit1 = RX FIFO reset
     * CTRL_REG bit0 = TX FIFO reset
     * 0x03 : 두 FIFO를 모두 비운다.
     * Interrupt bit4는 0이므로 Polling 방식이다.
     */
    XUartLite_WriteReg(
        UARTLITE_BASEADDR,
        XUL_CONTROL_REG_OFFSET,
        0x03U
    );

    uart_puts("\r\nAXI UART Lite Echo Ready\r\n");
    uart_puts("Type characters. Received data will be echoed.\r\n> ");

    while (1) {
        /* RX FIFO에 문자가 들어올 때까지 Blocking 대기 */
        last_rx = XUartLite_RecvByte(UARTLITE_BASEADDR);
        rx_count++;

        /* 받은 1 Byte를 그대로 PC로 다시 전송 */
        XUartLite_SendByte(UARTLITE_BASEADDR, last_rx);
        tx_count++;
    }

    return 0;
}
