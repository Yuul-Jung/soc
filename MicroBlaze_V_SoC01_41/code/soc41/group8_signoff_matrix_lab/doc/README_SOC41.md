# SoC 41 · Group 8 Cumulative Sign-off Matrix

## 1. 역할

SoC 41은 새 NPU 기능을 추가하는 장이 아닙니다.

SoC 37~40의 성능 개선을 하나의 Sign-off 체계로 묶습니다.

```text
SoC37 Baseline
      ↓
SoC38 BRAM Read Pipeline
      ↓
SoC39 Parallel4 Requant
      ↓
SoC40 Data/Compute Overlap
      ↓
SoC41 Sign-off Matrix
```

## 2. Static Progression

- SoC37: 35 cycles
- SoC38: 28 cycles
- SoC39: 22 cycles
- SoC40: 16 cycles

100 MHz:

- 350 ns
- 280 ns
- 220 ns
- 160 ns

Baseline 대비:

- 19 cycles 감소
- Static Latency 54.3% 감소
- Static Upper Throughput 118.8% 증가

모두 RTL Schedule입니다.

## 3. Hardware Freeze

SoC 40 Hardware를 byte-identical하게 보존합니다.

SoC 41에서는 Report, Board Measurement, Matrix만 추가합니다.

## 4. Sign-off Gate

### Functional

- JOB0/JOB1
- JOB_ID
- Counter
- DONE/W1C
- ERROR IRQ

### Timing

- WNS/TNS
- WHS/THS
- Unconstrained
- Pulse Width
- Timing Critical Warning

### Methodology

- Methodology Critical Warning
- DRC Error
- CDC Critical

### Resource

- LUT
- FF
- BRAM
- DSP

### Power

- Activity
- Total/Dynamic/Static
- Junction Temperature
- User Budget

### Runtime

- START→ISR
- Full E2E
- min/avg/max

## 5. 자동 판정

`evaluate_soc41_signoff.py`는 비어 있는 값을 PASS로 바꾸지 않습니다.

실측값이 없으면:

`INCOMPLETE`

를 반환합니다.

## 6. 다음 단계

Group 8이 실제 Sign-off까지 완료되면 다음 단계는
NPU 구조 확장 또는 이후 RISC-V 연결을 위한 시스템 아키텍처 단계로 넘어갈 수 있습니다.
