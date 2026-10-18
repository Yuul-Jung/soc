# SoC 41 · Sign-off 실행 절차

## 1. Hardware Freeze

SoC 40 최종 Hardware를 기준으로 합니다.

기능 변경 없이 Sign-off를 수행합니다.

## 2. Functional Regression

실제 HDL Simulator에서:

- JOB0
- JOB1
- JOB_ID
- Read/Write Count
- DONE IRQ/W1C
- ERROR IRQ

를 먼저 PASS시킵니다.

## 3. Vivado Implementation

Full SoC Project에서:

```tcl
open_project <project.xpr>
open_run impl_1
source scripts/collect_soc41_signoff_reports.tcl
```

생성 Report:

1. `check_timing`
2. `report_timing_summary`
3. `report_bus_skew` 가능 시
4. `report_methodology`
5. `report_drc`
6. `report_cdc` 가능 시
7. `report_utilization -hierarchical`
8. `report_clock_utilization`
9. `report_design_analysis`
10. `report_qor_assessment` 가능 시
11. `report_power`
12. Post-Route DCP

## 4. Timing Gate

최소 확인:

- WNS >= 0
- TNS = 0
- WHS >= 0
- THS = 0
- Unconstrained Path = 0
- Pulse Width Violation = 0
- Critical Timing Warning = 0

양의 Slack만 보고 끝내지 않습니다.

Constraint 자체가 정확한지 확인합니다.

## 5. Methodology / DRC / CDC

Critical Warning부터 해결합니다.

특히:

- Clock 정의
- Missing Constraint
- CDC
- Reset
- XDC
- Timing Accuracy

관련 항목을 확인합니다.

## 6. Power

Post-Route Report를 사용합니다.

반드시 함께 기록:

- Activity Source
- Voltage
- Ambient
- Airflow
- Thermal condition

설계 요구사항의 Power Budget과 비교합니다.

## 7. Basys3 Runtime

권장:

- Warm-up 10회
- 반복 측정 100회 이상
- START → ISR
- Full E2E
- min / avg / max

실제 반복 횟수와 측정 방법을 기록합니다.

## 8. JSON 입력

`data/soc41_signoff_input.json`

실제 Report 값을 입력합니다.

값을 모르면 `null`을 유지합니다.

## 9. 자동 판정

```bash
python3 scripts/evaluate_soc41_signoff.py   data/soc41_signoff_input.json
```

결과:

- PASS
- FAIL
- INCOMPLETE
- Runtime은 측정 완료 시 RECORDED

중 하나로 판정합니다.

## 10. Group 8 종료

Group 8을 닫는 조건:

- Function 확인
- Timing Sign-off
- Methodology / DRC / CDC 확인
- Resource 확인
- Power/Thermal Budget 확인
- Runtime 측정
- Sign-off Matrix 저장

정적 성능 개선만으로 Group 8을 완료 처리하지 않습니다.
