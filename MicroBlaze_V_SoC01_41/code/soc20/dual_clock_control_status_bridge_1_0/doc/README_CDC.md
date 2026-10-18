# SoC 20 · CDC / Reset 안전 설계

## 1. 목적

SoC 19의 AXI Control / Status Bridge와 기능 RTL이 서로 다른 Clock Domain에서 동작할 때 필요한 CDC와 Reset 구조를 정리합니다.

## 2. 기본 선택

| 신호 종류 | 권장 방식 |
|---|---|
| 1-bit Level | XPM_CDC_SINGLE |
| 서로 독립적인 여러 1-bit Flag | 각 Bit별 Single Synchronizer 또는 XPM_CDC_ARRAY_SINGLE |
| Pulse/Event | XPM_CDC_PULSE |
| Coherent Multi-bit Bus | XPM_CDC_HANDSHAKE |
| Gray Counter/Pointer | XPM_CDC_GRAY |
| 연속 고속 Data | XPM_FIFO_ASYNC / XPM_FIFO_AXIS |
| Async Reset | XPM_CDC_ASYNC_RST |

## 3. 중요한 금지사항

- Binary Multi-bit Data에 Bit별 2-FF를 붙이지 않습니다.
- Pulse를 Level Synchronizer 하나로 넘기지 않습니다.
- Clock Domain이 다른 Logic에 Global Reset 해제를 그대로 배포하지 않습니다.
- CDC Path를 false path로 숨기는 것을 CDC 해결이라고 부르지 않습니다.
- Logic으로 만든 분주 Clock을 습관적으로 새 Clock Domain으로 사용하지 않습니다. 가능하면 Clock Enable을 사용합니다.

## 4. SoC 20 Dual-Clock Demo

AXI Domain:
- `s_axi_aclk`
- AXI4-Lite
- SoC 19 Control/Status Bridge

Functional Domain:
- `func_clk`
- `dual_clock_example_core`

Input CDC:
- `{CONTROL, IN_DATA}`를 64-bit Packet으로 묶습니다.
- XPM_CDC_HANDSHAKE 기반 Ready/Valid Wrapper로 한 번에 전달합니다.
- 따라서 Control과 Data가 같은 Snapshot으로 전달됩니다.

Output CDC:
- 32-bit Result를 XPM_CDC_HANDSHAKE로 AXI Domain에 되돌립니다.

Status CDC:
- `idle`, `busy`처럼 독립적인 1-bit Flag만 XPM_CDC_SINGLE로 되돌립니다.
- Counter나 Coherent Binary Status Bus에는 이 방식을 사용하지 않습니다.

Reset:
- `global_resetn`은 각 Domain의 XPM_CDC_ASYNC_RST를 통과합니다.
- Reset Assert는 비동기, Deassert는 각 Clock에 동기화됩니다.

## 5. report_cdc

합성 후:

```tcl
report_cdc -details -file soc20_report_cdc.rpt
report_clock_interaction -file soc20_clock_interaction.rpt
```

다음 항목을 확인합니다.

- Unknown CDC가 없는가
- Single-bit Synchronizer가 인식되는가
- Async Reset Synchronizer가 인식되는가
- Combinational Logic before Synchronizer가 없는가
- Multi-clock Fanin 문제가 없는가
- XPM_CDC_HANDSHAKE 사용 경로를 의도대로 검토했는가

## 6. XPM 권장 이유

교육용 2-FF / Toggle 구현을 함께 제공하지만, 실제 AMD FPGA 설계에서는 XPM을 우선합니다.

XPM은:
- Vivado가 CDC 구조를 인식하기 쉽고
- Synchronizer 배치/MTBF 관련 Methodology에 맞으며
- `report_cdc`와 연결하기 쉽고
- Simulation misuse check를 사용할 수 있습니다.
