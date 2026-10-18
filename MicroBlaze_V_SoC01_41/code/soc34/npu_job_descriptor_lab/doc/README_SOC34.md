# SoC 34 · Command / Descriptor / Job Control

## 1. 목표

SoC 33의 고정 Tensor 주소를 Software가 지정하는 Job Descriptor 구조로 바꿉니다.

기존:

`input 0x000 → output 0x100`

SoC 34:

`INPUT_BASE + OUTPUT_BASE + LENGTH + PARAMETER → START`

## 2. Direct Job Descriptor

이번 장의 Descriptor는 AXI DMA Scatter-Gather 구조를 그대로 구현하는 것이 아닙니다.

학습용 Direct Job 구조입니다.

핵심 필드:

- INPUT_BASE
- OUTPUT_BASE
- LENGTH_WORDS
- Bias
- Multiplier
- Shift
- Zero Point
- CONTROL
- STATUS
- JOB_ID
- ERROR_CODE

## 3. Shadow / Active

Software는 Shadow Descriptor를 작성합니다.

START가 정상 수락되면:

`Shadow → Active Snapshot`

현재 Job은 Active 값만 사용합니다.

따라서 실행 중 Software가 Shadow를 다음 Job 값으로 바꿔도 현재 Job에는 영향을 주지 않습니다.

## 4. Validation

START 수락 전 확인:

- INPUT_BASE 4-byte alignment
- OUTPUT_BASE 4-byte alignment
- LENGTH_WORDS = 8
- input range inside 4 KB
- output range inside 4 KB
- input/output buffer non-overlap
- engine idle

## 5. Error Code

| Code | Meaning |
|---:|---|
| 0 | none |
| 1 | busy |
| 2 | input alignment |
| 3 | output alignment |
| 4 | unsupported length |
| 5 | input range |
| 6 | output range |
| 7 | buffer overlap |
| 8 | engine error |

## 6. LENGTH의 현재 제한

Descriptor에는 LENGTH_WORDS를 도입하지만 현재 교육용 Requantization Kernel은 8개의 int32 입력을 처리합니다.

따라서 SoC 34에서는:

`LENGTH_WORDS = 8`

만 유효합니다.

Descriptor 구조와 Kernel 계산 능력을 구분하기 위한 의도적인 단계입니다.

## 7. JOB_ID

정상 수락된 START마다 JOB_ID가 1 증가합니다.

Descriptor 검증 실패나 BUSY 중 START 거부는 JOB_ID를 증가시키지 않습니다.

## 8. Memory Map 예

Testbench:

- INPUT_BASE = 0x200
- OUTPUT_BASE = 0x300
- LENGTH_WORDS = 8

NPU 결과:

- 0x300 -> 0x20181008
- 0x304 -> 0x7F7F6333

## 9. 검증

Self-checking:

- valid descriptor
- active snapshot
- shadow update during job
- unaligned input
- unsupported length
- overlapping buffer
- out-of-range input
- rejected job does not increment JOB_ID

## 10. 다음 단계

SoC 35:

- SoC32 IRQ Control Plane
- SoC33 Tensor BRAM Data Plane
- SoC34 Job Descriptor

를 하나의 Full NPU Accelerator로 통합합니다.
