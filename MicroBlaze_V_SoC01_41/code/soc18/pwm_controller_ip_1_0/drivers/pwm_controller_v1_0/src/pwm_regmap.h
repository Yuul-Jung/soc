#ifndef PWM_REGMAP_H
#define PWM_REGMAP_H

#include "xil_io.h"
#include "xil_types.h"

#define PWM_CONTROL_OFFSET          0x00U
#define PWM_PERIOD_SHADOW_OFFSET    0x04U
#define PWM_DUTY_SHADOW_OFFSET      0x08U
#define PWM_COMMAND_OFFSET          0x0CU
#define PWM_STATUS_OFFSET           0x10U
#define PWM_ACTIVE_PERIOD_OFFSET    0x14U
#define PWM_ACTIVE_DUTY_OFFSET      0x18U
#define PWM_ID_OFFSET               0x1CU
#define PWM_VERSION_OFFSET          0x20U

#define PWM_CONTROL_ENABLE_MASK     0x00000001U
#define PWM_CONTROL_INVERT_MASK     0x00000002U

#define PWM_COMMAND_UPDATE_MASK     0x00000001U
#define PWM_COMMAND_CLEAR_ERR_MASK  0x00000002U

#define PWM_STATUS_ACTIVE_MASK      0x00000001U
#define PWM_STATUS_ERROR_MASK       0x00000002U

#define PWM_ID_VALUE                0x50574D31U /* ASCII "PWM1" */
#define PWM_VERSION_VALUE           0x00010000U

#define Pwm_ReadReg(BaseAddress, Offset) \
    Xil_In32((BaseAddress) + (Offset))

#define Pwm_WriteReg(BaseAddress, Offset, Data) \
    Xil_Out32((BaseAddress) + (Offset), (Data))

#endif
