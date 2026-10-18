#ifndef UART_TX_REGMAP_H
#define UART_TX_REGMAP_H

#include "xil_io.h"
#include "xil_types.h"

#define UARTTX_CONTROL_OFFSET        0x00U
#define UARTTX_STATUS_OFFSET         0x04U
#define UARTTX_TX_DATA_OFFSET        0x08U
#define UARTTX_COMMAND_OFFSET        0x0CU
#define UARTTX_IRQ_STATUS_OFFSET     0x10U
#define UARTTX_BAUD_DIV_OFFSET       0x14U
#define UARTTX_VERSION_OFFSET        0x18U
#define UARTTX_ID_OFFSET             0x1CU

#define UARTTX_CONTROL_ENABLE_MASK   0x00000001U

#define UARTTX_STATUS_BUSY_MASK      0x00000001U
#define UARTTX_STATUS_DONE_MASK      0x00000002U
#define UARTTX_STATUS_ERROR_MASK     0x00000004U

#define UARTTX_COMMAND_SEND_MASK     0x00000001U
#define UARTTX_COMMAND_CLEAR_MASK    0x00000002U

#define UARTTX_IRQ_DONE_MASK         0x00000001U
#define UARTTX_IRQ_ERROR_MASK        0x00000002U

#define UARTTX_VERSION_VALUE         0x00010000U
#define UARTTX_ID_VALUE              0x55545831U /* ASCII "UTX1" */

#define UartTx_ReadReg(BaseAddress, Offset) \
    Xil_In32((BaseAddress) + (Offset))

#define UartTx_WriteReg(BaseAddress, Offset, Data) \
    Xil_Out32((BaseAddress) + (Offset), (Data))

#endif
