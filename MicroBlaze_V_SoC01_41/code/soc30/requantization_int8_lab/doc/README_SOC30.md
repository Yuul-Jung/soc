# SoC 30 · Bias / Requantization / Rounding / Saturation / int8 Output

## 1. 목표

SoC 29의 int32 Accumulator 결과를 다음 Layer에서 다시 사용할 수 있는 signed int8 Tensor로 변환합니다.

교육용 수식:

`q = saturate_int8(round_away_from_zero((acc + bias) × multiplier / 2^shift) + zero_point)`

## 2. Bit Width

- acc: signed 32 bit
- bias: signed 32 bit
- acc+bias: signed 33 bit
- multiplier: signed 16 bit
- product: signed 49 bit
- output: signed int8

32-bit add를 그대로 사용하면 `acc+bias`에서 Overflow가 날 수 있으므로 33 bit로 확장합니다.

## 3. Rounding

Magnitude-domain rounding:

1. sign 분리
2. 절댓값 계산
3. `2^(shift-1)` 추가
4. right shift
5. sign 복원

정책:

- +1.5 → +2
- -1.5 → -2
- +0.5 → +1
- -0.5 → -1

## 4. Saturation

signed int8:

- 최대 +127
- 최소 -128

범위를 넘으면 Wrap하지 않고 포화합니다.

## 5. Zero Point

이번 RTL은 signed int8 output을 기준으로 zero point를 파라미터로 받습니다.

대칭 양자화에서는 보통 `zero_point=0`을 사용할 수 있습니다.

## 6. Pipeline

- S1 Bias
- S2 Scale Multiply
- S3 Round/Shift
- S4 Zero Point + Saturation

Valid도 같은 Stage로 이동합니다.

## 7. Batch Wrapper

SoC 29의 2채널 × 4샘플 int32 결과 8개를 하나의 Pipelined Core에 연속 투입합니다.

Feed:
- CH0 sample0..3
- CH1 sample0..3

Tag도 Pipeline으로 이동해 Output을 원래 위치에 다시 조립합니다.

## 8. Board Demo

SoC 29 결과:

- CH0 = [16,32,48,64]
- CH1 = [32,64,96,128]

CH0:
- bias = 0
- multiplier = 1
- shift = 1
- zero point = 0
- result = [8,16,24,32]

CH1:
- bias = 4
- multiplier = 3
- shift = 1
- zero point = -3
- result = [51,99,127,127]

Saturation count = 2.

LED:
- high byte = CH0 sample3 = 0x20
- low byte = CH1 sample3 = 0x7F
- final = `0x207F`

## 9. 실제 양자화 구현과의 관계

실제 integer-only inference에서는 학습/변환 단계에서 real scale을 integer multiplier와 shift로 근사합니다.

gemmlowp/TensorFlow 계열 구현은 int32 누산값을 fixed-point multiplier, rounding shift, output offset, clamp 단계를 통해 8-bit 범위로 내립니다.

이번 RTL은 교육용으로 16-bit multiplier / power-of-two shift 형태를 사용합니다.

## 10. 다음 단계

SoC 31:
- NPU register map
- input/output buffer control
- start/busy/done
- MicroBlaze V ↔ NPU accelerator integration
