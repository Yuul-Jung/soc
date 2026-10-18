module xpm_pulse_sync (
    input  wire src_clk,
    input  wire src_reset,
    input  wire src_pulse_i,

    input  wire dest_clk,
    input  wire dest_reset,
    output wire dest_pulse_o
);

// XPM_CDC_PULSE converts a source-domain pulse to one destination-clock pulse.
// The source must obey AMD's minimum pulse-gap requirement.

xpm_cdc_pulse #(
    .DEST_SYNC_FF(4),
    .INIT_SYNC_FF(0),
    .REG_OUTPUT(1),
    .RST_USED(1),
    .SIM_ASSERT_CHK(1)
) u_xpm_cdc_pulse (
    .src_clk(src_clk),
    .src_pulse(src_pulse_i),
    .src_rst(src_reset),

    .dest_clk(dest_clk),
    .dest_pulse(dest_pulse_o),
    .dest_rst(dest_reset)
);

endmodule
