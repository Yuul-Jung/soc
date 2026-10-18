module pe4_basic_basys3_top (
    input  wire        clk,
    input  wire        btnC,
    output wire [15:0] led_o
);

// Pure board Shell / Wrapper.

wire resetn;

wire [31:0] a_vec;
wire [31:0] b_vec;
wire        source_valid;

wire signed [31:0] acc;
wire               acc_valid;

reset_active_high_to_active_low u_reset_adapter (
    .reset_i(btnC),
    .resetn_o(resetn)
);

pe4_pattern_source u_pe4_pattern_source (
    .clk(clk),
    .resetn(resetn),
    .a_vec_o(a_vec),
    .b_vec_o(b_vec),
    .valid_o(source_valid)
);

pe4_dot_accum_basic u_pe4 (
    .clk(clk),
    .resetn(resetn),
    .clear_i(1'b0),
    .valid_i(source_valid),
    .a_vec_i(a_vec),
    .b_vec_i(b_vec),
    .acc_o(acc),
    .valid_o(acc_valid)
);

pe4_result_sink u_pe4_result_sink (
    .clk(clk),
    .resetn(resetn),
    .acc_i(acc),
    .valid_i(acc_valid),
    .led_o(led_o)
);

endmodule
