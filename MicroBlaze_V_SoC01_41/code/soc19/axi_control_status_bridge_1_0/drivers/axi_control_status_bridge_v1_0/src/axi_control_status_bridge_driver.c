#include "axi_control_status_bridge_driver.h"

static int CsbDrv_CheckReady(const CsbDrv *InstancePtr)
{
    if (InstancePtr == 0) {
        return CSBDRV_ERR_PARAM;
    }

    if (InstancePtr->IsReady != CSBDRV_READY_MAGIC) {
        return CSBDRV_ERR_NOT_READY;
    }

    return CSBDRV_OK;
}

int CsbDrv_Initialize(CsbDrv *InstancePtr, UINTPTR BaseAddress)
{
    if (InstancePtr == 0) {
        return CSBDRV_ERR_PARAM;
    }

    if ((BaseAddress & 0x3U) != 0U) {
        return CSBDRV_ERR_PARAM;
    }

    InstancePtr->BaseAddress = BaseAddress;
    InstancePtr->IsReady = 0U;

    if (Csb_ReadReg(BaseAddress, CSB_ID_OFFSET) != CSB_ID_VALUE) {
        return CSBDRV_ERR_ID;
    }

    if (Csb_ReadReg(BaseAddress, CSB_VERSION_OFFSET) != CSB_VERSION_VALUE) {
        return CSBDRV_ERR_ID;
    }

    InstancePtr->IsReady = CSBDRV_READY_MAGIC;
    return CSBDRV_OK;
}

int CsbDrv_SetControl(CsbDrv *InstancePtr, u32 ControlWord)
{
    int rc = CsbDrv_CheckReady(InstancePtr);

    if (rc != CSBDRV_OK) {
        return rc;
    }

    Csb_WriteReg(
        InstancePtr->BaseAddress,
        CSB_CONTROL_OFFSET,
        ControlWord
    );

    return CSBDRV_OK;
}

int CsbDrv_GetCoreStatus(CsbDrv *InstancePtr, u32 *StatusWord)
{
    int rc = CsbDrv_CheckReady(InstancePtr);

    if (rc != CSBDRV_OK) {
        return rc;
    }

    if (StatusWord == 0) {
        return CSBDRV_ERR_PARAM;
    }

    *StatusWord = Csb_ReadReg(
        InstancePtr->BaseAddress,
        CSB_CORE_STATUS_OFFSET
    );

    return CSBDRV_OK;
}

int CsbDrv_GetBridgeStatus(CsbDrv *InstancePtr, u32 *StatusWord)
{
    int rc = CsbDrv_CheckReady(InstancePtr);

    if (rc != CSBDRV_OK) {
        return rc;
    }

    if (StatusWord == 0) {
        return CSBDRV_ERR_PARAM;
    }

    *StatusWord = Csb_ReadReg(
        InstancePtr->BaseAddress,
        CSB_BRIDGE_STATUS_OFFSET
    );

    return CSBDRV_OK;
}

int CsbDrv_GetEvents(CsbDrv *InstancePtr, u32 *EventWord)
{
    int rc = CsbDrv_CheckReady(InstancePtr);

    if (rc != CSBDRV_OK) {
        return rc;
    }

    if (EventWord == 0) {
        return CSBDRV_ERR_PARAM;
    }

    *EventWord = Csb_ReadReg(
        InstancePtr->BaseAddress,
        CSB_EVENT_STATUS_OFFSET
    );

    return CSBDRV_OK;
}

int CsbDrv_ClearEvents(CsbDrv *InstancePtr, u32 EventMask)
{
    int rc = CsbDrv_CheckReady(InstancePtr);
    u32 valid_mask;

    if (rc != CSBDRV_OK) {
        return rc;
    }

    valid_mask =
        CSB_EVENT_IN_ACCEPTED_MASK |
        CSB_EVENT_OUT_CAPTURED_MASK |
        CSB_EVENT_ERROR_MASK;

    Csb_WriteReg(
        InstancePtr->BaseAddress,
        CSB_EVENT_STATUS_OFFSET,
        EventMask & valid_mask
    );

    return CSBDRV_OK;
}

int CsbDrv_ClearError(CsbDrv *InstancePtr)
{
    int rc = CsbDrv_CheckReady(InstancePtr);

    if (rc != CSBDRV_OK) {
        return rc;
    }

    Csb_WriteReg(
        InstancePtr->BaseAddress,
        CSB_COMMAND_OFFSET,
        CSB_COMMAND_CLEAR_ERROR_MASK
    );

    return CSBDRV_OK;
}

