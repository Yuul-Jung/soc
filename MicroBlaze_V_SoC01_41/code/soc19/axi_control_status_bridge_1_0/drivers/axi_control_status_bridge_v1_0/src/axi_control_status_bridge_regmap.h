#ifndef AXI_CONTROL_STATUS_BRIDGE_REGMAP_H
#define AXI_CONTROL_STATUS_BRIDGE_REGMAP_H

#include "xil_io.h"
#include "xil_types.h"

#define CSB_CONTROL_OFFSET             0x00U
#define CSB_CORE_STATUS_OFFSET         0x04U
#define CSB_BRIDGE_STATUS_OFFSET       0x08U
#define CSB_IN_DATA_OFFSET             0x0CU
#define CSB_COMMAND_OFFSET             0x10U
#define CSB_OUT_DATA_OFFSET            0x14U
#define CSB_EVENT_STATUS_OFFSET        0x18U
#define CSB_VERSION_OFFSET             0x1CU
#define CSB_ID_OFFSET                  0x20U

#define CSB_BRIDGE_IN_READY_MASK       0x00000001U
#define CSB_BRIDGE_IN_PENDING_MASK     0x00000002U
#define CSB_BRIDGE_OUT_PENDING_MASK    0x00000004U
#define CSB_BRIDGE_ERROR_MASK          0x00000008U
#define CSB_BRIDGE_ENDPOINT_OUT_MASK   0x00000010U

#define CSB_COMMAND_SUBMIT_MASK        0x00000001U
#define CSB_COMMAND_POP_OUT_MASK       0x00000002U
#define CSB_COMMAND_CLEAR_ERROR_MASK   0x00000004U

#define CSB_EVENT_IN_ACCEPTED_MASK     0x00000001U
#define CSB_EVENT_OUT_CAPTURED_MASK    0x00000002U
#define CSB_EVENT_ERROR_MASK           0x00000004U

#define CSB_VERSION_VALUE              0x00010000U
#define CSB_ID_VALUE                   0x43534231U /* ASCII "CSB1" */

#define Csb_ReadReg(BaseAddress, Offset) \
    Xil_In32((BaseAddress) + (Offset))

#define Csb_WriteReg(BaseAddress, Offset, Data) \
    Xil_Out32((BaseAddress) + (Offset), (Data))

#endif
