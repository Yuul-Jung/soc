module mac_pipelined_basys3_top (
    input  wire        clk,
    input  wire        btnC,
    output wire [15:0] led_o
);

// Pure board Shell / Wrapper.

wire resetn;

wire signed [7:0] a;
wire signed [7:0] b;
wire              source_valid;

wire signed [31:0] acc;
wire               acc_valid;

reset_active_high_to_active_low u_reset_adapter (
    .reset_i(btnC),
    .resetn_o(resetn)
);

mac_pattern_source u_mac_pattern_source (
    .clk(clk),
    .resetn(resetn),

    .a_o(a),
    .b_o(b),
    .valid_o(source_valid)
);

mac_s8_acc32_pipelined u_mac (
    .clk(clk),
    .resetn(resetn),
    .clear_i(1'b0),
    .valid_i(source_valid),

    .a_i(a),
    .b_i(b),

    .acc_o(acc),
    .valid_o(acc_valid)
);

mac_result_sink u_mac_result_sink (
    .clk(clk),
    .resetn(resetn),

    .acc_i(acc),
    .valid_i(acc_valid),

    .led_o(led_o)
);

endmodule
