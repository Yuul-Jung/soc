#include "pwm_driver.h"

static int PwmDrv_CheckReady(const PwmDrv *InstancePtr)
{
    if (InstancePtr == 0) {
        return PWMDRV_ERR_PARAM;
    }

    if (InstancePtr->IsReady != PWMDRV_READY_MAGIC) {
        return PWMDRV_ERR_NOT_READY;
    }

    return PWMDRV_OK;
}

int PwmDrv_Initialize(PwmDrv *InstancePtr, UINTPTR BaseAddress)
{
    if (InstancePtr == 0) {
        return PWMDRV_ERR_PARAM;
    }

    if ((BaseAddress & 0x3U) != 0U) {
        return PWMDRV_ERR_PARAM;
    }

    InstancePtr->BaseAddress = BaseAddress;
    InstancePtr->IsReady = 0U;

    if (Pwm_ReadReg(BaseAddress, PWM_ID_OFFSET) != PWM_ID_VALUE) {
        return PWMDRV_ERR_ID;
    }

    if (Pwm_ReadReg(BaseAddress, PWM_VERSION_OFFSET) != PWM_VERSION_VALUE) {
        return PWMDRV_ERR_ID;
    }

    InstancePtr->IsReady = PWMDRV_READY_MAGIC;
    return PWMDRV_OK;
}

int PwmDrv_ClearError(PwmDrv *InstancePtr)
{
    int rc;

    rc = PwmDrv_CheckReady(InstancePtr);
    if (rc != PWMDRV_OK) {
        return rc;
    }

    Pwm_WriteReg(
        InstancePtr->BaseAddress,
        PWM_COMMAND_OFFSET,
        PWM_COMMAND_CLEAR_ERR_MASK
    );

    return PWMDRV_OK;
}

int PwmDrv_Configure(
    PwmDrv *InstancePtr,
    u32 PeriodClocks,
    u32 DutyClocks,
    u32 Enable,
    u32 Invert
)
{
    u32 control;
    u32 status;
    int rc;

    rc = PwmDrv_CheckReady(InstancePtr);
    if (rc != PWMDRV_OK) {
        return rc;
    }

    if ((PeriodClocks == 0U) || (DutyClocks > PeriodClocks)) {
        return PWMDRV_ERR_PARAM;
    }

    rc = PwmDrv_ClearError(InstancePtr);
    if (rc != PWMDRV_OK) {
        return rc;
    }

    control = 0U;

    if (Enable != 0U) {
        control |= PWM_CONTROL_ENABLE_MASK;
    }

    if (Invert != 0U) {
        control |= PWM_CONTROL_INVERT_MASK;
    }

    Pwm_WriteReg(
        InstancePtr->BaseAddress,
        PWM_CONTROL_OFFSET,
        control
    );

    Pwm_WriteReg(
        InstancePtr->BaseAddress,
        PWM_PERIOD_SHADOW_OFFSET,
        PeriodClocks
    );

    Pwm_WriteReg(
        InstancePtr->BaseAddress,
        PWM_DUTY_SHADOW_OFFSET,
        DutyClocks
    );

    Pwm_WriteReg(
        InstancePtr->BaseAddress,
        PWM_COMMAND_OFFSET,
        PWM_COMMAND_UPDATE_MASK
    );

    status = Pwm_ReadReg(
        InstancePtr->BaseAddress,
        PWM_STATUS_OFFSET
    );

    if ((status & PWM_STATUS_ERROR_MASK) != 0U) {
        return PWMDRV_ERR_HW;
    }

    return PWMDRV_OK;
}

int PwmDrv_Disable(PwmDrv *InstancePtr)
{
    u32 active_period;
    u32 active_duty;
    int rc;

    rc = PwmDrv_CheckReady(InstancePtr);
    if (rc != PWMDRV_OK) {
        return rc;
    }

    active_period = Pwm_ReadReg(
        InstancePtr->BaseAddress,
        PWM_ACTIVE_PERIOD_OFFSET
    );

    active_duty = Pwm_ReadReg(
        InstancePtr->BaseAddress,
        PWM_ACTIVE_DUTY_OFFSET
    );

    return PwmDrv_Configure(
        InstancePtr,
        active_period,
        active_duty,
        0U,
        0U
    );
}