int CsbDrv_Submit(CsbDrv *InstancePtr, u32 InputWord)
{
    int rc;
    u32 status;

    rc = CsbDrv_GetBridgeStatus(InstancePtr, &status);
    if (rc != CSBDRV_OK) {
        return rc;
    }

    if ((status & CSB_BRIDGE_ERROR_MASK) != 0U) {
        return CSBDRV_ERR_HW;
    }

    if ((status & CSB_BRIDGE_IN_PENDING_MASK) != 0U) {
        return CSBDRV_ERR_BUSY;
    }

    Csb_WriteReg(
        InstancePtr->BaseAddress,
        CSB_IN_DATA_OFFSET,
        InputWord
    );

    Csb_WriteReg(
        InstancePtr->BaseAddress,
        CSB_COMMAND_OFFSET,
        CSB_COMMAND_SUBMIT_MASK
    );

    return CSBDRV_OK;
}

int CsbDrv_OutputAvailable(CsbDrv *InstancePtr)
{
    int rc;
    u32 status;

    rc = CsbDrv_GetBridgeStatus(InstancePtr, &status);
    if (rc != CSBDRV_OK) {
        return rc;
    }

    if ((status & CSB_BRIDGE_ERROR_MASK) != 0U) {
        return CSBDRV_ERR_HW;
    }

    return ((status & CSB_BRIDGE_OUT_PENDING_MASK) != 0U) ? 1 : 0;
}

int CsbDrv_GetOutput(CsbDrv *InstancePtr, u32 *OutputWord)
{
    int available;

    if (OutputWord == 0) {
        return CSBDRV_ERR_PARAM;
    }

    available = CsbDrv_OutputAvailable(InstancePtr);
    if (available < 0) {
        return available;
    }

    if (available == 0) {
        return CSBDRV_ERR_NO_OUTPUT;
    }

    *OutputWord = Csb_ReadReg(
        InstancePtr->BaseAddress,
        CSB_OUT_DATA_OFFSET
    );

    return CSBDRV_OK;
}

int CsbDrv_PopOutput(CsbDrv *InstancePtr)
{
    int available;

    available = CsbDrv_OutputAvailable(InstancePtr);
    if (available < 0) {
        return available;
    }

    if (available == 0) {
        return CSBDRV_ERR_NO_OUTPUT;
    }

    Csb_WriteReg(
        InstancePtr->BaseAddress,
        CSB_COMMAND_OFFSET,
        CSB_COMMAND_POP_OUT_MASK
    );

    return CSBDRV_OK;
}

int CsbDrv_RunBlocking(
    CsbDrv *InstancePtr,
    u32 ControlWord,
    u32 InputWord,
    u32 PollLimit,
    u32 *OutputWord
)
{
    u32 k;
    int rc;
    int available;

    if ((OutputWord == 0) || (PollLimit == 0U)) {
        return CSBDRV_ERR_PARAM;
    }

    rc = CsbDrv_ClearError(InstancePtr);
    if (rc != CSBDRV_OK) {
        return rc;
    }

    rc = CsbDrv_ClearEvents(
        InstancePtr,
        CSB_EVENT_IN_ACCEPTED_MASK |
        CSB_EVENT_OUT_CAPTURED_MASK |
        CSB_EVENT_ERROR_MASK
    );
    if (rc != CSBDRV_OK) {
        return rc;
    }

    rc = CsbDrv_SetControl(
        InstancePtr,
        ControlWord
    );
    if (rc != CSBDRV_OK) {
        return rc;
    }

    rc = CsbDrv_Submit(
        InstancePtr,
        InputWord
    );
    if (rc != CSBDRV_OK) {
        return rc;
    }

    for (k = 0U; k < PollLimit; k++) {
        available = CsbDrv_OutputAvailable(InstancePtr);

        if (available < 0) {
            return available;
        }

        if (available != 0) {
            rc = CsbDrv_GetOutput(
                InstancePtr,
                OutputWord
            );
            if (rc != CSBDRV_OK) {
                return rc;
            }

            return CsbDrv_PopOutput(InstancePtr);
        }
    }

    return CSBDRV_ERR_TIMEOUT;
}
