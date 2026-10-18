# SoC 22 Functional + Timing Test Plan

## Functional Gate

`tb_timing_lab_compare.sv`

검증 항목:
- Unpipelined 결과와 Reference Model 비교
- Pipelined 결과와 Reference Model 비교
- 서로 다른 Pipeline Latency를 독립 Queue로 검증
- Directed 2 Case
- Random 20 Case
- Error Count = 0

## Timing Gate

각 Variant에 대해:

- 10 ns baseline
- 5 ns stress

생성 Report:
1. Methodology after synthesis
2. Timing Summary after synthesis
3. Design Analysis after synthesis
4. Timing Summary after place
5. Timing Summary after route
6. Worst setup paths
7. Worst hold paths
8. Design Analysis after route
9. QoR Suggestions
10. Utilization
11. Clock Interaction
12. Methodology after route

## 최종 Signoff 기준

- 실제 요구 Clock에 대한 Post-route Timing Summary
- Setup violation 없음
- Hold violation 없음
- Unconstrained path 검토 완료
- Methodology Critical Warning 검토 완료
- Functional Regression PASS

5 ns Stress Case는 교육용 비교이며 제품 요구사항이 아닙니다.
