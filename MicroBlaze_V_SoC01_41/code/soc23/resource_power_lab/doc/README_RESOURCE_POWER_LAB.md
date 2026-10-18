# SoC 23 · Resource / Power / Thermal Lab

## 목적

SoC 22의 동일 기능 두 RTL 구조를 같은 조건으로 구현하고 다음을 비교합니다.

- LUT / Register / Carry / Clock Resource
- BRAM / LUTRAM / DSP 사용 여부
- Post-route Timing
- Static / Dynamic / Total Power
- Switching Activity
- Supply별 Current/Power
- Junction Temperature
- Thermal Margin

## 비교 조건

두 Variant에 반드시 동일하게 적용합니다.

- Device: `xc7a35tcpg236-1`
- Board: Basys3
- Clock Requirement: 100 MHz / 10 ns
- Pin Constraint
- Vivado Implementation Flow
- Power Activity Assumption
- Environment / Voltage / Process Conditions

Power 비교에서 이 조건이 다르면 숫자 비교의 의미가 약해집니다.

## Power Report 신뢰도

### 1. Vectorless / Default

Activity File 없이 Vivado의 기본 추정과 전파를 사용합니다.

장점:
- 빠름
- 초기 설계 비교에 유용

주의:
- 실제 동작 Activity와 다를 수 있음

### 2. Controlled What-If

두 Variant에 같은 Default Activity를 강제합니다.

```tcl
set_switching_activity     -default_static_probability 0.5     -default_toggle_rate 12.5
```

목적:
- 실제 절대전력 확정이 아니라 구조 비교 조건 통일

### 3. Simulation Activity

실제 Testbench에서 SAIF 등 Switching Activity를 추출해 Report Power에 반영합니다.

이 단계가 실제 Application 동작을 더 잘 반영합니다.

### 4. Hardware Correlation

실제 Board의 Current / Die Temperature와 비교합니다.

Junction Temperature는 Static Power에 큰 영향을 주므로 실제 측정 시 온도 안정화와 Operating Condition 정합이 중요합니다.

## 실행

```bash
cd resource_power_lab
chmod +x scripts/run_all_resource_power_cases.sh
./scripts/run_all_resource_power_cases.sh
```

## 핵심 비교 Report

- `03_utilization_post_route.rpt`
- `06_timing_summary_post_route.rpt`
- `07_operating_conditions.rpt`
- `09_switching_activity_normalized.rpt`
- `10_power_normalized_activity.rpt`

## 해석 원칙

Pipeline은 일반적으로 Register가 추가되지만:
- LUT Packing이 달라질 수 있고
- Route가 달라질 수 있고
- Clock Tree Load가 늘 수 있고
- Logic Glitch / Switching이 달라질 수 있으므로

실제 Dynamic Power 변화 방향을 RTL 구조만 보고 단정하지 않습니다.

Timing / Resource / Power를 함께 봅니다.
