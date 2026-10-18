# SoC 33 · Vivado Tensor BRAM Block Design Guide

## 1. 목표 구조

```text
                    Control Plane
MicroBlaze V ── AXI4-Lite ── NPU Control / IRQ
     │
     │              Data Plane
     └── AXI ── AXI BRAM Controller ── Tensor BRAM Port A
                                      Tensor BRAM Port B ── NPU
```

## 2. IP 추가

- AXI BRAM Controller
- Block Memory Generator
- 기존 MicroBlaze V / SmartConnect
- SoC32 NPU Control/IRQ Path

## 3. Tensor BRAM

교육 기준:

- 4 KB
- 32-bit
- True Dual-Port RAM
- Common 100 MHz Clock
- byte-addressed system map

Port A:

- AXI BRAM Controller
- MicroBlaze V Software

Port B:

- NPU Native Port

## 4. Connection Automation 주의

AMD MicroBlaze V 2026.1 가이드는 AXI BRAM Controller와 BMG를 자동 연결하고 BMG를 True Dual-Port로 구성하는 흐름을 제공합니다.

이번 실습의 목적은 Port B를 NPU가 사용하는 것이므로 자동화 후 Port B가 AXI BRAM Controller에 모두 소비되지 않았는지 확인합니다.

권장 실습 구조:

- AXI BRAM Controller: 한 BRAM interface를 CPU-side Port A에 사용
- BMG: True Dual-Port
- BMG Port B: NPU Native Port에 수동 연결

## 5. Address Editor

Tensor BRAM의 CPU-visible Base Address를 Address Editor에서 할당합니다.

자료에서 절대 주소를 임의로 고정하지 않습니다.

Software에서는 생성된 `xparameters.h`의 Base Address를 사용합니다.

## 6. Address Unit

이 자료의 RTL Engine은 12-bit byte address를 사용합니다.

- 0x000
- 0x004
- ...
- 0x100
- 0x104

Block Memory Generator/BRAM interface의 실제 Address Width와 Byte/Word Address 설정을 Block Design에서 확인합니다.

필요하면 하위 2 bit를 Word Alignment 기준으로 처리합니다.

## 7. Collision Rule

CPU와 NPU가 같은 Tensor Address를 같은 Clock에 동시에 접근하는 상황을 만들지 않습니다.

Software ownership:

`CPU_FILL → NPU_BUSY → CPU_READ`

이 규칙은 설계의 일부입니다.

## 8. Control Plane

SoC 32의:

- START
- BUSY
- DONE/ERROR
- IRQ_ENABLE
- IRQ_STATUS

개념은 유지합니다.

SoC 33에서는 Data Plane 자체를 독립 검증합니다.

SoC 34/35에서 Control Plane과 Data Plane을 완전히 결합합니다.

## 9. 실제 확인

- Address Editor
- Validate Design
- Synthesis RAMB count
- Timing Summary
- Methodology
- Port width warnings

특히 IP Integrator에서 Port Width가 다르면 하위 bit만 연결될 수 있으므로 warning을 그대로 무시하지 말고 Address 의미를 확인합니다.
