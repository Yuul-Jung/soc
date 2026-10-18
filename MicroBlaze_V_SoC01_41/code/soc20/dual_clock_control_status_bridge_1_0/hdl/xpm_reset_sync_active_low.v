module xpm_reset_sync_active_low #(
    parameter integer DEST_SYNC_FF = 4
)(
    input  wire dest_clk,
    input  wire global_resetn_i,
    output wire dest_resetn_o
);

// AMD XPM implementation.
// Active-Low reset asserts asynchronously and deasserts synchronously
// to the destination clock.

xpm_cdc_async_rst #(
    .DEST_SYNC_FF(DEST_SYNC_FF),
    .INIT_SYNC_FF(0),
    .RST_ACTIVE_HIGH(0)
) u_xpm_cdc_async_rst (
    .src_arst(global_resetn_i),
    .dest_clk(dest_clk),
    .dest_arst(dest_resetn_o)
);

endmodule
