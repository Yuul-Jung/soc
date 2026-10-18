#ifndef TENSOR_BUFFER_H
#define TENSOR_BUFFER_H

#include "xil_io.h"
#include "xil_types.h"

// ------------------------------------------------------------
// SoC 33 Tensor BRAM fixed teaching map.
//
// These are offsets inside the Tensor BRAM address range.
// SoC 34 will make base/length information programmable.
// ------------------------------------------------------------

#define TENSOR_INPUT_CH0_S0_OFFSET   0x000U
#define TENSOR_INPUT_CH0_S1_OFFSET   0x004U
#define TENSOR_INPUT_CH0_S2_OFFSET   0x008U
#define TENSOR_INPUT_CH0_S3_OFFSET   0x00CU

#define TENSOR_INPUT_CH1_S0_OFFSET   0x010U
#define TENSOR_INPUT_CH1_S1_OFFSET   0x014U
#define TENSOR_INPUT_CH1_S2_OFFSET   0x018U
#define TENSOR_INPUT_CH1_S3_OFFSET   0x01CU

#define TENSOR_OUTPUT_CH0_OFFSET     0x100U
#define TENSOR_OUTPUT_CH1_OFFSET     0x104U

static inline void Tensor_Write32(
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

static inline u32 Tensor_Read32(
    UINTPTR TensorBase,
    u32 Offset
)
{
    return Xil_In32(
        TensorBase + (UINTPTR)Offset
    );
}

#endif
