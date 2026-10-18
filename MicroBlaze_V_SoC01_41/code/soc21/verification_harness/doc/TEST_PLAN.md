# SoC 21 Verification Test Plan

## DUT

`axi_control_status_bridge_demo_top`

## Verification Layers

1. Self-checking AXI4-Lite BFM tasks
2. Reference model / scoreboard
3. Directed corner cases
4. Randomized regression
5. SystemVerilog Assertions
6. Functional coverage
7. Code coverage
8. UVM migration mapping

## Directed Functional Tests

| ID | Scenario | Expected |
|---|---|---|
| T01 | ID read | `0x43534231` |
| T02 | VERSION read | `0x00010000` |
| T03 | mode0 pass-through | `out == in` |
| T04 | mode1 add1 | `out == in + 1` |
| T05 | mode2 shift-left | `out == in << 1` |
| T06 | mode3 invert | `out == ~in` |
| T07 | submit while pending | Bridge ERROR |
| T08 | POP with empty output | Bridge ERROR |
| T09 | clear error/event | Error/Event cleared |
| T10 | IRQ with event | IRQ asserted |

## Random Regression

20 randomized mode/data transactions are included in the chapter harness.
This is intentionally small for education; CI regression can increase the seed count.

## Assertions

- input data/valid stable while waiting for ready
- out_pending blocks out_ready
- empty output buffer asserts out_ready
- IRQ equals OR of EVENT_STATUS
- submit-while-pending produces error
- empty POP produces error

## Functional Coverage

- mode 0/1/2/3
- normal transaction
- submit-pending error
- empty-pop error
- clear sequence
- cross: mode x scenario

## Code Coverage

Vivado xsim 2026.1 supports:
- statement/line
- branch
- condition
- toggle

Use `-cc_type sbct`.

## Exit Criteria

Required:
- self-checking ERROR COUNT = 0
- all Assertions pass
- directed tests pass
- all four modes hit
- both illegal command corner cases hit

Educational target:
- functional coverage reviewed
- code coverage holes reviewed, not blindly forced to 100 %
