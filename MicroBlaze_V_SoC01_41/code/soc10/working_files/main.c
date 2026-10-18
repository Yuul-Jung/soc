#include "xparameters.h"
#include "xgpio.h"
#include "xuartlite_l.h"
#include "xtmrctr.h"
#include "xstatus.h"
#include "xil_types.h"
#include "xil_exception.h"

#ifdef SDT
#include "xinterrupt_wrap.h"
#else
#include "xintc.h"
#endif

/*
 * SoC 10 - MicroBlaze V + GPIO + UART + Timer + AXI INTC Integration
 *
 * GPIO Channel 1 : LED[15:0] output
 * GPIO Channel 2 : SW[15:0] input
 *
 * LED ownership:
 *   LED[13:0] : SW[13:0] mirror
 *   LED14     : UART command control ('1' = ON, '0' = OFF)
 *   LED15     : Timer interrupt heartbeat
 *
 * UART : Polling, 115200 8N1
 * Timer: 100 MHz, 0.5 s interval, Down Count + Auto Reload + Interrupt
 * IRQ  : AXI Timer -> AXI INTC -> MicroBlaze V
 */

#define GPIO_LED_CHANNEL        1U
#define GPIO_SW_CHANNEL         2U

#define SW_LED_MASK             0x00003FFFU
#define UART_LED_MASK           0x00004000U
#define HEARTBEAT_LED_MASK      0x00008000U

#define TIMER0                  0U
#define TIMER_TICKS_500MS       50000000U
#define TIMER_RESET_VALUE       (TIMER_TICKS_500MS - 2U)

#ifndef SDT
#define GPIO_DEVICE_ID          XPAR_GPIO_0_DEVICE_ID
#define TIMER_DEVICE_ID         XPAR_TMRCTR_0_DEVICE_ID
#define INTC_DEVICE_ID          XPAR_INTC_0_DEVICE_ID
#define TIMER_INTERRUPT_ID      XPAR_INTC_0_TMRCTR_0_VEC_ID
#define UART_BASEADDR           XPAR_UARTLITE_0_BASEADDR
#else
#define GPIO_BASEADDR           XPAR_XGPIO_0_BASEADDR
#define TIMER_BASEADDR          XPAR_XTMRCTR_0_BASEADDR
#define UART_BASEADDR           XPAR_XUARTLITE_0_BASEADDR
#endif

static XGpio Gpio;
static XTmrCtr Timer;

#ifndef SDT
static XIntc Intc;
#endif

volatile u32 interrupt_count = 0U;
volatile u32 switch_value    = 0U;
volatile u32 led_state       = 0U;
volatile u8  last_uart_rx    = 0U;

static u32 uart_led_state = 0U;

static void UartPutChar(u8 ch)
{
    XUartLite_SendByte(UART_BASEADDR, ch);
}

static void UartPutString(const char *text)
{
    while (*text != '\0') {
        UartPutChar((u8)*text);
        text++;
    }
}

static void UartPutHexNibble(u8 value)
{
    value &= 0x0FU;

    if (value < 10U) {
        UartPutChar((u8)('0' + value));
    } else {
        UartPutChar((u8)('A' + (value - 10U)));
    }
}

static void UartPutHex16(u16 value)
{
    int shift;

    for (shift = 12; shift >= 0; shift -= 4) {
        UartPutHexNibble((u8)(value >> shift));
    }
}

static void UartPutHex32(u32 value)
{
    int shift;

    for (shift = 28; shift >= 0; shift -= 4) {
        UartPutHexNibble((u8)(value >> shift));
    }
}

static void PrintHelp(void)
{
    UartPutString("\r\nCommands\r\n");
    UartPutString("  1 : LED14 ON\r\n");
    UartPutString("  0 : LED14 OFF\r\n");
    UartPutString("  r : Read status\r\n");
    UartPutString("  h : Help\r\n");
}

static void PrintStatus(void)
{
    UartPutString("\r\nSW=0x");
    UartPutHex16((u16)switch_value);
    UartPutString(" LED=0x");
    UartPutHex16((u16)led_state);
    UartPutString(" IRQ=0x");
    UartPutHex32(interrupt_count);
    UartPutString("\r\n");
}

static void TimerCallback(void *CallBackRef, u8 TmrCtrNumber)
{
    (void)CallBackRef;
    (void)TmrCtrNumber;
    interrupt_count++;
}

