#ifndef NPU_FULL_H
#define NPU_FULL_H

#include "xil_io.h"
#include "xil_types.h"

#define NPU_CONTROL_OFFSET          0x00U
#define NPU_STATUS_OFFSET           0x04U
#define NPU_VERSION_OFFSET          0x08U
#define NPU_JOB_ID_OFFSET           0x0CU

#define NPU_INPUT_BASE_OFFSET       0x10U
#define NPU_OUTPUT_BASE_OFFSET      0x14U
#define NPU_LENGTH_WORDS_OFFSET     0x18U
#define NPU_ERROR_CODE_OFFSET       0x1CU

#define NPU_BIAS_CH0_OFFSET         0x20U
#define NPU_BIAS_CH1_OFFSET         0x24U
#define NPU_SCALE_CH0_OFFSET        0x28U
#define NPU_SCALE_CH1_OFFSET        0x2CU
#define NPU_ZERO_POINT_OFFSET       0x30U

#define NPU_ACTIVE_INPUT_OFFSET     0x34U
#define NPU_ACTIVE_OUTPUT_OFFSET    0x38U
#define NPU_ACTIVE_LENGTH_OFFSET    0x3CU

#define NPU_READ_COUNT_OFFSET       0x40U
#define NPU_WRITE_COUNT_OFFSET      0x44U

#define NPU_IRQ_ENABLE_OFFSET       0x48U
#define NPU_IRQ_STATUS_OFFSET       0x4CU

#define NPU_CONTROL_START_MASK      0x00000001U
#define NPU_CONTROL_CLR_DONE_MASK   0x00000002U
#define NPU_CONTROL_CLR_ERROR_MASK  0x00000004U

#define NPU_STATUS_BUSY_MASK        0x00000001U
#define NPU_STATUS_DONE_MASK        0x00000002U
#define NPU_STATUS_ERROR_MASK       0x00000004U
#define NPU_STATUS_DESC_VALID_MASK  0x00000008U

#define NPU_IRQ_DONE_MASK           0x00000001U
#define NPU_IRQ_ERROR_MASK          0x00000002U
#define NPU_IRQ_ALL_MASK            0x00000003U

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
} NpuDescriptor;

static inline void Npu_WriteReg(
    UINTPTR Base,
    u32 Offset,
    u32 Value
)
{
    Xil_Out32(Base + (UINTPTR)Offset, Value);
}

static inline u32 Npu_ReadReg(
    UINTPTR Base,
    u32 Offset
)
{
    return Xil_In32(Base + (UINTPTR)Offset);
}

static inline u32 Npu_PackScale(
    s16 Multiplier,
    u8 Shift
)
{
    return
        ((u32)Multiplier & 0xFFFFU) |
        (((u32)Shift & 0x3FU) << 16U);
}

static inline u32 Npu_PackZeroPoint(
    s16 ZpCh0,
    s16 ZpCh1
)
{
    return
        ((u32)ZpCh0 & 0xFFFFU) |
        (((u32)ZpCh1 & 0xFFFFU) << 16U);
}

static inline void Npu_ProgramDescriptor(
    UINTPTR Base,
    const NpuDescriptor *Desc
)
{
    Npu_WriteReg(Base, NPU_INPUT_BASE_OFFSET, Desc->InputBase);
    Npu_WriteReg(Base, NPU_OUTPUT_BASE_OFFSET, Desc->OutputBase);
    Npu_WriteReg(Base, NPU_LENGTH_WORDS_OFFSET, Desc->LengthWords);

    Npu_WriteReg(Base, NPU_BIAS_CH0_OFFSET, (u32)Desc->BiasCh0);
    Npu_WriteReg(Base, NPU_BIAS_CH1_OFFSET, (u32)Desc->BiasCh1);

    Npu_WriteReg(
        Base,
        NPU_SCALE_CH0_OFFSET,
        Npu_PackScale(Desc->MultCh0, Desc->ShiftCh0)
    );

    Npu_WriteReg(
        Base,
        NPU_SCALE_CH1_OFFSET,
        Npu_PackScale(Desc->MultCh1, Desc->ShiftCh1)
    );

    Npu_WriteReg(
        Base,
        NPU_ZERO_POINT_OFFSET,
        Npu_PackZeroPoint(Desc->ZpCh0, Desc->ZpCh1)
    );
}

static inline void Npu_EnableIrq(
    UINTPTR Base,
    u32 Mask
)
{
    Npu_WriteReg(
        Base,
        NPU_IRQ_ENABLE_OFFSET,
        Mask & NPU_IRQ_ALL_MASK
    );
}

static inline u32 Npu_GetIrqStatus(UINTPTR Base)
{
    return Npu_ReadReg(Base, NPU_IRQ_STATUS_OFFSET);
}

static inline void Npu_ClearIrq(
    UINTPTR Base,
    u32 Mask
)
{
    Npu_WriteReg(
        Base,
        NPU_IRQ_STATUS_OFFSET,
        Mask & NPU_IRQ_ALL_MASK
    );
}

static inline void Npu_Start(UINTPTR Base)
{
    Npu_WriteReg(
        Base,
        NPU_CONTROL_OFFSET,
        NPU_CONTROL_START_MASK
    );
}

#endif
