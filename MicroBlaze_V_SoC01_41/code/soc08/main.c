#include "xparameters.h"
#include "xtmrctr.h"
#include "xgpio.h"
#include "xstatus.h"
#include "xil_types.h"

/* SoC08: Timer0 0.5초 Polling, 기존 AXI GPIO LED0 출력 */
#define TIMER0                 0U
#define GPIO_LED_CHANNEL       1U
#define LED0_MASK              0x00000001U

/* 100 MHz × 0.5 s = 50,000,000 clocks, PG079: TLR + 2 */
#define TIMER_RESET_VALUE      (50000000U - 2U)

#ifndef SDT
#define TIMER_DEVICE_ID        XPAR_TMRCTR_0_DEVICE_ID
#define GPIO_DEVICE_ID         XPAR_GPIO_0_DEVICE_ID
#else
#define TIMER_BASEADDR         XPAR_XTMRCTR_0_BASEADDR
#define GPIO_BASEADDR          XPAR_XGPIO_0_BASEADDR
#endif

static XTmrCtr Timer;
static XGpio Gpio;

/* Vitis Debug Watch로 확인할 변수 */
volatile u32 expire_count = 0U;
volatile u32 led_state = 0U;
volatile u32 timer_value = 0U;

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
    if (status != XST_SUCCESS) return status;
    status = XTmrCtr_SelfTest(&Timer, TIMER0);
    if (status != XST_SUCCESS) return status;

    /* (유지) Down Count + Auto Reload, Interrupt 출력은 미사용 */
    XTmrCtr_SetOptions(&Timer, TIMER0,
        XTC_DOWN_COUNT_OPTION | XTC_AUTO_RELOAD_OPTION);
    XTmrCtr_SetResetValue(&Timer, TIMER0, TIMER_RESET_VALUE);
    XTmrCtr_Start(&Timer, TIMER0);
    return XST_SUCCESS;
}

/* 만료 비트 T0INT는 1을 쓰면 0으로 지워진다. */
static void clear_timer_expired(void)
{
    u32 csr = XTmrCtr_GetControlStatusReg(Timer.BaseAddress, TIMER0);
    XTmrCtr_SetControlStatusReg(Timer.BaseAddress, TIMER0,
        csr | XTC_CSR_INT_OCCURED_MASK);
}

int main(void)
{
    if (init_gpio() != XST_SUCCESS) return XST_FAILURE;
    if (init_timer() != XST_SUCCESS) return XST_FAILURE;

    /* LED0 초기 소등: 기존 AXI GPIO 채널 1 출력 */
    XGpio_DiscreteWrite(&Gpio, GPIO_LED_CHANNEL, led_state);

    while (1) {
        timer_value = XTmrCtr_GetValue(&Timer, TIMER0);
        if (XTmrCtr_IsExpired(&Timer, TIMER0)) {
            clear_timer_expired();
            expire_count++;
            led_state ^= LED0_MASK;  /* 0 → 1 → 0 반복 */
            XGpio_DiscreteWrite(&Gpio, GPIO_LED_CHANNEL, led_state);
        }
    }
}
