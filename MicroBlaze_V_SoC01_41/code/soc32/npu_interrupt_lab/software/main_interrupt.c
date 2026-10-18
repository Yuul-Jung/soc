#include "xil_exception.h"
#include "xil_printf.h"
#include "xintc.h"
#include "xparameters.h"

#include "npu_accel.h"

// ------------------------------------------------------------
// Platform symbols
// ------------------------------------------------------------
//
// NPU_BASEADDR:
//   Generated xparameters.h symbol for npu_axi_irq_accel_ip.
//
// INTC_DEVICE_ID:
//   AXI Interrupt Controller Device ID.
//
// NPU_INTR_ID:
//   Interrupt ID assigned to the NPU irq input.
//
// Exact symbol names depend on Vivado instance names.
// Do not invent fixed addresses or interrupt IDs.

#ifndef NPU_BASEADDR
#ifdef XPAR_NPU_AXI_IRQ_0_BASEADDR
#define NPU_BASEADDR XPAR_NPU_AXI_IRQ_0_BASEADDR
#elif defined(XPAR_NPU_AXI_0_BASEADDR)
#define NPU_BASEADDR XPAR_NPU_AXI_0_BASEADDR
#else
#error "Define NPU_BASEADDR from generated xparameters.h."
#endif
#endif

// (변경) 생성 BSP 흐름에 맞춰 INTC 식별자를 선택한다.
#ifndef SDT
#ifndef INTC_DEVICE_ID
#ifdef XPAR_INTC_0_DEVICE_ID
#define INTC_DEVICE_ID XPAR_INTC_0_DEVICE_ID
#else
#error "Define INTC_DEVICE_ID from generated xparameters.h."
#endif
#endif
#else
#ifndef INTC_BASEADDR
#if defined(XPAR_XINTC_0_BASEADDR)
#define INTC_BASEADDR XPAR_XINTC_0_BASEADDR
#elif defined(XPAR_INTC_0_BASEADDR)
#define INTC_BASEADDR XPAR_INTC_0_BASEADDR
#else
#error "Define INTC_BASEADDR from generated xparameters.h."
#endif
#endif
#endif

#ifndef NPU_INTR_ID
#error "Define NPU_INTR_ID from generated xparameters.h."
#endif

static XIntc Intc;

static volatile u32 NpuDoneFlag = 0U;
static volatile u32 NpuErrorFlag = 0U;
static volatile u32 NpuLastIrqStatus = 0U;

static void NpuIsr(void *CallbackRef)
{
    const UINTPTR base = (UINTPTR)CallbackRef;
    const u32 irq_status = Npu_GetIrqStatus(base);

    NpuLastIrqStatus = irq_status;

    if ((irq_status & NPU_IRQ_DONE_MASK) != 0U) {
        NpuDoneFlag = 1U;
    }

    if ((irq_status & NPU_IRQ_ERROR_MASK) != 0U) {
        NpuErrorFlag = 1U;
    }

    // Clear the peripheral source before returning.
    // IRQ_STATUS uses Write-One-to-Clear.
    Npu_ClearIrq(
        base,
        irq_status & NPU_IRQ_ALL_MASK
    );
}

static int SetupInterruptSystem(UINTPTR base)
{
    int status;

    // (변경) SDT는 BaseAddress, 비 SDT는 DeviceId를 사용한다.
#ifndef SDT
    status = XIntc_Initialize(&Intc, INTC_DEVICE_ID);
#else
    status = XIntc_Initialize(&Intc, INTC_BASEADDR);
#endif

    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = XIntc_Connect(
        &Intc,
        NPU_INTR_ID,
        (XInterruptHandler)NpuIsr,
        (void *)base
    );

    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    status = XIntc_Start(
        &Intc,
        XIN_REAL_MODE
    );

    if (status != XST_SUCCESS) {
        return XST_FAILURE;
    }

    XIntc_Enable(
        &Intc,
        NPU_INTR_ID
    );

    Xil_ExceptionInit();

    Xil_ExceptionRegisterHandler(
        XIL_EXCEPTION_ID_INT,
        (Xil_ExceptionHandler)XIntc_InterruptHandler,
        &Intc
    );

    Xil_ExceptionEnable();

    return XST_SUCCESS;
}

