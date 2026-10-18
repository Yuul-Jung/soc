#include <stdint.h>
#include <stdio.h>
#include <string.h>

typedef uint8_t  u8;
typedef uint16_t u16;
typedef uint32_t u32;
typedef uintptr_t UINTPTR;

#define MOCK_BASE  0x10000000U

static u32 mock_regs[8];
static u32 mock_force_timeout = 0U;

static u32 Mock_Process(u32 input, u32 mode)
{
    switch (mode & 0x3U) {
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
    u32 offset;
    u32 index;

    offset = (u32)(Addr - MOCK_BASE);
    index = offset >> 2;

    if (index < 8U) {
        return mock_regs[index];
    }

    return 0U;
}

void Xil_Out32(UINTPTR Addr, u32 Value)
{
    u32 offset;
    u32 index;
    u32 control;
    u32 mode;

    offset = (u32)(Addr - MOCK_BASE);
    index = offset >> 2;

    if (index >= 8U) {
        return;
    }

    switch (offset) {
    case 0x00U:
        mock_regs[index] = Value;
        break;

    case 0x08U:
        /* COMMAND.CLEAR */
        if ((Value & 0x2U) != 0U) {
            mock_regs[1] = 0U;
        }

        /* COMMAND.START */
        if ((Value & 0x1U) != 0U) {
            control = mock_regs[0];
            mode = (control >> 1) & 0x3U;

            if ((control & 0x1U) == 0U) {
                mock_regs[1] |= 0x4U;
                mock_regs[3] |= 0x2U;
            } else if (mock_force_timeout == 0U) {
                mock_regs[1] = 0x1U;
                mock_regs[5] = Mock_Process(mock_regs[4], mode);
                mock_regs[1] = 0x2U;
                mock_regs[3] |= 0x1U;
            }
        }
        break;

    case 0x0CU:
        /* W1C */
        mock_regs[3] &= ~Value;
        break;

    case 0x10U:
        mock_regs[index] = Value;
        break;

    default:
        mock_regs[index] = Value;
        break;
    }
}

#include "custom_driver.c"

static int check(int condition, const char *name)
{
    if (!condition) {
        printf("FAIL: %s\n", name);
        return 1;
    }

    printf("PASS: %s\n", name);
    return 0;
}

static void Mock_Reset(void)
{
    memset(mock_regs, 0, sizeof(mock_regs));
    mock_regs[6] = CUSTOM_VERSION_VALUE;
    mock_regs[7] = CUSTOM_ID_VALUE;
    mock_force_timeout = 0U;
}

int main(void)
{
    CustomDrv drv;
    CustomDrv_Status status;
    CustomDrv_IrqStatus irq;
    u32 out;
    int rc;
    int errors = 0;

    Mock_Reset();

    rc = CustomDrv_Initialize(&drv, MOCK_BASE);
    errors += check(rc == CUSTOMDRV_OK, "Initialize");

    rc = CustomDrv_SelfTest(&drv);
    errors += check(rc == CUSTOMDRV_OK, "SelfTest");

    rc = CustomDrv_RunBlocking(
        &drv,
        CUSTOMDRV_MODE_ADD1,
        9U,
        100U,
        &out
    );
    errors += check(rc == CUSTOMDRV_OK, "RunBlocking ADD1");
    errors += check(out == 10U, "ADD1 result");

    rc = CustomDrv_GetStatus(&drv, &status);
    errors += check(rc == CUSTOMDRV_OK, "GetStatus");
    errors += check(status.Done == 1U, "DONE retained");
    errors += check(status.Error == 0U, "No HW error");

    rc = CustomDrv_GetIrqStatus(&drv, &irq);
    errors += check(rc == CUSTOMDRV_OK, "GetIrqStatus");
    errors += check(irq.Done == 1U, "DONE IRQ retained");

    rc = CustomDrv_ClearStatus(&drv);
    errors += check(rc == CUSTOMDRV_OK, "ClearStatus");

    rc = CustomDrv_ClearAllIrq(&drv);
    errors += check(rc == CUSTOMDRV_OK, "ClearAllIrq");

    rc = CustomDrv_GetStatus(&drv, &status);
    errors += check(status.Raw == 0U, "STATUS cleared");

    rc = CustomDrv_GetIrqStatus(&drv, &irq);
    errors += check(irq.Raw == 0U, "IRQ_STATUS cleared");

    /* Invalid mode */
    rc = CustomDrv_SetMode(&drv, (CustomDrv_Mode)4U);
    errors += check(rc == CUSTOMDRV_ERR_PARAM, "Invalid mode");

    /* Alignment error */
    rc = CustomDrv_Initialize(&drv, MOCK_BASE + 1U);
    errors += check(rc == CUSTOMDRV_ERR_PARAM, "Unaligned BaseAddress");

    /* Wrong ID */
    Mock_Reset();
    mock_regs[7] = 0xDEADBEEFU;
    rc = CustomDrv_Initialize(&drv, MOCK_BASE);
    errors += check(rc == CUSTOMDRV_ERR_ID, "ID mismatch");


    /* Version mismatch */
    Mock_Reset();
    mock_regs[6] = 0x00020000U;
    rc = CustomDrv_Initialize(&drv, MOCK_BASE);
    errors += check(rc == CUSTOMDRV_ERR_VERSION, "VERSION mismatch");

    /* Busy start rejection */
    Mock_Reset();
    rc = CustomDrv_Initialize(&drv, MOCK_BASE);
    errors += check(rc == CUSTOMDRV_OK, "Initialize before busy test");
    mock_regs[1] = CUSTOM_STATUS_BUSY_MASK;
    rc = CustomDrv_Start(&drv, 0x55AA55AAU);
    errors += check(rc == CUSTOMDRV_ERR_BUSY, "Start while busy");

    /* Hardware error returned by WaitDone */
    Mock_Reset();
    rc = CustomDrv_Initialize(&drv, MOCK_BASE);
    errors += check(rc == CUSTOMDRV_OK, "Initialize before HW error");
    rc = CustomDrv_Configure(&drv, 0U, CUSTOMDRV_MODE_PASS);
    errors += check(rc == CUSTOMDRV_OK, "Configure disabled");
    rc = CustomDrv_Start(&drv, 0x12345678U);
    errors += check(rc == CUSTOMDRV_OK, "Start disabled reaches hardware");
    rc = CustomDrv_WaitDone(&drv, 4U);
    errors += check(rc == CUSTOMDRV_ERR_HW, "Hardware error");

    /* Timeout */
    Mock_Reset();
    rc = CustomDrv_Initialize(&drv, MOCK_BASE);
    errors += check(rc == CUSTOMDRV_OK, "Initialize before timeout");
    mock_force_timeout = 1U;

    rc = CustomDrv_RunBlocking(
        &drv,
        CUSTOMDRV_MODE_PASS,
        0x12345678U,
        4U,
        &out
    );
    errors += check(rc == CUSTOMDRV_ERR_TIMEOUT, "Timeout");

    if (errors == 0) {
        printf("SOC15 CUSTOM DRIVER MOCK TEST: PASS\n");
        return 0;
    }

    printf("SOC15 CUSTOM DRIVER MOCK TEST: FAIL (%d)\n", errors);
    return 1;
}
