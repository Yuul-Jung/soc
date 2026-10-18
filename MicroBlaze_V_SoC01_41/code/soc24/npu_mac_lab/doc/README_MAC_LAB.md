# SoC 24 · NPU Datapath / MAC 기본 구조

## 1. 목적

NPU Datapath의 최소 계산 단위인 MAC(Multiply-Accumulate)을 Basys3/Artix-7 RTL로 구현합니다.

학습 흐름:

`Signed Fixed-Point → Multiply → Accumulate → DSP48E1 Inference → Pipeline → Valid Pipeline → Self-Checking → Timing/Resource/Power`

## 2. Fixed-Point 정의

Q 표기 관습 차이로 인한 혼동을 피하기 위해 이 실습에서는 다음처럼 직접 정의합니다.

- Input width: signed 8 bit
- Fractional bits: 7
- Real value: `raw / 2^7`
- Product width: signed 16 bit
- Product fractional bits: 14
- Accumulator width: signed 32 bit
- Accumulator fractional bits: 14

예:

- raw `64` → `+0.5`
- raw `-32` → `-0.25`
- raw product `64 × -32` → `-2048`
- real product → `-2048 / 2^14 = -0.125`

Hardware에는 Binary Point Register가 별도로 존재하지 않습니다.
Binary Point 위치는 설계자가 정한 해석 규칙입니다.

## 3. MAC

수식:

`acc_next = acc + a × b`

Basic:
- Multiply와 Accumulate가 같은 MAC 구조 안에 있음
- `valid_i`가 1일 때 누산

Pipelined:
- Stage 1: Multiply + Product Register
- Stage 2: Accumulate
- `valid_i`도 `product_valid_q`로 함께 Pipeline

## 4. DSP48E1

Basys3의 XC7A35T는 DSP48E1 90개를 갖습니다.

7-Series DSP48E1:
- Multiplier: 최대 25 × 18 bit
- 48-bit ALU/Accumulator
- 내부 Pipeline Register 지원

SoC 24의 8×8 / 32-bit MAC은 이 폭 범위 안에 있습니다.

RTL에는:

```verilog
(* use_dsp = "yes" *)
```

를 사용합니다.

중요:

`USE_DSP`는 Synthesis에 DSP 사용을 지시하지만,
교육자료에서는 실제 `report_utilization`과 DSP48 Cell Report를 확인하기 전까지
“실제 DSP48E1 1개 사용”이라고 확정하지 않습니다.

## 5. Self-Checking

Testbench는 Basic과 Pipelined MAC의 Latency가 다르므로 Expected Queue를 각각 사용합니다.

Directed:
- `64 × -32`
- `127 × 127`
- `-128 × 127`
- `-128 × -128`
- `1 × -1`
- `0 × 127`

Random:
- signed 8-bit 32 Case

## 6. Vivado Analysis

```bash
cd npu_mac_lab
chmod +x scripts/run_all_mac_cases.sh
./scripts/run_all_mac_cases.sh
```

확인 순서:

1. `01_utilization_post_synth.rpt`
2. `02_dsp48_cells_post_synth.rpt`
3. `05_timing_summary_post_route.rpt`
4. `07_power_normalized_activity.rpt`

## 7. 다음 단계

SoC 25에서는 MAC 하나를 여러 개 병렬 배치하여
PE(Processing Element) / Vector Dot Product 구조로 확장합니다.
