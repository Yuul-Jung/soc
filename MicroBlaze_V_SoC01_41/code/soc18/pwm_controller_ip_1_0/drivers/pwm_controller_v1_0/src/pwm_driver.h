#ifndef PWM_DRIVER_H
#define PWM_DRIVER_H

#include "pwm_regmap.h"

typedef struct {
    UINTPTR BaseAddress;
    u32 IsReady;
} PwmDrv;

#define PWMDRV_READY_MAGIC    0x50574D44U /* "PWMD" */

#define PWMDRV_OK              0
#define PWMDRV_ERR_PARAM      -1
#define PWMDRV_ERR_NOT_READY  -2
#define PWMDRV_ERR_ID         -3
#define PWMDRV_ERR_HW         -4

int PwmDrv_Initialize(PwmDrv *InstancePtr, UINTPTR BaseAddress);
int PwmDrv_Configure(
    PwmDrv *InstancePtr,
    u32 PeriodClocks,
    u32 DutyClocks,
    u32 Enable,
    u32 Invert
);
int PwmDrv_Disable(PwmDrv *InstancePtr);
int PwmDrv_ClearError(PwmDrv *InstancePtr);

#endif
