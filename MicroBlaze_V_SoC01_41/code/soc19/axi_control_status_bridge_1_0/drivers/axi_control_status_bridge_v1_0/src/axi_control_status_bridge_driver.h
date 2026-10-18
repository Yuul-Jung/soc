#ifndef AXI_CONTROL_STATUS_BRIDGE_DRIVER_H
#define AXI_CONTROL_STATUS_BRIDGE_DRIVER_H

#include "axi_control_status_bridge_regmap.h"

typedef struct {
    UINTPTR BaseAddress;
    u32 IsReady;
} CsbDrv;

#define CSBDRV_READY_MAGIC       0x43534244U /* "CSBD" */

#define CSBDRV_OK                 0
#define CSBDRV_ERR_PARAM         -1
#define CSBDRV_ERR_NOT_READY     -2
#define CSBDRV_ERR_ID            -3
#define CSBDRV_ERR_BUSY          -4
#define CSBDRV_ERR_HW            -5
#define CSBDRV_ERR_TIMEOUT       -6
#define CSBDRV_ERR_NO_OUTPUT     -7

int CsbDrv_Initialize(CsbDrv *InstancePtr, UINTPTR BaseAddress);
int CsbDrv_SetControl(CsbDrv *InstancePtr, u32 ControlWord);
int CsbDrv_Submit(CsbDrv *InstancePtr, u32 InputWord);
int CsbDrv_OutputAvailable(CsbDrv *InstancePtr);
int CsbDrv_GetOutput(CsbDrv *InstancePtr, u32 *OutputWord);
int CsbDrv_PopOutput(CsbDrv *InstancePtr);
int CsbDrv_GetCoreStatus(CsbDrv *InstancePtr, u32 *StatusWord);
int CsbDrv_GetBridgeStatus(CsbDrv *InstancePtr, u32 *StatusWord);
int CsbDrv_GetEvents(CsbDrv *InstancePtr, u32 *EventWord);
int CsbDrv_ClearEvents(CsbDrv *InstancePtr, u32 EventMask);
int CsbDrv_ClearError(CsbDrv *InstancePtr);
int CsbDrv_RunBlocking(
    CsbDrv *InstancePtr,
    u32 ControlWord,
    u32 InputWord,
    u32 PollLimit,
    u32 *OutputWord
);

#endif
