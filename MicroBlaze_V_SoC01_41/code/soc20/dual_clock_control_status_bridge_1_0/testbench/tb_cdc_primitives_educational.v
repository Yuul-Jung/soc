`timescale 1ns / 1ps

module tb_cdc_primitives_educational;

reg src_clk = 1'b0;
reg dest_clk = 1'b0;
reg src_resetn = 1'b0;
reg dest_resetn = 1'b0;

reg async_level = 1'b0;
reg src_pulse = 1'b0;

wire sync_level;
wire dest_pulse;
wire dest_resetn_sync;

always #5 src_clk = ~src_clk;      // 100 MHz
always #7 dest_clk = ~dest_clk;    // ~71.4 MHz, unrelated phase

cdc_level_sync_educational u_level (
    .dest_clk(dest_clk),
    .async_level_i(async_level),
    .sync_level_o(sync_level)
);

cdc_pulse_toggle_educational u_pulse (
    .src_clk(src_clk),
    .src_resetn(src_resetn),
    .src_pulse_i(src_pulse),

    .dest_clk(dest_clk),
    .dest_resetn(dest_resetn),
    .dest_pulse_o(dest_pulse)
);

reset_sync_async_assert_educational u_reset (
    .clk(dest_clk),
    .arstn_i(src_resetn),
    .srstn_o(dest_resetn_sync)
);

initial begin
    #40;
    src_resetn = 1'b1;
    dest_resetn = 1'b1;

    #33;
    async_level = 1'b1;

    #100;
    async_level = 1'b0;

    @(negedge src_clk);
    src_pulse = 1'b1;
    @(negedge src_clk);
    src_pulse = 1'b0;

    // Leave a wide gap before the next pulse.
    repeat (10) @(posedge src_clk);

    @(negedge src_clk);
    src_pulse = 1'b1;
    @(negedge src_clk);
    src_pulse = 1'b0;

    #200;
    $finish;
end

endmodule