static void WriteDemoInputs(UINTPTR base)
{
    Npu_WriteReg(base, NPU_ACC_IN0_OFFSET, 16U);
    Npu_WriteReg(base, NPU_ACC_IN1_OFFSET, 32U);
    Npu_WriteReg(base, NPU_ACC_IN2_OFFSET, 48U);
    Npu_WriteReg(base, NPU_ACC_IN3_OFFSET, 64U);

    Npu_WriteReg(base, NPU_ACC_IN4_OFFSET, 32U);
    Npu_WriteReg(base, NPU_ACC_IN5_OFFSET, 64U);
    Npu_WriteReg(base, NPU_ACC_IN6_OFFSET, 96U);
    Npu_WriteReg(base, NPU_ACC_IN7_OFFSET, 128U);
}

static void WriteDemoParameters(UINTPTR base)
{
    Npu_WriteReg(base, NPU_BIAS_CH0_OFFSET, 0U);
    Npu_WriteReg(
        base,
        NPU_SCALE_CH0_OFFSET,
        Npu_PackScale(1, 1U)
    );

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
    u32 out_ch0;
    u32 out_ch1;
    u32 sat_count;
    u32 timeout;

    xil_printf("\r\nSoC32 NPU interrupt demo\r\n");

    version = Npu_ReadReg(
        base,
        NPU_VERSION_OFFSET
    );

    if (version != NPU_VERSION_EXPECTED) {
        xil_printf("ERROR: unexpected NPU version\r\n");
        return 1;
    }

    if (SetupInterruptSystem(base) != XST_SUCCESS) {
        xil_printf("ERROR: interrupt setup failed\r\n");
        return 1;
    }

    // Clear stale software-visible and interrupt status.
    Npu_ClearDone(base);
    Npu_ClearError(base);
    Npu_ClearIrq(base, NPU_IRQ_ALL_MASK);

    // Enable DONE and ERROR sources inside the NPU peripheral.
    Npu_SetIrqEnable(
        base,
        NPU_IRQ_DONE_MASK |
        NPU_IRQ_ERROR_MASK
    );

    WriteDemoInputs(base);
    WriteDemoParameters(base);

    NpuDoneFlag = 0U;
    NpuErrorFlag = 0U;
    NpuLastIrqStatus = 0U;

    Npu_Start(base);

    // No STATUS.DONE polling.
    // Timeout is only a safety guard for the teaching example.
    timeout = 1000000U;

    while (
        (NpuDoneFlag == 0U) &&
        (NpuErrorFlag == 0U) &&
        (timeout != 0U)
    ) {
        timeout--;
    }

    if (timeout == 0U) {
        xil_printf("ERROR: interrupt timeout\r\n");
        return 1;
    }

    if (NpuErrorFlag != 0U) {
        xil_printf(
            "ERROR: NPU IRQ_STATUS = 0x%08x\r\n",
            (unsigned int)NpuLastIrqStatus
        );
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

    xil_printf(
        "IRQ_STATUS = 0x%08x\r\n",
        (unsigned int)NpuLastIrqStatus
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

    if (
        ((NpuLastIrqStatus & NPU_IRQ_DONE_MASK) == 0U) ||
        (out_ch0 != 0x20181008U) ||
        (out_ch1 != 0x7F7F6333U) ||
        ((sat_count & 0xFFU) != 2U)
    ) {
        xil_printf("SOC32 RESULT: FAIL\r\n");
        return 1;
    }

    xil_printf("SOC32 RESULT: PASS\r\n");

    return 0;
}
