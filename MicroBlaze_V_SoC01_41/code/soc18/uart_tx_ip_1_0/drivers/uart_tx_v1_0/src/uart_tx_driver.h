#ifndef UART_TX_DRIVER_H
#define UART_TX_DRIVER_H

#include "uart_tx_regmap.h"

typedef struct {
    UINTPTR BaseAddress;
    u32 IsReady;
} UartTxDrv;

#define UARTTXDRV_READY_MAGIC   0x55545844U /* "UTXD" */

#define UARTTXDRV_OK             0
#define UARTTXDRV_ERR_PARAM     -1
#define UARTTXDRV_ERR_NOT_READY -2
#define UARTTXDRV_ERR_ID        -3
#define UARTTXDRV_ERR_BUSY      -4
#define UARTTXDRV_ERR_HW        -5
#define UARTTXDRV_ERR_TIMEOUT   -6

int UartTxDrv_Initialize(UartTxDrv *InstancePtr, UINTPTR BaseAddress);
int UartTxDrv_Enable(UartTxDrv *InstancePtr, u32 Enable);
int UartTxDrv_SendBlocking(
    UartTxDrv *InstancePtr,
    u8 Data,
    u32 PollLimit
);
int UartTxDrv_IsBusy(UartTxDrv *InstancePtr);
int UartTxDrv_Clear(UartTxDrv *InstancePtr);

#endif
