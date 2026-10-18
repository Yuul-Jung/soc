#include "xparameters.h"
#include "xgpio.h"
#include "xstatus.h"
#include "xil_types.h"

/*
 * SoC 06 - AXI GPIO
 *
 * Channel 1 : Basys3 LED[15:0]  (Output)
 * Channel 2 : Basys3 SW[15:0]   (Input)
 *
 * SW0 ~ SW15 상태를 읽어서 LED0 ~ LED15에 그대로 출력한다.
 */

#define LED_CHANNEL  1U
#define SW_CHANNEL   2U
#define GPIO_MASK    0x0000FFFFU

#ifndef SDT
#define GPIO_DEVICE_ID   XPAR_GPIO_0_DEVICE_ID
#else
#define GPIO_BASEADDR    XPAR_XGPIO_0_BASEADDR
#endif

static XGpio Gpio;

/* Debugger에서 관찰하기 위한 변수 */
volatile u32 switch_value = 0U;
volatile u32 led_value    = 0U;

int main(void)
{
    int status;

#ifndef SDT
    status = XGpio_Initialize(&Gpio, GPIO_DEVICE_ID);
#else
    status = XGpio_Initialize(&Gpio, GPIO_BASEADDR);
#endif

    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    /*
     * Vivado에서 Channel 1은 All Outputs,
     * Channel 2는 All Inputs로 고정한다.
     *
     * 따라서 이 예제에서는 Software에서 GPIO_TRI를 다시 설정하지 않는다.
     */

    while (1) {
        /* Channel 2: Basys3 Slide Switch 읽기 */
        switch_value = XGpio_DiscreteRead(&Gpio, SW_CHANNEL) & GPIO_MASK;

        /* 읽은 16비트 값을 그대로 LED 출력으로 전달 */
        led_value = switch_value;
        XGpio_DiscreteWrite(&Gpio, LED_CHANNEL, led_value);
    }

    return XST_SUCCESS;
}
