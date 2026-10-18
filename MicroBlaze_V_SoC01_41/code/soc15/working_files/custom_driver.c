#include "custom_driver.h"

static int CustomDrv_CheckReady(const CustomDrv *InstancePtr)
{
    if (InstancePtr == 0) {
        return CUSTOMDRV_ERR_PARAM;
    }

    if (InstancePtr->IsReady != CUSTOMDRV_READY_MAGIC) {
        return CUSTOMDRV_ERR_NOT_READY;
    }

    return CUSTOMDRV_OK;
}

static int CustomDrv_CheckMode(CustomDrv_Mode Mode)
{
    if ((u32)Mode > (u32)CUSTOMDRV_MODE_NOT) {
        return CUSTOMDRV_ERR_PARAM;
    }

    return CUSTOMDRV_OK;
}

int CustomDrv_Initialize(CustomDrv *InstancePtr, UINTPTR BaseAddress)
{
    u32 id_value;
    u32 version_value;

    if (InstancePtr == 0) {
        return CUSTOMDRV_ERR_PARAM;
    }

    if ((BaseAddress & 0x3U) != 0U) {
        return CUSTOMDRV_ERR_PARAM;
    }

    InstancePtr->BaseAddress = BaseAddress;
    InstancePtr->IsReady = 0U;

    id_value = Custom_ReadReg(
        BaseAddress,
        CUSTOM_ID_OFFSET
    );

    if (id_value != CUSTOM_ID_VALUE) {
        return CUSTOMDRV_ERR_ID;
    }

    version_value = Custom_ReadReg(
        BaseAddress,
        CUSTOM_VERSION_OFFSET
    );

    if (version_value != CUSTOM_VERSION_VALUE) {
        return CUSTOMDRV_ERR_VERSION;
    }

    InstancePtr->IsReady = CUSTOMDRV_READY_MAGIC;

    return CUSTOMDRV_OK;
}

int CustomDrv_SelfTest(CustomDrv *InstancePtr)
{
    int result;
    u32 id_value;
    u32 version_value;

    result = CustomDrv_CheckReady(InstancePtr);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    id_value = Custom_ReadReg(
        InstancePtr->BaseAddress,
        CUSTOM_ID_OFFSET
    );

    if (id_value != CUSTOM_ID_VALUE) {
        return CUSTOMDRV_ERR_ID;
    }

    version_value = Custom_ReadReg(
        InstancePtr->BaseAddress,
        CUSTOM_VERSION_OFFSET
    );

    if (version_value != CUSTOM_VERSION_VALUE) {
        return CUSTOMDRV_ERR_VERSION;
    }

    return CUSTOMDRV_OK;
}

int CustomDrv_SetEnable(CustomDrv *InstancePtr, u32 Enable)
{
    int result;

    result = CustomDrv_CheckReady(InstancePtr);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    Custom_SetEnable(
        InstancePtr->BaseAddress,
        Enable
    );

    return CUSTOMDRV_OK;
}

int CustomDrv_SetMode(CustomDrv *InstancePtr, CustomDrv_Mode Mode)
{
    int result;

    result = CustomDrv_CheckReady(InstancePtr);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    result = CustomDrv_CheckMode(Mode);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    Custom_SetMode(
        InstancePtr->BaseAddress,
        (u32)Mode
    );

    return CUSTOMDRV_OK;
}

int CustomDrv_Configure(
    CustomDrv *InstancePtr,
    u32 Enable,
    CustomDrv_Mode Mode
)
{
    int result;

    result = CustomDrv_SetMode(InstancePtr, Mode);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    return CustomDrv_SetEnable(InstancePtr, Enable);
}

int CustomDrv_GetStatus(
    CustomDrv *InstancePtr,
    CustomDrv_Status *StatusPtr
)
{
    int result;
    u32 raw;

    result = CustomDrv_CheckReady(InstancePtr);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    if (StatusPtr == 0) {
        return CUSTOMDRV_ERR_PARAM;
    }

    raw = Custom_ReadReg(
        InstancePtr->BaseAddress,
        CUSTOM_STATUS_OFFSET
    );

    StatusPtr->Raw = raw;
    StatusPtr->Busy =
        ((raw & CUSTOM_STATUS_BUSY_MASK) != 0U) ? 1U : 0U;
    StatusPtr->Done =
        ((raw & CUSTOM_STATUS_DONE_MASK) != 0U) ? 1U : 0U;
    StatusPtr->Error =
        ((raw & CUSTOM_STATUS_ERROR_MASK) != 0U) ? 1U : 0U;

    return CUSTOMDRV_OK;
}

int CustomDrv_GetIrqStatus(
    CustomDrv *InstancePtr,
    CustomDrv_IrqStatus *IrqStatusPtr
)
{
    int result;
    u32 raw;

    result = CustomDrv_CheckReady(InstancePtr);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    if (IrqStatusPtr == 0) {
        return CUSTOMDRV_ERR_PARAM;
    }

    raw = Custom_ReadReg(
        InstancePtr->BaseAddress,
        CUSTOM_IRQ_STATUS_OFFSET
    );

    IrqStatusPtr->Raw = raw;
    IrqStatusPtr->Done =
        ((raw & CUSTOM_IRQ_DONE_MASK) != 0U) ? 1U : 0U;
    IrqStatusPtr->Error =
        ((raw & CUSTOM_IRQ_ERROR_MASK) != 0U) ? 1U : 0U;

    return CUSTOMDRV_OK;
}

