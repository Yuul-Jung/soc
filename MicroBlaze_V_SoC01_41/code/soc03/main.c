#include <stdint.h>

/*
 * SoC 03 교육용 BRAM Read/Write 검증 코드
 *
 * Vitis Debugger의 Watch / Memory 창에서 확인할 값:
 *
 * stage 1 : memory_data = 0x11111111
 * stage 2 : read_value_1 = 0x11111111
 * stage 3 : memory_data = 0x22222222
 * stage 4 : read_value_2 = 0x22222222
 * stage 5 : memory_data = 0x33333333
 * stage 6 : read_value_3 = 0x33333333
 */

volatile uint32_t memory_data  = 0;
volatile uint32_t read_value_1 = 0;
volatile uint32_t read_value_2 = 0;
volatile uint32_t read_value_3 = 0;
volatile uint32_t stage        = 0;

int main(void)
{
    // 1단계: BRAM 변수에 첫 번째 값을 쓴다.
    memory_data = 0x11111111U;
    stage = 1;

    // 2단계: 방금 쓴 값을 다시 읽는다.
    read_value_1 = memory_data;
    stage = 2;

    // 3단계: 같은 BRAM 변수에 다른 값을 다시 쓴다.
    memory_data = 0x22222222U;
    stage = 3;

    // 4단계: 변경된 값을 다시 읽는다.
    read_value_2 = memory_data;
    stage = 4;

    // 5단계: 앞에서 읽은 두 값을 더한 결과를 다시 쓴다.
    memory_data = read_value_1 + read_value_2;
    stage = 5;

    // 6단계: 최종 변경값을 다시 읽는다.
    read_value_3 = memory_data;
    stage = 6;

    // Debugger에서 최종 값을 확인할 수 있도록 정지 상태 유지
    while (1) {
        // 의도적인 무한 루프
    }

    return 0;
}
