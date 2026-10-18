#include "uart_tx_driver.h"
#include "pwm_driver.h"

/*
 * SoC 18 board-level software example.
 *
 * UartBaseAddress and PwmBaseAddress come from the actual
 * Vivado/Vitis hardware platform. No fictional XPAR macro is used here.
 */

int Soc18_UartPwmDemo(
    UINTPTR UartBaseAddress,
    UINTPTR PwmBaseAddress
)
{
    UartTxDrv uart;
    PwmDrv pwm;
    int rc;

    rc = UartTxDrv_Initialize(
        &uart,
        UartBaseAddress
    );
    if (rc != UARTTXDRV_OK) {
        return rc;
    }

    rc = PwmDrv_Initialize(
        &pwm,
        PwmBaseAddress
    );
    if (rc != PWMDRV_OK) {
        return rc;
    }

    /*
     * 100 MHz clock example:
     * Period 100,000 clocks -> 1 kHz PWM
     * Duty   25,000 clocks -> 25 %
     */
    rc = PwmDrv_Configure(
        &pwm,
        100000U,
        25000U,
        1U,
        0U
    );
    if (rc != PWMDRV_OK) {
        return rc;
    }

    /* Send ASCII 'A' through the custom UART TX IP. */
    rc = UartTxDrv_SendBlocking(
        &uart,
        (u8)'A',
        2000000U
    );
    if (rc != UARTTXDRV_OK) {
        return rc;
    }

    return 0;
}
