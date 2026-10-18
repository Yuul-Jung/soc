# SoC 37 · AXI Timer Runtime Measurement Guide

SoC 37의 Vivado Report와 실제 CPU 관측 Latency를 구분하기 위한 실습입니다.

## 1. 두 개의 Latency

### NPU Internal Latency

RTL Testbench 기준:

`job_start pulse → IRQ_STATUS.DONE`

Frozen RTL의 정적 예상값:

`35 cycles → 350 ns @ 100 MHz`

### CPU-visible End-to-End Latency

실제 Software:

`Npu_Start()` 직전 → ISR flag 직후`

또는 더 넓게:

`Tensor Fill 시작 → Result Verify 완료`

이 값은 AXI Transaction, CPU, Interrupt Controller, ISR 비용을 포함합니다.

## 2. AXI Timer 사용

기존 SoC 과정에서 사용한 AXI Timer를 Full SoC Block Design에 포함하고
MicroBlaze V가 Timer Counter를 읽도록 구성할 수 있습니다.

측정 구간 A:

1. Timer Read → `t_start`
2. `Npu_Start()`
3. DONE ISR
4. ISR 또는 Main에서 Timer Read → `t_done`
5. `delta = t_done - t_start`

측정 구간 B:

1. Tensor Fill 직전 → `t_e2e_start`
2. Tensor Fill
3. Descriptor
4. START
5. IRQ/ISR
6. Output Read
7. Verify
8. Timer Read → `t_e2e_end`

## 3. 주의

- Timer Clock Frequency를 반드시 기록합니다.
- Counter Overflow를 고려합니다.
- UART Print는 측정 구간 밖에 둡니다.
- Debugger Breakpoint는 Latency 측정에 사용하지 않습니다.
- 첫 실행과 반복 실행을 분리합니다.
- Cache가 없는/있는 구성 차이를 기록합니다.
- Release/Optimization Build 조건을 기록합니다.

## 4. 반복 측정

권장:

- Warm-up 10회
- Measurement 100회 이상
- min / max / average 기록

단, SoC 37에서는 실제 보드가 없으므로 숫자를 만들지 않습니다.
