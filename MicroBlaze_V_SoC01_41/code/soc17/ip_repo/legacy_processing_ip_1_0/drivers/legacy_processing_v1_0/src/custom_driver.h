#ifndef CUSTOM_DRIVER_H
#define CUSTOM_DRIVER_H

#include "custom_regmap.h"
#include "xil_types.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * SoC 15 - MicroBlaze V Software Driver
 *
 * The driver stores only the hardware BaseAddress and software state.
 * The actual BaseAddress is supplied by the application/platform.
 */

#define CUSTOMDRV_READY_MAGIC  0x43555354U  /* ASCII "CUST" */

typedef enum {
    CUSTOMDRV_OK              =  0,
    CUSTOMDRV_ERR_PARAM       = -1,
    CUSTOMDRV_ERR_NOT_READY   = -2,
    CUSTOMDRV_ERR_ID          = -3,
    CUSTOMDRV_ERR_VERSION     = -4,
    CUSTOMDRV_ERR_BUSY        = -5,
    CUSTOMDRV_ERR_HW          = -6,
    CUSTOMDRV_ERR_TIMEOUT     = -7
} CustomDrv_Result;

typedef enum {
    CUSTOMDRV_MODE_PASS       = 0U,
    CUSTOMDRV_MODE_ADD1       = 1U,
    CUSTOMDRV_MODE_SHIFT_LEFT = 2U,
    CUSTOMDRV_MODE_NOT        = 3U
} CustomDrv_Mode;

typedef struct {
    UINTPTR BaseAddress;
    u32     IsReady;
} CustomDrv;

typedef struct {
    u32 Raw;
    u32 Busy;
    u32 Done;
    u32 Error;
} CustomDrv_Status;

typedef struct {
    u32 Raw;
    u32 Done;
    u32 Error;
} CustomDrv_IrqStatus;

/* Initialization / identification */
int CustomDrv_Initialize(CustomDrv *InstancePtr, UINTPTR BaseAddress);
int CustomDrv_SelfTest(CustomDrv *InstancePtr);

/* Configuration */
int CustomDrv_SetEnable(CustomDrv *InstancePtr, u32 Enable);
int CustomDrv_SetMode(CustomDrv *InstancePtr, CustomDrv_Mode Mode);
int CustomDrv_Configure(
    CustomDrv *InstancePtr,
    u32 Enable,
    CustomDrv_Mode Mode
);

/* Operation */
int CustomDrv_Start(CustomDrv *InstancePtr, u32 InputValue);
int CustomDrv_WaitDone(
    CustomDrv *InstancePtr,
    u32 PollLimit
);
int CustomDrv_RunBlocking(
    CustomDrv *InstancePtr,
    CustomDrv_Mode Mode,
    u32 InputValue,
    u32 PollLimit,
    u32 *OutputValue
);

/* Status / result */
int CustomDrv_GetStatus(
    CustomDrv *InstancePtr,
    CustomDrv_Status *StatusPtr
);
int CustomDrv_GetIrqStatus(
    CustomDrv *InstancePtr,
    CustomDrv_IrqStatus *IrqStatusPtr
);
int CustomDrv_GetResult(
    CustomDrv *InstancePtr,
    u32 *OutputValue
);
int CustomDrv_IsBusy(CustomDrv *InstancePtr);
int CustomDrv_IsDone(CustomDrv *InstancePtr);
int CustomDrv_HasError(CustomDrv *InstancePtr);

/* Clear retained state */
int CustomDrv_ClearStatus(CustomDrv *InstancePtr);
int CustomDrv_ClearIrq(
    CustomDrv *InstancePtr,
    u32 IrqMask
);
int CustomDrv_ClearAllIrq(CustomDrv *InstancePtr);

#ifdef __cplusplus
}
#endif

#endif
