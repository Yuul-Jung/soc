#include "xparameters.h"
#include "xtmrctr.h"
#include "xgpio.h"
#include "xstatus.h"
#include "xil_types.h"

/*
 * SoC 08 - AXI Timer Polling + AXI GPIO LED Blink
 *
 * Timer clock : 100 MHz
 * Clock period: 10 ns
 *
 * Down-count Generate Mode:
 *   interval = (TLR0 + 2) * 10 ns
 *
 * 0.5 s:
 *   50,000,000 clocks
 *   TLR0 = 50,000,000 - 2
 *        = 49,999,998
 *        = 0x02FAF07E
 *
 * Timer expires every 0.5 s.
 * LED0 toggles at every expiration.
 * Therefore LED0 ON/OFF full cycle is about 1 s.
 */

#define TIMER0                  0U
#define LED_CHANNEL             1U
#define LED0_MASK               0x00000001U

#define TIMER_CLOCK_HZ          100000000U
#define TIMER_INTERVAL_MS       500U
#define TIMER_TICKS_500MS       50000000U
#define TIMER_RESET_VALUE       (TIMER_TICKS_500MS - 2U)

#ifndef SDT
#define TIMER_DEVICE_ID         XPAR_TMRCTR_0_DEVICE_ID
#define GPIO_DEVICE_ID          XPAR_GPIO_0_DEVICE_ID
#else
#define TIMER_BASEADDR          XPAR_XTMRCTR_0_BASEADDR
#define GPIO_BASEADDR           XPAR_XGPIO_0_BASEADDR
#endif

static XTmrCtr Timer;
static XGpio Gpio;

volatile u32 led_state    = 0U;
volatile u32 expire_count = 0U;
volatile u32 timer_value  = 0U;

static int init_gpio(void)
{
#ifndef SDT
    return XGpio_Initialize(&Gpio, GPIO_DEVICE_ID);
#else
    return XGpio_Initialize(&Gpio, GPIO_BASEADDR);
#endif
}

static int init_timer(void)
{
    int status;

#ifndef SDT
    status = XTmrCtr_Initialize(&Timer, TIMER_DEVICE_ID);
#else
    status = XTmrCtr_Initialize(&Timer, TIMER_BASEADDR);
#endif

    if (status != XST_SUCCESS) {
        return status;
    }

    status = XTmrCtr_SelfTest(&Timer, TIMER0);
    if (status != XST_SUCCESS) {
        return status;
    }

    /*
     * Polling Generate Mode:
     * - Down Count
     * - Auto Reload
     * - Interrupt output is NOT enabled
     */
    XTmrCtr_SetOptions(
        &Timer,
        TIMER0,
        XTC_DOWN_COUNT_OPTION | XTC_AUTO_RELOAD_OPTION
    );

    XTmrCtr_SetResetValue(&Timer, TIMER0, TIMER_RESET_VALUE);
    XTmrCtr_Start(&Timer, TIMER0);

    return XST_SUCCESS;
}

static void clear_timer_expired(void)
{
    u32 csr;

    /*
     * T0INT is Write-1-to-Clear.
     * Keep the current control bits and write 1 only to the event flag.
     */
    csr = XTmrCtr_GetControlStatusReg(Timer.BaseAddress, TIMER0);

    XTmrCtr_SetControlStatusReg(
        Timer.BaseAddress,
        TIMER0,
        csr | XTC_CSR_INT_OCCURED_MASK
    );
}

int main(void)
{
    int status;

    status = init_gpio();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = init_timer();
    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /* LED0 initially OFF */
    XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, led_state);

    while (1) {
        /* Debugger에서 현재 down-counter 값을 관찰할 수 있다. */
        timer_value = XTmrCtr_GetValue(&Timer, TIMER0);

        if (XTmrCtr_IsExpired(&Timer, TIMER0)) {
            clear_timer_expired();

            expire_count++;

            /* LED0 toggle */
            led_state ^= LED0_MASK;
            XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, led_state);
        }
    }

    return XST_SUCCESS;
}