int CustomDrv_GetResult(
    CustomDrv *InstancePtr,
    u32 *OutputValue
)
{
    int result;

    result = CustomDrv_CheckReady(InstancePtr);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    if (OutputValue == 0) {
        return CUSTOMDRV_ERR_PARAM;
    }

    *OutputValue = Custom_ReadReg(
        InstancePtr->BaseAddress,
        CUSTOM_DATA_OUT_OFFSET
    );

    return CUSTOMDRV_OK;
}

int CustomDrv_IsBusy(CustomDrv *InstancePtr)
{
    int result;
    CustomDrv_Status status;

    result = CustomDrv_GetStatus(InstancePtr, &status);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    return (int)status.Busy;
}

int CustomDrv_IsDone(CustomDrv *InstancePtr)
{
    int result;
    CustomDrv_Status status;

    result = CustomDrv_GetStatus(InstancePtr, &status);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    return (int)status.Done;
}

int CustomDrv_HasError(CustomDrv *InstancePtr)
{
    int result;
    CustomDrv_Status status;

    result = CustomDrv_GetStatus(InstancePtr, &status);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    return (int)status.Error;
}

int CustomDrv_ClearStatus(CustomDrv *InstancePtr)
{
    int result;

    result = CustomDrv_CheckReady(InstancePtr);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    Custom_WriteReg(
        InstancePtr->BaseAddress,
        CUSTOM_COMMAND_OFFSET,
        CUSTOM_COMMAND_CLEAR_MASK
    );

    return CUSTOMDRV_OK;
}

int CustomDrv_ClearIrq(
    CustomDrv *InstancePtr,
    u32 IrqMask
)
{
    int result;
    u32 valid_mask;

    result = CustomDrv_CheckReady(InstancePtr);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    valid_mask =
        CUSTOM_IRQ_DONE_MASK |
        CUSTOM_IRQ_ERROR_MASK;

    Custom_WriteReg(
        InstancePtr->BaseAddress,
        CUSTOM_IRQ_STATUS_OFFSET,
        IrqMask & valid_mask
    );

    return CUSTOMDRV_OK;
}

int CustomDrv_ClearAllIrq(CustomDrv *InstancePtr)
{
    return CustomDrv_ClearIrq(
        InstancePtr,
        CUSTOM_IRQ_DONE_MASK |
        CUSTOM_IRQ_ERROR_MASK
    );
}

int CustomDrv_Start(CustomDrv *InstancePtr, u32 InputValue)
{
    int result;
    CustomDrv_Status status;

    result = CustomDrv_GetStatus(InstancePtr, &status);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    if (status.Busy != 0U) {
        return CUSTOMDRV_ERR_BUSY;
    }

    Custom_WriteReg(
        InstancePtr->BaseAddress,
        CUSTOM_DATA_IN_OFFSET,
        InputValue
    );

    Custom_Start(InstancePtr->BaseAddress);

    return CUSTOMDRV_OK;
}

int CustomDrv_WaitDone(
    CustomDrv *InstancePtr,
    u32 PollLimit
)
{
    u32 poll_count;
    int result;
    CustomDrv_Status status;

    if (PollLimit == 0U) {
        return CUSTOMDRV_ERR_PARAM;
    }

    for (poll_count = 0U;
         poll_count < PollLimit;
         poll_count++) {

        result = CustomDrv_GetStatus(
            InstancePtr,
            &status
        );

        if (result != CUSTOMDRV_OK) {
            return result;
        }

        if (status.Error != 0U) {
            return CUSTOMDRV_ERR_HW;
        }

        if (status.Done != 0U) {
            return CUSTOMDRV_OK;
        }
    }

    return CUSTOMDRV_ERR_TIMEOUT;
}

int CustomDrv_RunBlocking(
    CustomDrv *InstancePtr,
    CustomDrv_Mode Mode,
    u32 InputValue,
    u32 PollLimit,
    u32 *OutputValue
)
{
    int result;

    if (OutputValue == 0) {
        return CUSTOMDRV_ERR_PARAM;
    }

    result = CustomDrv_CheckMode(Mode);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    result = CustomDrv_ClearStatus(InstancePtr);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    result = CustomDrv_ClearAllIrq(InstancePtr);
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    result = CustomDrv_Configure(
        InstancePtr,
        1U,
        Mode
    );
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    result = CustomDrv_Start(
        InstancePtr,
        InputValue
    );
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    result = CustomDrv_WaitDone(
        InstancePtr,
        PollLimit
    );
    if (result != CUSTOMDRV_OK) {
        return result;
    }

    return CustomDrv_GetResult(
        InstancePtr,
        OutputValue
    );
}
