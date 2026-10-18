module requantization_basys3_top (
    input  wire        clk,
    input  wire        btnC,
    output wire [15:0] led_o
);

// Pure board Shell / Wrapper.

wire resetn;
wire start;

wire [127:0] acc_ch0_batch;
wire [127:0] acc_ch1_batch;

wire signed [31:0] bias_ch0;
wire signed [31:0] bias_ch1;

wire signed [15:0] mult_ch0;
wire signed [15:0] mult_ch1;

wire [5:0] shift_ch0;
wire [5:0] shift_ch1;

wire signed [15:0] zp_ch0;
wire signed [15:0] zp_ch1;

wire busy;
wire done;
wire result_valid;

wire [31:0] q_ch0_batch;
wire [31:0] q_ch1_batch;

wire [7:0] saturation_count;

reset_active_high_to_active_low u_reset_adapter (
    .reset_i(btnC),
    .resetn_o(resetn)
);

soc29_result_demo_source u_demo_source (
    .clk(clk),
    .resetn(resetn),

    .start_o(start),

    .acc_ch0_batch_o(acc_ch0_batch),
    .acc_ch1_batch_o(acc_ch1_batch),

    .bias_ch0_o(bias_ch0),
    .bias_ch1_o(bias_ch1),

    .mult_ch0_o(mult_ch0),
    .mult_ch1_o(mult_ch1),

    .shift_ch0_o(shift_ch0),
    .shift_ch1_o(shift_ch1),

    .zp_ch0_o(zp_ch0),
    .zp_ch1_o(zp_ch1),

    .done_i(done)
);

requantize_batch2x4_serial u_requant_batch (
    .clk(clk),
    .resetn(resetn),

    .start_i(start),

    .acc_ch0_batch_i(acc_ch0_batch),
    .acc_ch1_batch_i(acc_ch1_batch),

    .bias_ch0_i(bias_ch0),
    .bias_ch1_i(bias_ch1),

    .mult_ch0_i(mult_ch0),
    .mult_ch1_i(mult_ch1),

    .shift_ch0_i(shift_ch0),
    .shift_ch1_i(shift_ch1),

    .zp_ch0_i(zp_ch0),
    .zp_ch1_i(zp_ch1),

    .busy_o(busy),
    .done_o(done),
    .result_valid_o(result_valid),

    .q_ch0_batch_o(q_ch0_batch),
    .q_ch1_batch_o(q_ch1_batch),

    .saturation_count_o(saturation_count)
);

requant_result_sink u_result_sink (
    .clk(clk),
    .resetn(resetn),

    .result_valid_i(result_valid),

    .q_ch0_batch_i(q_ch0_batch),
    .q_ch1_batch_i(q_ch1_batch),

    .led_o(led_o)
);

endmodule