static int InitGpio(void)
{
#ifndef SDT
    return XGpio_Initialize(&Gpio, GPIO_DEVICE_ID);
#else
    return XGpio_Initialize(&Gpio, GPIO_BASEADDR);
#endif
}

static int InitTimer(void)
{
    int status;

#ifndef SDT
    status = XTmrCtr_Initialize(&Timer, TIMER_DEVICE_ID);
#else
    status = XTmrCtr_Initialize(&Timer, TIMER_BASEADDR);
#endif

    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = XTmrCtr_SelfTest(&Timer, TIMER0);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XTmrCtr_SetHandler(&Timer, TimerCallback, &Timer);
    XTmrCtr_SetOptions(
        &Timer,
        TIMER0,
        XTC_DOWN_COUNT_OPTION |
        XTC_AUTO_RELOAD_OPTION |
        XTC_INT_MODE_OPTION
    );
    XTmrCtr_SetResetValue(&Timer, TIMER0, TIMER_RESET_VALUE);

    return XST_SUCCESS;
}

static int SetupInterruptSystem(void)
{
    int status;

#ifndef SDT
    status = XIntc_Initialize(&Intc, INTC_DEVICE_ID);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = XIntc_Connect(
        &Intc,
        TIMER_INTERRUPT_ID,
        (XInterruptHandler)XTmrCtr_InterruptHandler,
        (void *)&Timer
    );
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = XIntc_Start(&Intc, XIN_REAL_MODE);
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XIntc_Enable(&Intc, TIMER_INTERRUPT_ID);

    Xil_ExceptionInit();
    Xil_ExceptionRegisterHandler(
        XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XIntc_InterruptHandler,
        &Intc
    );
    Xil_ExceptionEnable();
#else
    status = XSetupInterruptSystem(
        &Timer,
        (XInterruptHandler)XTmrCtr_InterruptHandler,
        Timer.Config.IntrId,
        Timer.Config.IntrParent,
        XINTERRUPT_DEFAULT_PRIORITY
    );

    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }
#endif

    return XST_SUCCESS;
}

static void InitUart(void)
{
    /* RX/TX FIFO clear. UART interrupt remains disabled. */
    XUartLite_WriteReg(
        UART_BASEADDR,
        XUL_CONTROL_REG_OFFSET,
        0x03U
    );
}

static void HandleUartCommand(void)
{
    if (XUartLite_IsReceiveEmpty(UART_BASEADDR)) {
        return;
    }

    last_uart_rx = XUartLite_RecvByte(UART_BASEADDR);

    switch (last_uart_rx) {
    case '1':
        uart_led_state = UART_LED_MASK;
        UartPutString("\r\nLED14=ON\r\n");
        break;

    case '0':
        uart_led_state = 0U;
        UartPutString("\r\nLED14=OFF\r\n");
        break;

    case 'r':
    case 'R':
        PrintStatus();
        break;

    case 'h':
    case 'H':
        PrintHelp();
        break;

    case '\r':
    case '\n':
        break;

    default:
        UartPutString("\r\nUnknown command. Press h.\r\n");
        break;
    }
}

static void UpdateLedOutput(void)
{
    u32 new_led_state;
    u32 heartbeat_state;

    if ((interrupt_count & 1U) != 0U) {
        heartbeat_state = HEARTBEAT_LED_MASK;
    } else {
        heartbeat_state = 0U;
    }

    new_led_state =
        (switch_value & SW_LED_MASK) |
        uart_led_state |
        heartbeat_state;

    if (new_led_state != led_state) {
        led_state = new_led_state;
        XGpio_DiscreteWrite(
            &Gpio,
            GPIO_LED_CHANNEL,
            led_state
        );
    }
}

int main(void)
{
    int status;

    status = InitGpio();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    InitUart();

    status = InitTimer();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = SetupInterruptSystem();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    led_state = 0U;
    XGpio_DiscreteWrite(&Gpio, GPIO_LED_CHANNEL, led_state);

    UartPutString("\r\nSoC 10 Integrated System Ready\r\n");
    PrintHelp();

    XTmrCtr_Start(&Timer, TIMER0);

    while (1) {
        switch_value = XGpio_DiscreteRead(
            &Gpio,
            GPIO_SW_CHANNEL
        );

        HandleUartCommand();
        UpdateLedOutput();
    }

    return XST_SUCCESS;
}
