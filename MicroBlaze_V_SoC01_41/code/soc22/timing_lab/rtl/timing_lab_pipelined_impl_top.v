module timing_lab_pipelined_impl_top (
    input  wire        clk,
    input  wire        resetn,
    output wire [15:0] led_o
);

// Pure Shell / Wrapper.
// Functional stimulus, timing chain, and output storage are separate modules.

wire [31:0] a;
wire [31:0] b;
wire [31:0] c;
wire [31:0] d;
wire [31:0] e;
wire [31:0] f;
wire [31:0] g;
wire [31:0] h;
wire        source_valid;

wire [31:0] result;
wire        result_valid;

timing_pattern_source u_timing_pattern_source (
    .clk(clk),
    .resetn(resetn),

    .a_o(a),
    .b_o(b),
    .c_o(c),
    .d_o(d),
    .e_o(e),
    .f_o(f),
    .g_o(g),
    .h_o(h),
    .valid_o(source_valid)
);

timing_chain_pipelined u_timing_chain (
    .clk(clk),
    .resetn(resetn),

    .a_i(a),
    .b_i(b),
    .c_i(c),
    .d_i(d),
    .e_i(e),
    .f_i(f),
    .g_i(g),
    .h_i(h),
    .valid_i(source_valid),

    .result_o(result),
    .valid_o(result_valid)
);

timing_result_sink u_timing_result_sink (
    .clk(clk),
    .resetn(resetn),

    .result_i(result),
    .valid_i(result_valid),

    .led_o(led_o)
);

endmodule
