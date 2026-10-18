#include "xil_exception.h"
#include "xil_printf.h"
#include "xintc.h"

#include "npu_e2e.h"
#include "npu_platform.h"

static XIntc Intc;

static volatile u32 NpuDoneFlag = 0U;
static volatile u32 NpuErrorFlag = 0U;
static volatile u32 NpuLastIrqStatus = 0U;

static void NpuIsr(void *CallbackRef)
{
    const UINTPTR npu_base =
        (UINTPTR)CallbackRef;

    const u32 pending =
        Npu_GetIrqStatus(npu_base);

    NpuLastIrqStatus = pending;

    if ((pending & NPU_IRQ_DONE_MASK) != 0U) {
        NpuDoneFlag = 1U;
    }

    if ((pending & NPU_IRQ_ERROR_MASK) != 0U) {
        NpuErrorFlag = 1U;
    }

    // Peripheral source first: W1C the latched pending cause.
    Npu_ClearIrq(
        npu_base,
        pending & NPU_IRQ_ALL_MASK
    );
}

static int SetupInterruptSystem(UINTPTR npu_base)
{
    int status;

#ifndef SDT
    status = XIntc_Initialize(
        &Intc,
        INTC_DEVICE_ID
    );
#else
    status = XIntc_Initialize(
        &Intc,
        INTC_BASEADDR
    );
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

static int RunOneJob(
    UINTPTR npu_base,
    UINTPTR tensor_base,
    const NpuE2EJob *job,
    NpuE2EResult *result
)
{
    u32 status;
    u32 timeout;

    // --------------------------------------------------------
    // 1. CPU owns the Tensor Buffer and loads input.
    // --------------------------------------------------------
    NpuE2E_LoadInput(
        tensor_base,
        job
    );

    // --------------------------------------------------------
    // 2. Program the shadow descriptor.
    // --------------------------------------------------------
    Npu_ProgramDescriptor(
        npu_base,
        &job->Descriptor
    );

    status = Npu_ReadReg(
        npu_base,
        NPU_STATUS_OFFSET
    );

    if (
        (status & NPU_STATUS_DESC_VALID_MASK) == 0U
    ) {
        result->ErrorCode =
            Npu_ReadReg(
                npu_base,
                NPU_ERROR_CODE_OFFSET
            );

        return 0;
    }

    // --------------------------------------------------------
    // 3. Clear stale state, arm interrupt, launch job.
    // --------------------------------------------------------
    Npu_WriteReg(
        npu_base,
        NPU_CONTROL_OFFSET,
        NPU_CONTROL_CLR_DONE_MASK |
        NPU_CONTROL_CLR_ERROR_MASK
    );

    Npu_ClearIrq(
        npu_base,
        NPU_IRQ_ALL_MASK
    );

    Npu_EnableIrq(
        npu_base,
        NPU_IRQ_ALL_MASK
    );

    NpuDoneFlag = 0U;
    NpuErrorFlag = 0U;
    NpuLastIrqStatus = 0U;

    Npu_Start(npu_base);

    // --------------------------------------------------------
    // 4. Wait on software flags set by ISR.
    //    This is not STATUS.DONE polling.
    // --------------------------------------------------------
    timeout = 1000000U;

    while (
        (NpuDoneFlag == 0U) &&
        (NpuErrorFlag == 0U) &&
        (timeout != 0U)
    ) {
        timeout--;
    }

    if (timeout == 0U) {
        return 0;
    }

    // --------------------------------------------------------
    // 5. CPU reclaims the Tensor Buffer after completion.
    // --------------------------------------------------------
    NpuE2E_ReadResult(
        npu_base,
        tensor_base,
        NpuLastIrqStatus,
        result
    );

    if (NpuErrorFlag != 0U) {
        return 0;
    }

    return NpuE2E_Verify(
        job,
        result
    );
}

int main(void)
{
    const UINTPTR npu_base =
        (UINTPTR)NPU_CTRL_BASEADDR;

    const UINTPTR tensor_base =
        (UINTPTR)TENSOR_BRAM_BASEADDR;

    const NpuE2EJob job0 = {
        .Input = {
            16, 32, 48, 64,
            32, 64, 96, 128
        },

        .Descriptor = {
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
        },

        .ExpectedOut0 = 0x20181008U,
        .ExpectedOut1 = 0x7F7F6333U
    };

    const NpuE2EJob job1 = {
        .Input = {
            2, 4, 6, 8,
            4, 8, 12, 16
        },

        .Descriptor = {
            .InputBase = 0x400U,
            .OutputBase = 0x500U,
            .LengthWords = 8U,

            .BiasCh0 = 0,
            .BiasCh1 = 4,

            .MultCh0 = 1,
            .MultCh1 = 3,

            .ShiftCh0 = 1U,
            .ShiftCh1 = 1U,

            .ZpCh0 = 0,
            .ZpCh1 = -3
        },

        .ExpectedOut0 = 0x04030201U,
        .ExpectedOut1 = 0x1B150F09U
    };

    NpuE2EResult result0 = {0};
    NpuE2EResult result1 = {0};

    xil_printf("\r\nSoC36 CPU-NPU End-to-End\r\n");

    if (
        SetupInterruptSystem(npu_base) !=
        XST_SUCCESS
    ) {
        xil_printf("ERROR: interrupt setup\r\n");
        return 1;
    }

    if (
        !RunOneJob(
            npu_base,
            tensor_base,
            &job0,
            &result0
        )
    ) {
        xil_printf(
            "JOB0 FAIL: IRQ=0x%08x ERR=%u\r\n",
            (unsigned int)result0.IrqStatus,
            (unsigned int)result0.ErrorCode
        );

        return 1;
    }

    xil_printf(
        "JOB0 PASS: id=%u out0=0x%08x out1=0x%08x\r\n",
        (unsigned int)result0.JobId,
        (unsigned int)result0.Out0,
        (unsigned int)result0.Out1
    );

    if (
        !RunOneJob(
            npu_base,
            tensor_base,
            &job1,
            &result1
        )
    ) {
        xil_printf(
            "JOB1 FAIL: IRQ=0x%08x ERR=%u\r\n",
            (unsigned int)result1.IrqStatus,
            (unsigned int)result1.ErrorCode
        );

        return 1;
    }

    xil_printf(
        "JOB1 PASS: id=%u out0=0x%08x out1=0x%08x\r\n",
        (unsigned int)result1.JobId,
        (unsigned int)result1.Out0,
        (unsigned int)result1.Out1
    );

    if (
        (result0.JobId != 1U) ||
        (result1.JobId != 2U)
    ) {
        xil_printf("ERROR: JOB_ID sequence\r\n");
        return 1;
    }

    xil_printf("SOC36 END-TO-END RESULT: PASS\r\n");

    return 0;
}
