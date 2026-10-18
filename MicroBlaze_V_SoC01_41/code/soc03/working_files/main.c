#include <stdint.h>

volatile uint32_t counter = 0;

int main(void)
{
    // 주변장치 없이 CPU + BRAM 실행만 확인한다.
    for (uint32_t i = 0; i < 100; i++) {
        counter++;
    }

    // Debugger에서 counter == 100을 확인할 수 있도록 정지 상태 유지
    while (1) {
        // 의도적인 무한 루프
    }

    return 0;
}
