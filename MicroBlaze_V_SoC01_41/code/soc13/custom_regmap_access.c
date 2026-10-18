#include "custom_regmap.h"
#include "xil_types.h"

/*
 * SoC 13 - AXI Register Read / Write Path Demo
 *
 * BaseAddress is supplied by the caller.
 * This file does not hard-code a Vivado-assigned AXI base address.
 *
 * The purpose is to show:
 *   C helper -> Xil_In32 / Xil_Out32
 *   -> MicroBlaze V load/store
 *   -> AXI4-Lite transaction
 *   -> AXI adapter
 *   -> custom_register_bank
 */

typedef struct {
    u32 control_readback;
    u32 status;
    u32 data_in_readback;
    u32 data_out;
    u32 irq_status;
    u32 version;
    u32 id;
} CustomPathSnapshot;

void Custom_RegisterPathDemo(
    UINTPTR BaseAddress,
    CustomPathSnapshot *Snapshot
)
{
    u32 control_value;

    /*
     * WRITE #1
     * CONTROL[0]   = ENABLE
     * CONTROL[2:1] = MODE
     *
     * MODE = 2, ENABLE = 1
     * CONTROL data -> 0b101 -> 0x00000005
     */
    control_value =
        CUSTOM_CONTROL_ENABLE_MASK |
        (2U << CUSTOM_CONTROL_MODE_SHIFT);

    Custom_WriteReg(
        BaseAddress,
        CUSTOM_CONTROL_OFFSET,
        control_value
    );

    /*
     * READ #1
     * Read CONTROL back through the AXI read path.
     */
    Snapshot->control_readback =
        Custom_ReadReg(BaseAddress, CUSTOM_CONTROL_OFFSET);

    /*
     * WRITE #2
     * DATA_IN is a retained RW register.
     */
    Custom_WriteReg(
        BaseAddress,
        CUSTOM_DATA_IN_OFFSET,
        0x12345678U
    );

    Snapshot->data_in_readback =
        Custom_ReadReg(BaseAddress, CUSTOM_DATA_IN_OFFSET);

    /*
     * WRITE #3
     * COMMAND is W1P.
     * Writing bit0 = 1 generates start_pulse_o for one clock.
     * No retained command state remains afterward.
     */
    Custom_Start(BaseAddress);

    /*
     * READ hardware-driven registers.
     * STATUS / DATA_OUT values depend on the connected controller/datapath.
     */
    Snapshot->status =
        Custom_ReadReg(BaseAddress, CUSTOM_STATUS_OFFSET);

    Snapshot->data_out =
        Custom_ReadReg(BaseAddress, CUSTOM_DATA_OUT_OFFSET);

    Snapshot->irq_status =
        Custom_ReadReg(BaseAddress, CUSTOM_IRQ_STATUS_OFFSET);

    /*
     * If DONE IRQ is pending, clear only that W1C bit.
     */
    if ((Snapshot->irq_status & CUSTOM_IRQ_DONE_MASK) != 0U) {
        Custom_ClearDoneIrq(BaseAddress);
    }

    /*
     * Fixed RO identification registers.
     */
    Snapshot->version =
        Custom_ReadReg(BaseAddress, CUSTOM_VERSION_OFFSET);

    Snapshot->id =
        Custom_ReadReg(BaseAddress, CUSTOM_ID_OFFSET);
}
