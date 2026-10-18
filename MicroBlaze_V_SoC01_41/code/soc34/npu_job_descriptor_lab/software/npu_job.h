#ifndef NPU_JOB_H
#define NPU_JOB_H

#include "xil_io.h"
#include "xil_types.h"

#define NPU_JOB_CONTROL_OFFSET          0x00U
#define NPU_JOB_STATUS_OFFSET           0x04U
#define NPU_JOB_VERSION_OFFSET          0x08U
#define NPU_JOB_ID_OFFSET               0x0CU

#define NPU_JOB_INPUT_BASE_OFFSET       0x10U
#define NPU_JOB_OUTPUT_BASE_OFFSET      0x14U
#define NPU_JOB_LENGTH_WORDS_OFFSET     0x18U
#define NPU_JOB_ERROR_CODE_OFFSET       0x1CU

#define NPU_JOB_BIAS_CH0_OFFSET         0x20U
#define NPU_JOB_BIAS_CH1_OFFSET         0x24U
#define NPU_JOB_SCALE_CH0_OFFSET        0x28U
#define NPU_JOB_SCALE_CH1_OFFSET        0x2CU
#define NPU_JOB_ZERO_POINT_OFFSET       0x30U

#define NPU_JOB_ACTIVE_INPUT_OFFSET     0x34U
#define NPU_JOB_ACTIVE_OUTPUT_OFFSET    0x38U
#define NPU_JOB_ACTIVE_LENGTH_OFFSET    0x3CU

#define NPU_JOB_READ_COUNT_OFFSET       0x40U
#define NPU_JOB_WRITE_COUNT_OFFSET      0x44U

#define NPU_JOB_CONTROL_START_MASK      0x00000001U
#define NPU_JOB_CONTROL_CLR_DONE_MASK   0x00000002U
#define NPU_JOB_CONTROL_CLR_ERROR_MASK  0x00000004U

#define NPU_JOB_STATUS_BUSY_MASK        0x00000001U
#define NPU_JOB_STATUS_DONE_MASK        0x00000002U
#define NPU_JOB_STATUS_ERROR_MASK       0x00000004U
#define NPU_JOB_STATUS_DESC_VALID_MASK  0x00000008U

typedef struct {
    u32 InputBase;
    u32 OutputBase;
    u32 LengthWords;
    s32 BiasCh0;
    s32 BiasCh1;
    s16 MultCh0;
    s16 MultCh1;
    u8 ShiftCh0;
    u8 ShiftCh1;
    s16 ZpCh0;
    s16 ZpCh1;
} NpuJobDescriptor;

static inline void NpuJob_WriteReg(
    UINTPTR BaseAddress,
    u32 Offset,
    u32 Value
)
{
    Xil_Out32(BaseAddress + (UINTPTR)Offset, Value);
}

static inline u32 NpuJob_ReadReg(
    UINTPTR BaseAddress,
    u32 Offset
)
{
    return Xil_In32(BaseAddress + (UINTPTR)Offset);
}

static inline u32 NpuJob_PackScale(
    s16 Multiplier,
    u8 Shift
)
{
    return
        ((u32)Multiplier & 0x0000FFFFU) |
        (((u32)Shift & 0x3FU) << 16U);
}

static inline u32 NpuJob_PackZeroPoint(
    s16 ZpCh0,
    s16 ZpCh1
)
{
    return
        ((u32)ZpCh0 & 0x0000FFFFU) |
        (((u32)ZpCh1 & 0x0000FFFFU) << 16U);
}

static inline void NpuJob_Program(
    UINTPTR BaseAddress,
    const NpuJobDescriptor *Job
)
{
    NpuJob_WriteReg(
        BaseAddress,
        NPU_JOB_INPUT_BASE_OFFSET,
        Job->InputBase
    );

    NpuJob_WriteReg(
        BaseAddress,
        NPU_JOB_OUTPUT_BASE_OFFSET,
        Job->OutputBase
    );

    NpuJob_WriteReg(
        BaseAddress,
        NPU_JOB_LENGTH_WORDS_OFFSET,
        Job->LengthWords
    );

    NpuJob_WriteReg(
        BaseAddress,
        NPU_JOB_BIAS_CH0_OFFSET,
        (u32)Job->BiasCh0
    );

    NpuJob_WriteReg(
        BaseAddress,
        NPU_JOB_BIAS_CH1_OFFSET,
        (u32)Job->BiasCh1
    );

    NpuJob_WriteReg(
        BaseAddress,
        NPU_JOB_SCALE_CH0_OFFSET,
        NpuJob_PackScale(
            Job->MultCh0,
            Job->ShiftCh0
        )
    );

    NpuJob_WriteReg(
        BaseAddress,
        NPU_JOB_SCALE_CH1_OFFSET,
        NpuJob_PackScale(
            Job->MultCh1,
            Job->ShiftCh1
        )
    );

    NpuJob_WriteReg(
        BaseAddress,
        NPU_JOB_ZERO_POINT_OFFSET,
        NpuJob_PackZeroPoint(
            Job->ZpCh0,
            Job->ZpCh1
        )
    );
}

static inline void NpuJob_Start(UINTPTR BaseAddress)
{
    NpuJob_WriteReg(
        BaseAddress,
        NPU_JOB_CONTROL_OFFSET,
        NPU_JOB_CONTROL_START_MASK
    );
}

#endif
