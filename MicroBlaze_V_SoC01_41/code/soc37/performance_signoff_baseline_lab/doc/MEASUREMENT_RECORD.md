# SoC 37 · Measurement Record

이 파일은 실제 Vivado/Basys3 실행 후 숫자를 기록하는 표입니다.

## 1. Tool / Target

- Vivado Version:
- Vitis Version:
- Board: Basys3
- Device: xc7a35tcpg236-1
- Clock Target: 100 MHz
- Bitstream:
- Date:

## 2. Timing Sign-off

| Metric | Result | PASS 기준 | 근거 |
|---|---:|---:|---|
| WNS |  | >= 0 ns | post-route timing summary |
| TNS |  | 0 ns | post-route timing summary |
| WHS |  | >= 0 ns | post-route timing summary |
| THS |  | 0 ns | post-route timing summary |
| Unconstrained Paths |  | 0 | check timing |
| Pulse Width Violations |  | 0 | timing summary |

## 3. Resource

| Resource | Used | Available | Utilization |
|---|---:|---:|---:|
| LUT |  |  |  |
| FF |  |  |  |
| BRAM18/36 |  |  |  |
| DSP48E1 |  | 90 |  |
| BUFG |  |  |  |

## 4. Power / Thermal

Power는 activity, 전압, ambient, airflow 설정과 함께 기록합니다.

| Metric | Result |
|---|---:|
| Total On-Chip Power |  |
| Dynamic Power |  |
| Device Static Power |  |
| Junction Temperature |  |
| Thermal Margin |  |
| VCCINT Current |  |
| VCCAUX Current |  |

Activity source:

- [ ] Vectorless
- [ ] User toggle/static probability
- [ ] SAIF from simulation

Environment:

- Ambient:
- Airflow:
- Heat sink:
- Supply settings:

## 5. Hardware Performance

### Static RTL Schedule

- Frozen RTL expected: `engine START accept → IRQ pending = 35 cycles`
- 100 MHz 기준: `350 ns`
- 이 값은 구조상 예상값이며 실제 측정값이 아님.

### Measured

| Metric | Result |
|---|---:|
| NPU internal job cycles |  |
| NPU internal job latency |  |
| CPU START → ISR latency |  |
| CPU Tensor fill + run + result total latency |  |
| Repeated job average |  |
| Repeated job min |  |
| Repeated job max |  |

## 6. Bottleneck

- [ ] BRAM READ_REQ/READ_CAPTURE 2-cycle/word 구조
- [ ] Serial Requantizer 1-lane feed
- [ ] AXI software register overhead
- [ ] CPU Tensor copy
- [ ] Interrupt latency
- [ ] Routing / critical path
- [ ] Resource pressure
- [ ] Power / thermal

## 7. Sign-off Decision

- Timing:
- Resource:
- Power:
- Functional Regression:
- End-to-End:
- Overall:
