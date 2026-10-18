#include "xparameters.h"
#include "xtmrctr.h"
#include "xgpio.h"
#include "xstatus.h"
#include "xil_types.h"
#include "xil_exception.h"

#ifdef SDT
#include "xinterrupt_wrap.h"
#else
#include "xintc.h"
#endif

/*
 * SoC 09 - AXI Interrupt Controller + AXI Timer
 *
 * Hardware path:
 *   axi_timer_0/interrupt
 *      -> axi_intc_0/intr[0]
 *      -> axi_intc_0/irq
 *      -> microblaze_riscv_0/Interrupt
 *
 * Timer:
 *   100 MHz
 *   0.5 s interval
 *   Down Count + Auto Reload + Interrupt
 *
 * User callback:
 *   - interrupt_count++
 *   - timer_event = 1
 *
 * Main loop:
 *   - timer_event 확인
 *   - AXI GPIO LED0 toggle
 */

#define TIMER0                  0U
#define LED_CHANNEL             1U
#define LED0_MASK               0x00000001U

#define TIMER_TICKS_500MS       50000000U
#define TIMER_RESET_VALUE       (TIMER_TICKS_500MS - 2U)

#ifndef SDT
#define TIMER_DEVICE_ID         XPAR_TMRCTR_0_DEVICE_ID
#define GPIO_DEVICE_ID          XPAR_GPIO_0_DEVICE_ID
#define INTC_DEVICE_ID          XPAR_INTC_0_DEVICE_ID
#define TIMER_INTERRUPT_ID      XPAR_INTC_0_TMRCTR_0_VEC_ID
#else
#define TIMER_BASEADDR          XPAR_XTMRCTR_0_BASEADDR
#define GPIO_BASEADDR           XPAR_XGPIO_0_BASEADDR
#endif

static XTmrCtr Timer;
static XGpio Gpio;

#ifndef SDT
static XIntc Intc;
#endif

volatile u32 interrupt_count = 0U;
volatile u32 timer_event     = 0U;
volatile u32 led_state       = 0U;

/*
 * XTmrCtr_InterruptHandler()가 Timer HW interrupt를 처리한 뒤
 * 이 callback을 Interrupt Context에서 호출한다.
 *
 * ISR/Callback에서는 긴 처리나 출력 작업을 하지 않는다.
 */
static void TimerCallback(void *CallBackRef, u8 TmrCtrNumber)
{
    (void)CallBackRef;
    (void)TmrCtrNumber;

    interrupt_count++;
    timer_event = 1U;
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

int main(void)
{
    int status;

    status = InitGpio();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = InitTimer();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = SetupInterruptSystem();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, led_state);

    /*
     * Interrupt path를 모두 준비한 뒤 Timer 시작
     */
    XTmrCtr_Start(&Timer, TIMER0);

    while (1) {
        /*
         * Callback은 event만 남긴다.
         * 실제 AXI GPIO Write는 Main Context에서 수행한다.
         */
        if (timer_event != 0U) {
            timer_event = 0U;

            led_state ^= LED0_MASK;
            XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, led_state);
        }
    }

    return XST_SUCCESS;
}
