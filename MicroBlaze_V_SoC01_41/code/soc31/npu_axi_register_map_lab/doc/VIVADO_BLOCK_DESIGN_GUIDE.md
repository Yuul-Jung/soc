# SoC 31 · Vivado Block Design 연결 절차

## 1. 기준

기존 MicroBlaze V + BRAM + Clock/Reset + SmartConnect 설계를 유지합니다.

추가 대상:

`npu_axi_accel_ip`

이 모듈은 AXI4-Lite Slave 인터페이스만 외부에 노출합니다.

## 2. Design Sources

다음 파일을 프로젝트에 추가합니다.

- `requantize_s32_to_s8.v`
- `requantize_batch2x4_serial.v`
- `npu_register_bank.v`
- `npu_axi4lite_slave.v`
- `npu_axi_accel_ip.v`

## 3. Block Design

1. 기존 Block Design을 엽니다.
2. `Add Module` 또는 `Module Reference`로 `npu_axi_accel_ip`를 추가합니다.
3. `S_AXI`를 SmartConnect의 비어 있는 Master Interface에 연결합니다.
4. `s_axi_aclk`를 기존 AXI 100 MHz Clock에 연결합니다.
5. `s_axi_aresetn`을 해당 Clock Domain의 active-low peripheral reset에 연결합니다.
6. `Validate Design`을 실행합니다.

## 4. Address Editor

NPU AXI Slave에 주소를 할당합니다.

중요:

- 이 자료는 특정 Base Address를 하드코딩하지 않습니다.
- 실제 Base Address는 Vivado Address Editor 결과를 사용합니다.
- Vitis/BSP에서 생성된 `xparameters.h`의 NPU Base Address Symbol을 확인합니다.

예시 소스의 기본 기대 Symbol:

`XPAR_NPU_AXI_0_BASEADDR`

실제 Instance 이름에 따라 Symbol 이름은 달라질 수 있습니다.

## 5. Software

`software/npu_accel.h`

- `Xil_Out32()` 기반 Register Write
- `Xil_In32()` 기반 Register Read
- Register Offset와 Bit Mask 정의

`software/main.c`

동작:

1. VERSION 확인
2. Sticky Status Clear
3. ACC_IN0..7 Write
4. Bias/Scale/Zero Point Write
5. CONTROL.START Write
6. STATUS.DONE Polling
7. OUT_CH0/OUT_CH1 Read
8. SAT_COUNT / CYCLE_COUNT Read
9. Expected Result 비교

## 6. 기대 출력

```text
VERSION = 0x00010000
OUT_CH0 = 0x20181008
OUT_CH1 = 0x7F7F6333
SAT_COUNT = 2
CYCLE_COUNT = <non-zero>
SOC31 RESULT: PASS
```

`CYCLE_COUNT`는 구현 상세에 따라 확인값으로 사용하고 고정 Expected 값으로 비교하지 않습니다.

## 7. 다음 단계

SoC 32에서는 Polling 중심 제어를 확장하여:

- NPU done interrupt
- AXI Interrupt Controller 연결
- command/status interrupt flow

로 진행할 수 있습니다.
