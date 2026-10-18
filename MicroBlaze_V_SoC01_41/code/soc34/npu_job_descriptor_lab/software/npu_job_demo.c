#include "xil_printf.h"
#include "xparameters.h"

#include "npu_job.h"

// Actual Base Address comes from Vivado Address Editor / xparameters.h.
#ifndef NPU_JOB_BASEADDR
#error "Define NPU_JOB_BASEADDR from generated xparameters.h."
#endif

int main(void)
{
    const UINTPTR base = (UINTPTR)NPU_JOB_BASEADDR;

    const NpuJobDescriptor job = {
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

    u32 status;
    u32 timeout;
    u32 error_code;
    u32 job_id;

    xil_printf("\r\nSoC34 NPU Job Descriptor demo\r\n");

    NpuJob_Program(base, &job);

    status = NpuJob_ReadReg(
        base,
        NPU_JOB_STATUS_OFFSET
    );

    if (
        (status & NPU_JOB_STATUS_DESC_VALID_MASK) == 0U
    ) {
        xil_printf("ERROR: descriptor invalid before START\r\n");
        return 1;
    }

    NpuJob_Start(base);

    timeout = 1000000U;

    do {
        status = NpuJob_ReadReg(
            base,
            NPU_JOB_STATUS_OFFSET
        );

        timeout--;
    } while (
        ((status & NPU_JOB_STATUS_DONE_MASK) == 0U) &&
        ((status & NPU_JOB_STATUS_ERROR_MASK) == 0U) &&
        (timeout != 0U)
    );

    if (timeout == 0U) {
        xil_printf("ERROR: job timeout\r\n");
        return 1;
    }

    if ((status & NPU_JOB_STATUS_ERROR_MASK) != 0U) {
        error_code = NpuJob_ReadReg(
            base,
            NPU_JOB_ERROR_CODE_OFFSET
        );

        xil_printf(
            "ERROR: descriptor/job error code = %u\r\n",
            (unsigned int)error_code
        );

        return 1;
    }

    job_id = NpuJob_ReadReg(
        base,
        NPU_JOB_ID_OFFSET
    );

    xil_printf(
        "JOB_ID = %u\r\n",
        (unsigned int)job_id
    );

    xil_printf(
        "READ_WORD_COUNT = %u\r\n",
        (unsigned int)NpuJob_ReadReg(
            base,
            NPU_JOB_READ_COUNT_OFFSET
        )
    );

    xil_printf(
        "WRITE_WORD_COUNT = %u\r\n",
        (unsigned int)NpuJob_ReadReg(
            base,
            NPU_JOB_WRITE_COUNT_OFFSET
        )
    );

    xil_printf("SOC34 JOB CONTROL: PASS\r\n");

    return 0;
}
