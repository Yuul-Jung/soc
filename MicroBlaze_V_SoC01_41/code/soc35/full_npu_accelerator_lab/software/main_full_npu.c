#include "xil_exception.h"
#include "xil_printf.h"
#include "xintc.h"
#include "xparameters.h"

#include "npu_full.h"

#ifndef NPU_CTRL_BASEADDR
#error "Define NPU_CTRL_BASEADDR from generated xparameters.h."
#endif

#ifndef TENSOR_BRAM_BASEADDR
#error "Define TENSOR_BRAM_BASEADDR from generated xparameters.h."
#endif

// (변경) 생성 BSP 흐름에 맞춰 INTC 식별자를 선택한다.
#ifndef SDT
#ifndef INTC_DEVICE_ID
#error "Define INTC_DEVICE_ID from generated xparameters.h."
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
static volatile u32 NpuLastIrq = 0U;

static void NpuIsr(void *CallbackRef)
{
    const UINTPTR base = (UINTPTR)CallbackRef;
    const u32 pending = Npu_GetIrqStatus(base);

    NpuLastIrq = pending;

    if ((pending & NPU_IRQ_DONE_MASK) != 0U) {
        NpuDoneFlag = 1U;
    }

    if ((pending & NPU_IRQ_ERROR_MASK) != 0U) {
        NpuErrorFlag = 1U;
    }

    Npu_ClearIrq(
        base,
        pending & NPU_IRQ_ALL_MASK
    );
}

static int SetupInterruptSystem(UINTPTR npu_base)
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
        (void *)npu_base
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

static void TensorWrite(
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

static u32 TensorRead(
    UINTPTR TensorBase,
    u32 Offset
)
{
    return Xil_In32(
        TensorBase + (UINTPTR)Offset
    );
}

int main(void)
{
    const UINTPTR npu_base =
        (UINTPTR)NPU_CTRL_BASEADDR;

    const UINTPTR tensor_base =
        (UINTPTR)TENSOR_BRAM_BASEADDR;

    const NpuDescriptor job = {
        .InputBase = 0x200U,
        .OutputBase = 0x300U,
        .LengthWords = 8U,

        .BiasCh0 = 0,
        .BiasCh1 = 4,

        .MultCh0 = 1,
        .MultCh1 = 3,

        .ShiftCh0 = 1U,
        .ShiftCh1 = 1U,

        .ZpCh0 = 0,
        .ZpCh1 = -3
    };

    u32 timeout;
    u32 out0;
    u32 out1;

    xil_printf("\r\nSoC35 Full NPU Accelerator\r\n");

    if (SetupInterruptSystem(npu_base) != XST_SUCCESS) {
        xil_printf("ERROR: interrupt setup\r\n");
        return 1;
    }

    TensorWrite(tensor_base, 0x200U, 16U);
    TensorWrite(tensor_base, 0x204U, 32U);
    TensorWrite(tensor_base, 0x208U, 48U);
    TensorWrite(tensor_base, 0x20CU, 64U);

    TensorWrite(tensor_base, 0x210U, 32U);
    TensorWrite(tensor_base, 0x214U, 64U);
    TensorWrite(tensor_base, 0x218U, 96U);
    TensorWrite(tensor_base, 0x21CU, 128U);

    Npu_ProgramDescriptor(npu_base, &job);

    if (
        (
            Npu_ReadReg(
                npu_base,
                NPU_STATUS_OFFSET
            ) &
            NPU_STATUS_DESC_VALID_MASK
        ) == 0U
    ) {
        xil_printf("ERROR: descriptor invalid\r\n");
        return 1;
    }

    Npu_ClearIrq(npu_base, NPU_IRQ_ALL_MASK);
    Npu_EnableIrq(npu_base, NPU_IRQ_ALL_MASK);

    NpuDoneFlag = 0U;
    NpuErrorFlag = 0U;
    NpuLastIrq = 0U;

    Npu_Start(npu_base);

    timeout = 1000000U;

    while (
        (NpuDoneFlag == 0U) &&
        (NpuErrorFlag == 0U) &&
        (timeout != 0U)
    ) {
        timeout--;
    }

    if (timeout == 0U) {
        xil_printf("ERROR: NPU timeout\r\n");
        return 1;
    }

    if (NpuErrorFlag != 0U) {
        xil_printf(
            "ERROR: IRQ=0x%08x CODE=%u\r\n",
            (unsigned int)NpuLastIrq,
            (unsigned int)Npu_ReadReg(
                npu_base,
                NPU_ERROR_CODE_OFFSET
            )
        );
        return 1;
    }

    out0 = TensorRead(tensor_base, 0x300U);
    out1 = TensorRead(tensor_base, 0x304U);

    xil_printf("OUT_CH0 = 0x%08x\r\n", (unsigned int)out0);
    xil_printf("OUT_CH1 = 0x%08x\r\n", (unsigned int)out1);

    if (
        (out0 != 0x20181008U) ||
        (out1 != 0x7F7F6333U)
    ) {
        xil_printf("SOC35 RESULT: FAIL\r\n");
        return 1;
    }

    xil_printf("SOC35 RESULT: PASS\r\n");

    return 0;
}
