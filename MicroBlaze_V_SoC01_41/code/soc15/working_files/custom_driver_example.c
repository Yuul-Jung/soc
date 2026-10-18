#include "custom_driver.h"

/*
 * SoC 15 - Reusable driver example
 *
 * BaseAddress must come from the actual platform/xparameters.h
 * or from the caller that owns the hardware configuration.
 */

#define CUSTOM_EXAMPLE_POLL_LIMIT  1000000U

int CustomDrv_Example(UINTPTR BaseAddress)
{
    CustomDrv custom;
    CustomDrv_Status status;
    CustomDrv_IrqStatus irq_status;

    u32 result_value;
    int result;

    result = CustomDrv_Initialize(
        &custom,
        BaseAddress
    );
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    result = CustomDrv_SelfTest(&custom);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    /*
     * Example:
     * mode = ADD1
     * input = 0x00000009
     * expected output = 0x0000000A
     */
    result = CustomDrv_RunBlocking(
        &custom,
        CUSTOMDRV_MODE_ADD1,
        0x00000009U,
        CUSTOM_EXAMPLE_POLL_LIMIT,
        &result_value
    );
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    if (result_value != 0x0000000AU) {
        return CUSTOMDRV_ERR_HW;
    }

    /*
     * Successful RunBlocking() intentionally leaves DONE
     * and DONE IRQ latched so software can inspect them.
     */
    result = CustomDrv_GetStatus(
        &custom,
        &status
    );
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    if ((status.Done == 0U) ||
        (status.Busy != 0U) ||
        (status.Error != 0U)) {
        return CUSTOMDRV_ERR_HW;
    }

    result = CustomDrv_GetIrqStatus(
        &custom,
        &irq_status
    );
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    if (irq_status.Done == 0U) {
        return CUSTOMDRV_ERR_HW;
    }

    /*
     * Clear retained state explicitly after inspection.
     */
    result = CustomDrv_ClearStatus(&custom);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    result = CustomDrv_ClearAllIrq(&custom);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    return CUSTOMDRV_OK;
}
