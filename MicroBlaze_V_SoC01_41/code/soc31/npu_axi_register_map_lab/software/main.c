#include "xil_printf.h"
#include "xparameters.h"

#include "npu_accel.h"

// Vivado Address Editor assigns the final base address.
// Classic BSP commonly exports XPAR_NPU_AXI_0_BASEADDR.
//
// If your generated name differs, replace NPU_BASEADDR below
// with the symbol from the generated xparameters.h.
//
// Example:
// #define NPU_BASEADDR XPAR_NPU_AXI_0_BASEADDR

#ifndef NPU_BASEADDR
#ifdef XPAR_NPU_AXI_0_BASEADDR
#define NPU_BASEADDR XPAR_NPU_AXI_0_BASEADDR
#else
#error "Define NPU_BASEADDR using the generated xparameters.h base address."
#endif
#endif

static void npu_write_demo_inputs(UINTPTR base)
{
    // SoC 29 board-demo int32 outputs.
    // CH0 = [16, 32, 48, 64]
    // CH1 = [32, 64, 96, 128]

    Npu_WriteReg(base, NPU_ACC_IN0_OFFSET, 16U);
    Npu_WriteReg(base, NPU_ACC_IN1_OFFSET, 32U);
    Npu_WriteReg(base, NPU_ACC_IN2_OFFSET, 48U);
    Npu_WriteReg(base, NPU_ACC_IN3_OFFSET, 64U);

    Npu_WriteReg(base, NPU_ACC_IN4_OFFSET, 32U);
    Npu_WriteReg(base, NPU_ACC_IN5_OFFSET, 64U);
    Npu_WriteReg(base, NPU_ACC_IN6_OFFSET, 96U);
    Npu_WriteReg(base, NPU_ACC_IN7_OFFSET, 128U);
}

static void npu_write_demo_parameters(UINTPTR base)
{
    // CH0:
    // q = round_away_from_zero(x / 2)
    Npu_WriteReg(base, NPU_BIAS_CH0_OFFSET, 0U);
    Npu_WriteReg(
        base,
        NPU_SCALE_CH0_OFFSET,
        Npu_PackScale(1, 1U)
    );

    // CH1:
    // q = round_away_from_zero((x + 4) * 3 / 2) - 3
    Npu_WriteReg(base, NPU_BIAS_CH1_OFFSET, 4U);
    Npu_WriteReg(
        base,
        NPU_SCALE_CH1_OFFSET,
        Npu_PackScale(3, 1U)
    );

    Npu_WriteReg(
        base,
        NPU_ZERO_POINT_OFFSET,
        Npu_PackZeroPoint(0, -3)
    );
}

int main(void)
{
    const UINTPTR base = (UINTPTR)NPU_BASEADDR;

    u32 version;
    u32 status;
    u32 out_ch0;
    u32 out_ch1;
    u32 sat_count;
    u32 cycle_count;
    u32 timeout;

    xil_printf("\r\nSoC31 NPU AXI4-Lite demo\r\n");

    version = Npu_ReadReg(
        base,
        NPU_VERSION_OFFSET
    );

    xil_printf(
        "VERSION = 0x%08x\r\n",
        (unsigned int)version
    );

    if (version != NPU_VERSION_EXPECTED) {
        xil_printf("ERROR: unexpected NPU version\r\n");
        return 1;
    }

    Npu_ClearDone(base);
    Npu_ClearError(base);

    npu_write_demo_inputs(base);
    npu_write_demo_parameters(base);

    Npu_Start(base);

    timeout = 1000000U;
    status = 0U;

    while (
        ((status & NPU_STATUS_DONE_MASK) == 0U) &&
        (timeout != 0U)
    ) {
        status = Npu_GetStatus(base);
        timeout--;
    }

    if (timeout == 0U) {
        xil_printf("ERROR: accelerator timeout\r\n");
        return 1;
    }

    if ((status & NPU_STATUS_ERROR_MASK) != 0U) {
        xil_printf("ERROR: accelerator status error\r\n");
        return 1;
    }

    out_ch0 = Npu_ReadReg(
        base,
        NPU_OUT_CH0_OFFSET
    );

    out_ch1 = Npu_ReadReg(
        base,
        NPU_OUT_CH1_OFFSET
    );

    sat_count = Npu_ReadReg(
        base,
        NPU_SAT_COUNT_OFFSET
    );

    cycle_count = Npu_ReadReg(
        base,
        NPU_CYCLE_COUNT_OFFSET
    );

    xil_printf(
        "OUT_CH0 = 0x%08x\r\n",
        (unsigned int)out_ch0
    );

    xil_printf(
        "OUT_CH1 = 0x%08x\r\n",
        (unsigned int)out_ch1
    );

    xil_printf(
        "SAT_COUNT = %u\r\n",
        (unsigned int)sat_count
    );

    xil_printf(
        "CYCLE_COUNT = %u\r\n",
        (unsigned int)cycle_count
    );

    // Expected from SoC 30:
    // CH0 [8,16,24,32]   -> 0x20181008
    // CH1 [51,99,127,127]-> 0x7F7F6333
    if (
        (out_ch0 != 0x20181008U) ||
        (out_ch1 != 0x7F7F6333U) ||
        ((sat_count & 0xFFU) != 2U)
    ) {
        xil_printf("SOC31 RESULT: FAIL\r\n");
        return 1;
    }

    xil_printf("SOC31 RESULT: PASS\r\n");

    return 0;
}
