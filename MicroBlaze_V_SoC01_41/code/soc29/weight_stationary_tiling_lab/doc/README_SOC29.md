# SoC 29 · Data Reuse / Weight Stationary / Activation Broadcast / Tiling

## 1. 목표

SoC 28까지는 Memory Stall을 숨겼습니다.

SoC 29에서는 필요한 Data Movement 자체를 줄입니다.

Mini GEMM shape:

- Batch B = 4
- Output Channel M = 2
- K = 16
- K Tile = 4

수식:

`Y[B][M] = X[B][K] × W[M][K]^T`

## 2. Weight Stationary

각 K Tile마다 두 Weight Vector를 한 번 Load합니다.

- CH0 weight 4개
- CH1 weight 4개

Tile 내부에서 Batch Sample 4개를 처리하는 동안 Weight Register는 유지됩니다.

Weight scalar traffic:

- naive = `B × M × K = 128`
- stationary = `M × K = 32`
- reuse = `4×`

## 3. Activation Broadcast

한 4-Lane Activation Group을 CH0 PE Row와 CH1 PE Row에 동시에 전달합니다.

Activation scalar traffic:

- row-by-row = `B × M × K = 128`
- broadcast = `B × K = 64`
- reuse = `2×`

## 4. Tiling

K=16을 4개 Tile로 나눕니다.

- Tile0 = K 0..3
- Tile1 = K 4..7
- Tile2 = K 8..11
- Tile3 = K 12..15

각 Tile:

1. Weight Load
2. Sample 0..3 Activation Feed
3. Dot4 partial 생성
4. per-sample psum 누적

Final Tile 뒤 Result를 출력합니다.

## 5. Traffic 비교

Output/psum traffic을 제외한 교육용 Input Scalar 모델:

- naive = 256
- WS + broadcast = 96
- reduction = `256 / 96 ≈ 2.667×`

이는 실제 DDR/BRAM Energy 측정값이 아닙니다.

## 6. RTL

핵심 파일:

- `ws_dual_pe4_datapath.v`
- `ws_tiled_batch_engine.v`

Datapath:
- 2 PE rows
- each row = 4 signed 8x8 multipliers
- 8 multipliers total
- 3-stage product/reduction pipeline

Engine:
- job start
- tile start/ready
- four sample groups per tile
- per-sample psum
- final packed results

## 7. Board Demo

Weights:

- CH0 = all 1
- CH1 = all 2

Activations:

- sample0 = all 1
- sample1 = all 2
- sample2 = all 3
- sample3 = all 4

K=16.

Results:

- CH0 = [16, 32, 48, 64]
- CH1 = [32, 64, 96, 128]

LED selects:
- CH1 sample3
- expected = `128 = 0x0080`

## 8. 검증

Self-checking:
- signed deterministic weights/activations
- 4 K tiles
- 4 batch samples
- 2 output channels
- source gaps
- result comparison
- weight tile load count = 4
- activation group count = 16
- dot results = 32

Python:
- exact GEMM reference
- traffic equations
- board-demo arithmetic

## 9. Vivado

Generic OOC:

```bash
vivado -mode batch   -source scripts/run_soc29_generic_ooc.tcl
```

Board implementation:

```bash
vivado -mode batch   -source scripts/run_soc29_board_analysis.tcl
```

Simulation project:

```bash
vivado -mode batch   -source scripts/prepare_soc29_simulation.tcl
```

## 10. 다음 단계

SoC 30:
- Requantization
- Bias
- Rounding
- Saturation
- int32 accumulator → int8 output
