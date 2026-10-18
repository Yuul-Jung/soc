# SoC 37 · Performance Baseline / Timing / Resource / Power / Throughput

## 1. 목표

Group 8의 첫 장입니다.

SoC 35~36에서 완성한 NPU Hardware를 수정하지 않고,
현재 설계의 성능 기준선을 수치화합니다.

분석 축:

1. RTL Static Cycle Schedule
2. Post-Route Timing Sign-off
3. Resource Utilization
4. Power / Thermal Estimate
5. CPU-visible End-to-End Latency
6. Bottleneck Classification

## 2. 측정값을 섞지 않는다

### RTL Schedule

Frozen RTL 구조에서 계산한 Clock Cycle 예상값입니다.

`engine START accept → IRQ pending = 35 cycles`

100 MHz:

`35 × 10 ns → 350 ns`

이 값은 실제 FPGA 실측값이 아닙니다.

### Vivado Timing

Post-Route:

- WNS
- TNS
- WHS
- THS
- Unconstrained Path
- Pulse Width

를 확인합니다.

### CPU End-to-End

실제 보드에서:

- CPU Tensor Fill
- Descriptor Write
- AXI START
- NPU
- AXI Interrupt Controller
- ISR
- Output Read
- Verify

까지 포함한 Latency를 별도 측정합니다.

## 3. Static Cycle Schedule

현재 Frozen RTL:

### BRAM Read

8 Word × 2 State:

`READ_REQ → READ_CAPTURE`

따라서:

`16 cycles`

### Requantization

Job Engine handoff + 8-item serial feed + 4-stage pipeline drain:

`14 cycles`

### Finish / IRQ

Result handoff + 2 Output Write + DONE + IRQ latch:

`5 cycles`

### 합계

`16 + 14 + 5 → 35 cycles`

## 4. Static Upper Bound

100 MHz에서 단순 계산:

- 약 2.857 M job/s
- 약 22.857 M scalar output/s

단, 다음은 제외합니다.

- AXI START transaction
- CPU Tensor copy
- ISR
- Software
- 다음 Job 준비
- Full SoC arbitration

따라서 실측 Throughput으로 사용하지 않습니다.

## 5. Timing Sign-off

AMD UG906의 Post-Implementation Timing Summary를 기준으로 확인합니다.

PASS 최소 기준:

- WNS >= 0
- TNS = 0
- WHS >= 0
- THS = 0
- Unconstrained Path = 0
- Critical Timing Warning 해결

## 6. Resource

확인:

- LUT
- FF
- BRAM
- DSP48E1
- Clocking

Isolated NPU Report와 Full SoC Report를 분리합니다.

## 7. Power

Power 결과에는 반드시 함께 기록합니다.

- Activity source
- Supply voltage
- Ambient
- Airflow
- Thermal configuration

Vectorless Power를 실제 소비전력으로 표현하지 않습니다.

## 8. Scripts

### Isolated NPU

`run_soc37_npu_post_route.tcl`

NPU IP만:

- synth
- opt
- place
- phys_opt
- route
- timing
- utilization
- clock
- methodology
- DRC
- vectorless power

를 생성합니다.

### Full SoC

`collect_soc37_full_system_reports.tcl`

사용법:

```tcl
open_project <project.xpr>
open_run impl_1
source collect_soc37_full_system_reports.tcl
```

## 9. Cycle Regression

`tb_soc37_cycle_baseline.sv`

기존 기능 Regression에 다음을 추가합니다.

- JOB0 `job_start → IRQ = 35 cycles`
- JOB1 `job_start → IRQ = 35 cycles`

실제 Simulator가 설치된 환경에서 확인합니다.

## 10. Runtime Measurement

실제 CPU 관측 성능은 AXI Timer 같은 독립 Timer로 측정합니다.

권장 구간:

- NPU Start → ISR
- Tensor Fill → Result Verify

UART Print는 측정구간 밖에 둡니다.

## 11. Measurement Record

`MEASUREMENT_RECORD.md`

실제 Vivado/Basys3 측정 후 결과를 기록합니다.

## 12. 다음 단계

SoC 38에서는 SoC 37 결과를 기준으로
가장 큰 Bottleneck을 선정하고 구조적 개선 전/후를 비교합니다.
