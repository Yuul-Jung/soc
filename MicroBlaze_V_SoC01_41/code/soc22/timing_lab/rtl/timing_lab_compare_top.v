module timing_lab_compare_top (
    input  wire        clk,
    input  wire        resetn,

    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [31:0] c_i,
    input  wire [31:0] d_i,
    input  wire [31:0] e_i,
    input  wire [31:0] f_i,
    input  wire [31:0] g_i,
    input  wire [31:0] h_i,
    input  wire        valid_i,

    output wire [31:0] unpipelined_result_o,
    output wire        unpipelined_valid_o,

    output wire [31:0] pipelined_result_o,
    output wire        pipelined_valid_o
);

// Pure comparison wrapper.

timing_chain_unpipelined u_timing_chain_unpipelined (
    .clk(clk),
    .resetn(resetn),

    .a_i(a_i),
    .b_i(b_i),
    .c_i(c_i),
    .d_i(d_i),
    .e_i(e_i),
    .f_i(f_i),
    .g_i(g_i),
    .h_i(h_i),
    .valid_i(valid_i),

    .result_o(unpipelined_result_o),
    .valid_o(unpipelined_valid_o)
);

timing_chain_pipelined u_timing_chain_pipelined (
    .clk(clk),
    .resetn(resetn),

    .a_i(a_i),
    .b_i(b_i),
    .c_i(c_i),
    .d_i(d_i),
    .e_i(e_i),
    .f_i(f_i),
    .g_i(g_i),
    .h_i(h_i),
    .valid_i(valid_i),

    .result_o(pipelined_result_o),
    .valid_o(pipelined_valid_o)
);

endmodule
