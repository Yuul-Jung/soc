module timing_lab_unpipelined_basys3_top (
    input  wire        clk,
    input  wire        btnC,
    output wire [15:0] led_o
);

// Pure board Shell / Wrapper.

wire resetn;

reset_active_high_to_active_low u_reset_polarity_adapter (
    .reset_i(btnC),
    .resetn_o(resetn)
);

timing_lab_unpipelined_impl_top u_timing_lab_impl (
    .clk(clk),
    .resetn(resetn),
    .led_o(led_o)
);

endmodule
