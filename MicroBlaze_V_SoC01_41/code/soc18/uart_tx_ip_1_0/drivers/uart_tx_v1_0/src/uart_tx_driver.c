#include "uart_tx_driver.h"

static int UartTxDrv_CheckReady(const UartTxDrv *InstancePtr)
{
    if (InstancePtr == 0) {
        return UARTTXDRV_ERR_PARAM;
    }

    if (InstancePtr->IsReady != UARTTXDRV_READY_MAGIC) {
        return UARTTXDRV_ERR_NOT_READY;
    }

    return UARTTXDRV_OK;
}

int UartTxDrv_Initialize(UartTxDrv *InstancePtr, UINTPTR BaseAddress)
{
    if (InstancePtr == 0) {
        return UARTTXDRV_ERR_PARAM;
    }

    if ((BaseAddress & 0x3U) != 0U) {
        return UARTTXDRV_ERR_PARAM;
    }

    InstancePtr->BaseAddress = BaseAddress;
    InstancePtr->IsReady = 0U;

    if (UartTx_ReadReg(BaseAddress, UARTTX_ID_OFFSET) != UARTTX_ID_VALUE) {
        return UARTTXDRV_ERR_ID;
    }

    if (UartTx_ReadReg(BaseAddress, UARTTX_VERSION_OFFSET) != UARTTX_VERSION_VALUE) {
        return UARTTXDRV_ERR_ID;
    }

    InstancePtr->IsReady = UARTTXDRV_READY_MAGIC;
    return UARTTXDRV_OK;
}

int UartTxDrv_Enable(UartTxDrv *InstancePtr, u32 Enable)
{
    int rc;

    rc = UartTxDrv_CheckReady(InstancePtr);
    if (rc != UARTTXDRV_OK) {
        return rc;
    }

    UartTx_WriteReg(
        InstancePtr->BaseAddress,
        UARTTX_CONTROL_OFFSET,
        (Enable != 0U) ? UARTTX_CONTROL_ENABLE_MASK : 0U
    );

    return UARTTXDRV_OK;
}

int UartTxDrv_IsBusy(UartTxDrv *InstancePtr)
{
    int rc;
    u32 status;

    rc = UartTxDrv_CheckReady(InstancePtr);
    if (rc != UARTTXDRV_OK) {
        return rc;
    }

    status = UartTx_ReadReg(
        InstancePtr->BaseAddress,
        UARTTX_STATUS_OFFSET
    );

    return ((status & UARTTX_STATUS_BUSY_MASK) != 0U) ? 1 : 0;
}

int UartTxDrv_Clear(UartTxDrv *InstancePtr)
{
    int rc;

    rc = UartTxDrv_CheckReady(InstancePtr);
    if (rc != UARTTXDRV_OK) {
        return rc;
    }

    UartTx_WriteReg(
        InstancePtr->BaseAddress,
        UARTTX_COMMAND_OFFSET,
        UARTTX_COMMAND_CLEAR_MASK
    );

    UartTx_WriteReg(
        InstancePtr->BaseAddress,
        UARTTX_IRQ_STATUS_OFFSET,
        UARTTX_IRQ_DONE_MASK | UARTTX_IRQ_ERROR_MASK
    );

    return UARTTXDRV_OK;
}

int UartTxDrv_SendBlocking(
    UartTxDrv *InstancePtr,
    u8 Data,
    u32 PollLimit
)
{
    u32 k;
    u32 status;
    int rc;

    rc = UartTxDrv_CheckReady(InstancePtr);
    if (rc != UARTTXDRV_OK) {
        return rc;
    }

    if (PollLimit == 0U) {
        return UARTTXDRV_ERR_PARAM;
    }

    status = UartTx_ReadReg(
        InstancePtr->BaseAddress,
        UARTTX_STATUS_OFFSET
    );

    if ((status & UARTTX_STATUS_BUSY_MASK) != 0U) {
        return UARTTXDRV_ERR_BUSY;
    }

    rc = UartTxDrv_Clear(InstancePtr);
    if (rc != UARTTXDRV_OK) {
        return rc;
    }

    rc = UartTxDrv_Enable(InstancePtr, 1U);
    if (rc != UARTTXDRV_OK) {
        return rc;
    }

    UartTx_WriteReg(
        InstancePtr->BaseAddress,
        UARTTX_TX_DATA_OFFSET,
        (u32)Data
    );

    UartTx_WriteReg(
        InstancePtr->BaseAddress,
        UARTTX_COMMAND_OFFSET,
        UARTTX_COMMAND_SEND_MASK
    );

    for (k = 0U; k < PollLimit; k++) {
        status = UartTx_ReadReg(
            InstancePtr->BaseAddress,
            UARTTX_STATUS_OFFSET
        );

        if ((status & UARTTX_STATUS_ERROR_MASK) != 0U) {
            return UARTTXDRV_ERR_HW;
        }

        if ((status & UARTTX_STATUS_DONE_MASK) != 0U) {
            return UARTTXDRV_OK;
        }
    }

    return UARTTXDRV_ERR_TIMEOUT;
}
