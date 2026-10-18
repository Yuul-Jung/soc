#include <stdint.h>
#include <stddef.h>

/*
 * SoC 04 교육용 Memory Map / BRAM 주소 확인 코드
 * 특정 BRAM 절대주소를 임의로 고정하지 않는다.
 */

volatile uint32_t bram_word[4] = {0, 0, 0, 0};

volatile uintptr_t addr_0 = 0;
volatile uintptr_t addr_1 = 0;
volatile uintptr_t addr_2 = 0;
volatile uintptr_t addr_3 = 0;

volatile uint32_t read_0 = 0;
volatile uint32_t read_1 = 0;
volatile uint32_t read_2 = 0;
volatile uint32_t read_3 = 0;

volatile uint32_t stage = 0;

int main(void)
{
    addr_0 = (uintptr_t)&bram_word[0];
    addr_1 = (uintptr_t)&bram_word[1];
    addr_2 = (uintptr_t)&bram_word[2];
    addr_3 = (uintptr_t)&bram_word[3];
    stage = 1;

    bram_word[0] = 0x11111111U;
    bram_word[1] = 0x22222222U;
    bram_word[2] = 0x33333333U;
    bram_word[3] = 0x44444444U;
    stage = 2;

    read_0 = bram_word[0];
    read_1 = bram_word[1];
    read_2 = bram_word[2];
    read_3 = bram_word[3];
    stage = 3;

    bram_word[1] = 0xA5A5A5A5U;
    stage = 4;

    read_1 = bram_word[1];
    stage = 5;

    while (1) {
    }

    return 0;
}
