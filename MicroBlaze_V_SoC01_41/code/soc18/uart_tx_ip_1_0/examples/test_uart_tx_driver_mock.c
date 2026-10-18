#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef uint8_t u8;
typedef uint32_t u32;
typedef uintptr_t UINTPTR;

#define MOCK_BASE 0x20000000U

static u32 regs[8];
static u32 timeout_mode = 0U;

u32 Xil_In32(UINTPTR Addr)
{
    u32 index = (u32)(Addr - MOCK_BASE) >> 2;
    return (index < 8U) ? regs[index] : 0U;
}

void Xil_Out32(UINTPTR Addr, u32 Value)
{
    u32 offset = (u32)(Addr - MOCK_BASE);
    u32 index = offset >> 2;

    if (index >= 8U) {
        return;
    }

    switch (offset) {
    case 0x00U:
    case 0x08U:
        regs[index] = Value;
        break;

    case 0x0CU:
        if ((Value & 0x2U) != 0U) {
            regs[1] = 0U;
        }

        if ((Value & 0x1U) != 0U) {
            if ((regs[0] & 0x1U) == 0U) {
                regs[1] = 0x4U;
                regs[4] |= 0x2U;
            } else if (timeout_mode == 0U) {
                regs[1] = 0x2U;
                regs[4] |= 0x1U;
            }
        }
        break;

    case 0x10U:
        regs[4] &= ~Value;
        break;

    default:
        regs[index] = Value;
        break;
    }
}

#include "uart_tx_driver.c"

static int check(int cond, const char *name)
{
    if (!cond) {
        printf("FAIL: %s\n", name);
        return 1;
    }

    printf("PASS: %s\n", name);
    return 0;
}

static void reset_mock(void)
{
    memset(regs, 0, sizeof(regs));
    regs[5] = 868U;
    regs[6] = UARTTX_VERSION_VALUE;
    regs[7] = UARTTX_ID_VALUE;
    timeout_mode = 0U;
}

int main(void)
{
    UartTxDrv drv;
    int rc;
    int errors = 0;

    reset_mock();

    rc = UartTxDrv_Initialize(&drv, MOCK_BASE);
    errors += check(rc == UARTTXDRV_OK, "UART Initialize");

    rc = UartTxDrv_SendBlocking(&drv, 0x55U, 100U);
    errors += check(rc == UARTTXDRV_OK, "UART SendBlocking");
    errors += check((regs[2] & 0xFFU) == 0x55U, "UART TX_DATA");

    rc = UartTxDrv_Clear(&drv);
    errors += check(rc == UARTTXDRV_OK, "UART Clear");
    errors += check(regs[1] == 0U, "UART STATUS clear");
    errors += check(regs[4] == 0U, "UART IRQ clear");

    reset_mock();
    rc = UartTxDrv_Initialize(&drv, MOCK_BASE);
    timeout_mode = 1U;
    rc = UartTxDrv_SendBlocking(&drv, 0xA5U, 4U);
    errors += check(rc == UARTTXDRV_ERR_TIMEOUT, "UART Timeout");

    if (errors == 0) {
        printf("SOC18 UART DRIVER MOCK TEST: PASS\n");
        return 0;
    }

    printf("SOC18 UART DRIVER MOCK TEST: FAIL (%d)\n", errors);
    return 1;
}
