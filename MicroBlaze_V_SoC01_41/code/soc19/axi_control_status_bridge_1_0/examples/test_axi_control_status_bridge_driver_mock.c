#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef uint32_t u32;
typedef uintptr_t UINTPTR;

#define MOCK_BASE 0x40000000U

static u32 regs[9];

static u32 process_value(u32 input, u32 control)
{
    switch (control & 0x3U) {
    case 0U:
        return input;
    case 1U:
        return input + 1U;
    case 2U:
        return input << 1;
    default:
        return ~input;
    }
}

u32 Xil_In32(UINTPTR Addr)
{
    u32 index = (u32)(Addr - MOCK_BASE) >> 2;

    if (index < 9U) {
        return regs[index];
    }

    return 0U;
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
        regs[0] = Value;
        break;

    case 0x0CU:
        regs[3] = Value;
        break;

    case 0x10U:
        if ((Value & 0x4U) != 0U) {
            regs[2] &= ~0x8U;
        }

        if ((Value & 0x2U) != 0U) {
            if ((regs[2] & 0x4U) == 0U) {
                regs[2] |= 0x8U;
                regs[6] |= 0x4U;
            } else {
                regs[2] &= ~0x4U;
            }
        }

        if ((Value & 0x1U) != 0U) {
            if ((regs[2] & 0x2U) != 0U) {
                regs[2] |= 0x8U;
                regs[6] |= 0x4U;
            } else {
                // Mock endpoint accepts immediately and produces immediately.
                regs[2] |= 0x1U;
                regs[6] |= 0x1U;

                regs[5] = process_value(regs[3], regs[0]);
                regs[2] |= 0x4U;
                regs[6] |= 0x2U;
            }
        }
        break;

    case 0x18U:
        regs[6] &= ~Value;
        break;

    default:
        regs[index] = Value;
        break;
    }
}

#include "axi_control_status_bridge_driver.c"

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

    // IN_READY = 1
    regs[2] = CSB_BRIDGE_IN_READY_MASK;
    regs[7] = CSB_VERSION_VALUE;
    regs[8] = CSB_ID_VALUE;
}

int main(void)
{
    CsbDrv drv;
    u32 output;
    u32 events;
    int rc;
    int errors = 0;

    reset_mock();

    rc = CsbDrv_Initialize(&drv, MOCK_BASE);
    errors += check(rc == CSBDRV_OK, "CSB Initialize");

    rc = CsbDrv_RunBlocking(
        &drv,
        1U,
        9U,
        100U,
        &output
    );
    errors += check(rc == CSBDRV_OK, "CSB RunBlocking ADD1");
    errors += check(output == 10U, "CSB output 9 -> 10");

    rc = CsbDrv_GetEvents(&drv, &events);
    errors += check(rc == CSBDRV_OK, "CSB GetEvents");
    errors += check(
        (events & 0x3U) == 0x3U,
        "CSB input/output events"
    );

    rc = CsbDrv_GetOutput(&drv, &output);
    errors += check(
        rc == CSBDRV_ERR_NO_OUTPUT,
        "CSB output already popped by RunBlocking"
    );

    // Force one pending input and check software-side BUSY protection.
    regs[2] |= CSB_BRIDGE_IN_PENDING_MASK;
    rc = CsbDrv_Submit(&drv, 0x1234U);
    errors += check(rc == CSBDRV_ERR_BUSY, "CSB pending input BUSY");
    regs[2] &= ~CSB_BRIDGE_IN_PENDING_MASK;

    // Force bridge error and verify driver sees HW error.
    regs[2] |= CSB_BRIDGE_ERROR_MASK;
    rc = CsbDrv_Submit(&drv, 0x55U);
    errors += check(rc == CSBDRV_ERR_HW, "CSB hardware error");
    regs[2] &= ~CSB_BRIDGE_ERROR_MASK;

    if (errors == 0) {
        printf("SOC19 BRIDGE DRIVER MOCK TEST: PASS\n");
        return 0;
    }

    printf("SOC19 BRIDGE DRIVER MOCK TEST: FAIL (%d)\n", errors);
    return 1;
}
