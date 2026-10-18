#ifndef NPU_ACCEL_H
#define NPU_ACCEL_H

#include "xil_io.h"
#include "xil_types.h"

// ------------------------------------------------------------
// SoC 31 NPU AXI4-Lite Register Map
// ------------------------------------------------------------
#define NPU_CONTROL_OFFSET       0x00U
#define NPU_STATUS_OFFSET        0x04U
#define NPU_VERSION_OFFSET       0x08U
#define NPU_SAT_COUNT_OFFSET     0x0CU

#define NPU_BIAS_CH0_OFFSET      0x10U
#define NPU_BIAS_CH1_OFFSET      0x14U
#define NPU_SCALE_CH0_OFFSET     0x18U
#define NPU_SCALE_CH1_OFFSET     0x1CU
#define NPU_ZERO_POINT_OFFSET    0x20U

#define NPU_ACC_IN0_OFFSET       0x40U
#define NPU_ACC_IN1_OFFSET       0x44U
#define NPU_ACC_IN2_OFFSET       0x48U
#define NPU_ACC_IN3_OFFSET       0x4CU
#define NPU_ACC_IN4_OFFSET       0x50U
#define NPU_ACC_IN5_OFFSET       0x54U
#define NPU_ACC_IN6_OFFSET       0x58U
#define NPU_ACC_IN7_OFFSET       0x5CU

#define NPU_OUT_CH0_OFFSET       0x60U
#define NPU_OUT_CH1_OFFSET       0x64U
#define NPU_CYCLE_COUNT_OFFSET   0x68U

#define NPU_CONTROL_START_MASK       0x00000001U
#define NPU_CONTROL_CLEAR_DONE_MASK  0x00000002U
#define NPU_CONTROL_CLEAR_ERROR_MASK 0x00000004U

#define NPU_STATUS_BUSY_MASK         0x00000001U
#define NPU_STATUS_DONE_MASK         0x00000002U
#define NPU_STATUS_ERROR_MASK        0x00000004U
#define NPU_STATUS_SATURATED_MASK    0x00000008U

#define NPU_VERSION_EXPECTED         0x00010000U

static inline void Npu_WriteReg(
    UINTPTR BaseAddress,
    u32 Offset,
    u32 Value
)
{
    Xil_Out32(BaseAddress + (UINTPTR)Offset, Value);
}

static inline u32 Npu_ReadReg(
    UINTPTR BaseAddress,
    u32 Offset
)
{
    return Xil_In32(BaseAddress + (UINTPTR)Offset);
}

static inline u32 Npu_PackScale(
    s16 Multiplier,
    u8 Shift
)
{
    return
        ((u32)Multiplier & 0x0000FFFFU) |
        (((u32)Shift & 0x3FU) << 16U);
}

static inline u32 Npu_PackZeroPoint(
    s16 ZpCh0,
    s16 ZpCh1
)
{
    return
        ((u32)ZpCh0 & 0x0000FFFFU) |
        (((u32)ZpCh1 & 0x0000FFFFU) << 16U);
}

static inline void Npu_Start(UINTPTR BaseAddress)
{
    Npu_WriteReg(
        BaseAddress,
        NPU_CONTROL_OFFSET,
        NPU_CONTROL_START_MASK
    );
}

static inline void Npu_ClearDone(UINTPTR BaseAddress)
{
    Npu_WriteReg(
        BaseAddress,
        NPU_CONTROL_OFFSET,
        NPU_CONTROL_CLEAR_DONE_MASK
    );
}

static inline void Npu_ClearError(UINTPTR BaseAddress)
{
    Npu_WriteReg(
        BaseAddress,
        NPU_CONTROL_OFFSET,
        NPU_CONTROL_CLEAR_ERROR_MASK
    );
}

static inline u32 Npu_GetStatus(UINTPTR BaseAddress)
{
    return Npu_ReadReg(
        BaseAddress,
        NPU_STATUS_OFFSET
    );
}

static inline int Npu_IsBusy(UINTPTR BaseAddress)
{
    return
        (Npu_GetStatus(BaseAddress) & NPU_STATUS_BUSY_MASK)
        != 0U;
}

static inline int Npu_IsDone(UINTPTR BaseAddress)
{
    return
        (Npu_GetStatus(BaseAddress) & NPU_STATUS_DONE_MASK)
        != 0U;
}

#endif
