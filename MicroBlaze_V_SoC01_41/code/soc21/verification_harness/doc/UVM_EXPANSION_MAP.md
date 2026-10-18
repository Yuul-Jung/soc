# UVM Expansion Map

SoC 21 intentionally does not jump directly to a full UVM environment.

| SoC 21 Structure | UVM Equivalent |
|---|---|
| `axi_write/axi_read` tasks | AXI driver / VIP |
| test sequence tasks | `uvm_sequence` |
| transaction data | `uvm_sequence_item` |
| observed bus activity | monitor |
| `reference_model()` | predictor/reference model |
| `check_eq32()` | scoreboard |
| `csb_assertions.sv` | SVA checker / protocol assertions |
| `covergroup` | coverage collector/subscriber |
| directed + random tests | UVM tests/sequences |

Recommended migration order:

1. Keep the DUT unchanged.
2. Replace procedural AXI BFM tasks with a transaction driver or AMD AXI VIP.
3. Add monitor transactions.
4. Move scoreboard/reference model into reusable classes.
5. Move coverage into a subscriber/collector.
6. Add constrained-random sequences.
7. Use UVM 1.2 in Vivado Simulator when the verification scale justifies it.

The purpose of UVM is reuse and scalable verification architecture, not replacing simple tests merely because UVM is available.
