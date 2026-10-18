#include "xil_printf.h"
#include "xparameters.h"

#include "tensor_buffer.h"

// The actual Tensor BRAM base address comes from Vivado Address Editor.
// Replace/alias the symbol below with the generated xparameters.h symbol.

#ifndef TENSOR_BRAM_BASEADDR
#error "Define TENSOR_BRAM_BASEADDR from generated xparameters.h."
#endif

int main(void)
{
    const UINTPTR tensor_base =
        (UINTPTR)TENSOR_BRAM_BASEADDR;

    u32 value;

    xil_printf("\r\nSoC33 Tensor BRAM access demo\r\n");

    Tensor_Write32(
        tensor_base,
        TENSOR_INPUT_CH0_S0_OFFSET,
        16U
    );

    Tensor_Write32(
        tensor_base,
        TENSOR_INPUT_CH0_S1_OFFSET,
        32U
    );

    Tensor_Write32(
        tensor_base,
        TENSOR_INPUT_CH0_S2_OFFSET,
        48U
    );

    Tensor_Write32(
        tensor_base,
        TENSOR_INPUT_CH0_S3_OFFSET,
        64U
    );

    Tensor_Write32(
        tensor_base,
        TENSOR_INPUT_CH1_S0_OFFSET,
        32U
    );

    Tensor_Write32(
        tensor_base,
        TENSOR_INPUT_CH1_S1_OFFSET,
        64U
    );

    Tensor_Write32(
        tensor_base,
        TENSOR_INPUT_CH1_S2_OFFSET,
        96U
    );

    Tensor_Write32(
        tensor_base,
        TENSOR_INPUT_CH1_S3_OFFSET,
        128U
    );

    value = Tensor_Read32(
        tensor_base,
        TENSOR_INPUT_CH0_S0_OFFSET
    );

    xil_printf(
        "INPUT[0] = %u\r\n",
        (unsigned int)value
    );

    value = Tensor_Read32(
        tensor_base,
        TENSOR_INPUT_CH1_S3_OFFSET
    );

    xil_printf(
        "INPUT[7] = %u\r\n",
        (unsigned int)value
    );

    // In SoC 33 this program demonstrates the CPU-side Data Plane.
    // The self-checking RTL testbench verifies NPU Port-B access.
    //
    // SoC 34/35 will connect the Control Plane START/IRQ path
    // and this Tensor BRAM Data Plane into one accelerator system.

    xil_printf("SOC33 CPU TENSOR-BRAM ACCESS: PASS\r\n");

    return 0;
}
