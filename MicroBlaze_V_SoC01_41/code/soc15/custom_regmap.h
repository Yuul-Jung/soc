#ifndef CUSTOM_REGMAP_H
#define CUSTOM_REGMAP_H

#include "xil_io.h"
#include "xil_types.h"

/*
 * SoC 11 - Custom Register Map example
 *
 * Base address is assigned by Vivado Address Editor.
 * This file defines only offsets, fields and access helpers.
 */

/* Register offsets */
#define CUSTOM_CONTROL_OFFSET        0x00U
#define CUSTOM_STATUS_OFFSET         0x04U
#define CUSTOM_COMMAND_OFFSET        0x08U
#define CUSTOM_IRQ_STATUS_OFFSET     0x0CU
#define CUSTOM_DATA_IN_OFFSET        0x10U
#define CUSTOM_DATA_OUT_OFFSET       0x14U
#define CUSTOM_VERSION_OFFSET        0x18U
#define CUSTOM_ID_OFFSET             0x1CU

/* CONTROL register fields: RW */
#define CUSTOM_CONTROL_ENABLE_MASK   0x00000001U
#define CUSTOM_CONTROL_MODE_MASK     0x00000006U
#define CUSTOM_CONTROL_MODE_SHIFT    1U

/* STATUS register fields: RO */
#define CUSTOM_STATUS_BUSY_MASK      0x00000001U
#define CUSTOM_STATUS_DONE_MASK      0x00000002U
#define CUSTOM_STATUS_ERROR_MASK     0x00000004U

/* COMMAND register fields: W1P */
#define CUSTOM_COMMAND_START_MASK    0x00000001U
#define CUSTOM_COMMAND_CLEAR_MASK    0x00000002U

/* IRQ_STATUS register fields: W1C */
#define CUSTOM_IRQ_DONE_MASK         0x00000001U
#define CUSTOM_IRQ_ERROR_MASK        0x00000002U

/* Fixed read-only values */
#define CUSTOM_VERSION_VALUE         0x00010000U  /* v1.0 */
#define CUSTOM_ID_VALUE              0x524D4150U  /* ASCII "RMAP" */

#define Custom_ReadReg(BaseAddress, RegOffset) \
    Xil_In32((BaseAddress) + (RegOffset))

#define Custom_WriteReg(BaseAddress, RegOffset, Data) \
    Xil_Out32((BaseAddress) + (RegOffset), (Data))

static inline void Custom_SetEnable(UINTPTR BaseAddress, u32 Enable)
{
    u32 value;

    value = Custom_ReadReg(BaseAddress, CUSTOM_CONTROL_OFFSET);

    if (Enable != 0U) {
        value |= CUSTOM_CONTROL_ENABLE_MASK;
    } else {
        value &= ~CUSTOM_CONTROL_ENABLE_MASK;
    }

    Custom_WriteReg(BaseAddress, CUSTOM_CONTROL_OFFSET, value);
}

static inline void Custom_SetMode(UINTPTR BaseAddress, u32 Mode)
{
    u32 value;

    value = Custom_ReadReg(BaseAddress, CUSTOM_CONTROL_OFFSET);
    value &= ~CUSTOM_CONTROL_MODE_MASK;
    value |= (Mode << CUSTOM_CONTROL_MODE_SHIFT) & CUSTOM_CONTROL_MODE_MASK;

    Custom_WriteReg(BaseAddress, CUSTOM_CONTROL_OFFSET, value);
}

static inline void Custom_Start(UINTPTR BaseAddress)
{
    /* W1P: write 1 to generate one-cycle start pulse */
    Custom_WriteReg(
        BaseAddress,
        CUSTOM_COMMAND_OFFSET,
        CUSTOM_COMMAND_START_MASK
    );
}

static inline void Custom_ClearDoneIrq(UINTPTR BaseAddress)
{
    /* W1C: writing 1 clears only DONE IRQ */
    Custom_WriteReg(
        BaseAddress,
        CUSTOM_IRQ_STATUS_OFFSET,
        CUSTOM_IRQ_DONE_MASK
    );
}

#endif
