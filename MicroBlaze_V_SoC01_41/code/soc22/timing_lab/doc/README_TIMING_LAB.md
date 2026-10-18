# SoC 22 · Timing / Critical Path / WNS / TNS

## 목적

기능적으로 정상인 RTL이 실제 Clock 주기 안에 동작하는지 Vivado Timing Engine으로 확인합니다.

핵심 흐름:

`Clock Constraint → Setup/Hold → Critical Path → WNS/TNS → Root Cause → RTL/Pipeline 개선 → Functional Regression → Post-route Signoff`

## 실습 구성

- `timing_chain_unpipelined.v`
  - 하나의 Register-to-Register Path 안에 긴 의존 연산 체인
- `timing_chain_pipelined.v`
  - 동일 연산을 두 Stage로 분할
- `timing_pattern_source.v`
  - 내부 Data 생성
- `timing_result_sink.v`
  - 결과를 Basys3 LED로 저장
- Basys3 Board Top 2개
  - Top은 연결만 수행

## Clock 실험

### 100 MHz Baseline

Clock period 10 ns.

실제 Basys3 W5 100 MHz oscillator와 동일한 정상 기준입니다.

### 200 MHz Stress Constraint

Clock period 5 ns.

이 Constraint는 **Timing Budget을 더 빡빡하게 만드는 분석 실험**입니다.
Basys3의 100 MHz Oscillator가 물리적으로 200 MHz가 되는 것이 아닙니다.

## 실행

```bash
cd timing_lab
chmod +x scripts/run_all_timing_cases.sh
./scripts/run_all_timing_cases.sh
```

4개 Case가 실행됩니다.

1. unpipelined / 10 ns
2. pipelined / 10 ns
3. unpipelined / 5 ns
4. pipelined / 5 ns

비교 기준:

`reports/*/05_timing_summary_post_route.rpt`

## Timing 해석 순서

1. Unconstrained path가 없는지 확인
2. Setup WNS / TNS 확인
3. Hold WHS / THS 확인
4. Failing Endpoints 확인
5. Worst Setup Path의 Data Path Delay 확인
6. Logic Delay vs Route Delay 비율 확인
7. Logic Levels / Fanout / Clock Skew / Uncertainty 확인
8. RTL 구조 개선 또는 Pipeline 검토
9. 다시 Implementation
10. SoC 21 Regression Harness로 기능 보존 확인

## 주의

- Synthesis Timing은 Net Delay가 추정값이므로 최종 Signoff가 아닙니다.
- 최종 판단은 Place/Route 완료 후 `report_timing_summary`로 합니다.
- `set_false_path`는 실제 비동기/무관 Path에만 사용합니다.
- `set_multicycle_path`는 기능적으로 여러 Clock을 허용하는 Path에만 사용합니다.
- Negative Slack을 숨기기 위해 Exception을 추가하지 않습니다.
