module xpm_single_bit_sync #(
    parameter integer DEST_SYNC_FF = 4
)(
    input  wire src_clk,
    input  wire src_level_i,

    input  wire dest_clk,
    output wire dest_level_o
);

// Use only for a single level signal or for independent status bits.
// Do not synchronize a coherent binary bus by instantiating one per bit.

xpm_cdc_single #(
    .DEST_SYNC_FF(DEST_SYNC_FF),
    .INIT_SYNC_FF(0),
    .SIM_ASSERT_CHK(1),
    .SRC_INPUT_REG(1)
) u_xpm_cdc_single (
    .src_clk(src_clk),
    .src_in(src_level_i),
    .dest_clk(dest_clk),
    .dest_out(dest_level_o)
);

endmodule
