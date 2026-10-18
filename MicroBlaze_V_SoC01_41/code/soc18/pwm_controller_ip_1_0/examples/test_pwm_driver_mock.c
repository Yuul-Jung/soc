#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef uint32_t u32;
typedef uintptr_t UINTPTR;

#define MOCK_BASE 0x30000000U

static u32 regs[9];

u32 Xil_In32(UINTPTR Addr)
{
    u32 index = (u32)(Addr - MOCK_BASE) >> 2;
    return (index < 9U) ? regs[index] : 0U;
}

void Xil_Out32(UINTPTR Addr, u32 Value)
{
    u32 offset = (u32)(Addr - MOCK_BASE);
    u32 index = offset >> 2;

    if (index >= 9U) {
        return;
    }

    switch (offset) {
    case 0x00U:
    case 0x04U:
    case 0x08U:
        regs[index] = Value;
        break;

    case 0x0CU:
        if ((Value & 0x2U) != 0U) {
            regs[4] &= ~0x2U;
        }

        if ((Value & 0x1U) != 0U) {
            if ((regs[1] == 0U) || (regs[2] > regs[1])) {
                regs[4] |= 0x2U;
            } else {
                regs[5] = regs[1];
                regs[6] = regs[2];
                regs[4] = ((regs[0] & 0x1U) != 0U) ? 0x1U : 0x0U;
            }
        }
        break;

    default:
        regs[index] = Value;
        break;
    }
}

#include "pwm_driver.c"

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
    regs[5] = 1000U;
    regs[6] = 500U;
    regs[7] = PWM_ID_VALUE;
    regs[8] = PWM_VERSION_VALUE;
}

int main(void)
{
    PwmDrv drv;
    int rc;
    int errors = 0;

    reset_mock();

    rc = PwmDrv_Initialize(&drv, MOCK_BASE);
    errors += check(rc == PWMDRV_OK, "PWM Initialize");

    rc = PwmDrv_Configure(&drv, 1000U, 250U, 1U, 0U);
    errors += check(rc == PWMDRV_OK, "PWM Configure 25%");
    errors += check(regs[5] == 1000U, "PWM active period");
    errors += check(regs[6] == 250U, "PWM active duty");
    errors += check((regs[4] & 0x1U) != 0U, "PWM active");

    rc = PwmDrv_Configure(&drv, 100U, 101U, 1U, 0U);
    errors += check(rc == PWMDRV_ERR_PARAM, "PWM invalid duty");

    rc = PwmDrv_Disable(&drv);
    errors += check(rc == PWMDRV_OK, "PWM Disable");
    errors += check((regs[4] & 0x1U) == 0U, "PWM inactive");

    if (errors == 0) {
        printf("SOC18 PWM DRIVER MOCK TEST: PASS\n");
        return 0;
    }

    printf("SOC18 PWM DRIVER MOCK TEST: FAIL (%d)\n", errors);
    return 1;
}
