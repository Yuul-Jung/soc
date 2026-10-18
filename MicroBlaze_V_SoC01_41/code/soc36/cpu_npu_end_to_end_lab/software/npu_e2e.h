#ifndef NPU_E2E_H
#define NPU_E2E_H

#include "xil_io.h"
#include "xil_types.h"

#include "npu_full.h"

#define NPU_E2E_INPUT_WORDS   8U
#define NPU_E2E_OUTPUT_WORDS  2U

typedef struct {
    s32 Input[NPU_E2E_INPUT_WORDS];

    NpuDescriptor Descriptor;

    u32 ExpectedOut0;
    u32 ExpectedOut1;
} NpuE2EJob;

typedef struct {
    u32 Out0;
    u32 Out1;

    u32 JobId;
    u32 ReadWordCount;
    u32 WriteWordCount;

    u32 IrqStatus;
    u32 ErrorCode;
} NpuE2EResult;

static inline void NpuE2E_TensorWrite(
    UINTPTR TensorBase,
    u32 Offset,
    u32 Value
)
{
    Xil_Out32(
        TensorBase + (UINTPTR)Offset,
        Value
    );
}

static inline u32 NpuE2E_TensorRead(
    UINTPTR TensorBase,
    u32 Offset
)
{
    return Xil_In32(
        TensorBase + (UINTPTR)Offset
    );
}

static inline void NpuE2E_LoadInput(
    UINTPTR TensorBase,
    const NpuE2EJob *Job
)
{
    u32 index;

    for (index = 0U; index < NPU_E2E_INPUT_WORDS; ++index) {
        NpuE2E_TensorWrite(
            TensorBase,
            Job->Descriptor.InputBase + (index * 4U),
            (u32)Job->Input[index]
        );
    }
}

static inline void NpuE2E_ReadResult(
    UINTPTR NpuBase,
    UINTPTR TensorBase,
    u32 IrqStatus,
    NpuE2EResult *Result
)
{
    const u32 output_base =
        Npu_ReadReg(
            NpuBase,
            NPU_ACTIVE_OUTPUT_OFFSET
        );

    Result->Out0 =
        NpuE2E_TensorRead(
            TensorBase,
            output_base
        );

    Result->Out1 =
        NpuE2E_TensorRead(
            TensorBase,
            output_base + 4U
        );

    Result->JobId =
        Npu_ReadReg(
            NpuBase,
            NPU_JOB_ID_OFFSET
        );

    Result->ReadWordCount =
        Npu_ReadReg(
            NpuBase,
            NPU_READ_COUNT_OFFSET
        );

    Result->WriteWordCount =
        Npu_ReadReg(
            NpuBase,
            NPU_WRITE_COUNT_OFFSET
        );

    Result->IrqStatus = IrqStatus;

    Result->ErrorCode =
        Npu_ReadReg(
            NpuBase,
            NPU_ERROR_CODE_OFFSET
        );
}

static inline int NpuE2E_Verify(
    const NpuE2EJob *Job,
    const NpuE2EResult *Result
)
{
    if (Result->Out0 != Job->ExpectedOut0) {
        return 0;
    }

    if (Result->Out1 != Job->ExpectedOut1) {
        return 0;
    }

    if (Result->ReadWordCount != 8U) {
        return 0;
    }

    if (Result->WriteWordCount != 2U) {
        return 0;
    }

    if ((Result->IrqStatus & NPU_IRQ_DONE_MASK) == 0U) {
        return 0;
    }

    if ((Result->IrqStatus & NPU_IRQ_ERROR_MASK) != 0U) {
        return 0;
    }

    if (Result->ErrorCode != 0U) {
        return 0;
    }

    return 1;
}

#endif
