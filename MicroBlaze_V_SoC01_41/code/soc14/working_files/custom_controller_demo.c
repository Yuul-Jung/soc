#include "custom_regmap.h"
#include "xstatus.h"
#include "xil_types.h"

/*
 * SoC 14 - Register Bank + RTL Controller software demo
 *
 * Hardware operation modes:
 *   mode 0 : pass-through
 *   mode 1 : input + 1
 *   mode 2 : input << 1
 *   mode 3 : bitwise NOT
 *
 * BaseAddress is supplied by the caller.
 */

#define CUSTOM_POLL_LIMIT  1000000U

static void Custom_ClearStatusAndIrq(UINTPTR BaseAddress)
{
    /* COMMAND.CLEAR clears controller done/error status. */
    Custom_WriteReg(
        BaseAddress,
        CUSTOM_COMMAND_OFFSET,
        CUSTOM_COMMAND_CLEAR_MASK
    );

    /* IRQ_STATUS is independent and must be cleared by W1C. */
    Custom_WriteReg(
        BaseAddress,
        CUSTOM_IRQ_STATUS_OFFSET,
        CUSTOM_IRQ_DONE_MASK | CUSTOM_IRQ_ERROR_MASK
    );
}

int Custom_RunOperation(
    UINTPTR BaseAddress,
    u32 Mode,
    u32 InputValue,
    u32 *OutputValue
)
{
    u32 poll_count;
    u32 status;

    if (OutputValue == 0) {
        return XST_FAILURE;
    }

    Custom_ClearStatusAndIrq(BaseAddress);

    Custom_SetEnable(BaseAddress, 1U);
    Custom_SetMode(BaseAddress, Mode);

    Custom_WriteReg(
        BaseAddress,
        CUSTOM_DATA_IN_OFFSET,
        InputValue
    );

    Custom_Start(BaseAddress);

    for (poll_count = 0U;
         poll_count < CUSTOM_POLL_LIMIT;
         poll_count++) {

        status = Custom_ReadReg(
            BaseAddress,
            CUSTOM_STATUS_OFFSET
        );

        if ((status & CUSTOM_STATUS_ERROR_MASK) != 0U) {
            return XST_FAILURE;
        }

        if ((status & CUSTOM_STATUS_DONE_MASK) != 0U) {
            *OutputValue = Custom_ReadReg(
                BaseAddress,
                CUSTOM_DATA_OUT_OFFSET
            );

            /* Clear retained controller status and DONE IRQ. */
            Custom_WriteReg(
                BaseAddress,
                CUSTOM_COMMAND_OFFSET,
                CUSTOM_COMMAND_CLEAR_MASK
            );

            Custom_ClearDoneIrq(BaseAddress);

            return XST_SUCCESS;
        }
    }

    return XST_FAILURE;
}
