module ws_tiled_batch_basys3_top (
    input  wire        clk,
    input  wire        btnC,
    output wire [15:0] led_o
);

// Pure board Shell / Wrapper.

wire resetn;

wire job_start;

wire tile_start;
wire tile_ready;
wire tile_last;

wire [31:0] weight_ch0_vec;
wire [31:0] weight_ch1_vec;

wire act_valid;
wire act_ready;
wire [1:0] act_sample_id;
wire [31:0] act_vec;

wire tile_done;
wire job_done;
wire result_valid;

wire [127:0] result_ch0_batch;
wire [127:0] result_ch1_batch;

wire [15:0] weight_tile_loads;
wire [15:0] activation_groups;
wire [15:0] dot_results;

wire demo_done;

reset_active_high_to_active_low u_reset_adapter (
    .reset_i(btnC),
    .resetn_o(resetn)
);

ws_board_demo_controller u_demo_controller (
    .clk(clk),
    .resetn(resetn),

    .job_start_o(job_start),

    .tile_start_o(tile_start),
    .tile_ready_i(tile_ready),
    .tile_last_o(tile_last),

    .weight_ch0_vec_o(weight_ch0_vec),
    .weight_ch1_vec_o(weight_ch1_vec),

    .act_valid_o(act_valid),
    .act_ready_i(act_ready),
    .act_sample_id_o(act_sample_id),
    .act_vec_o(act_vec),

    .tile_done_i(tile_done),
    .job_done_i(job_done),
    .result_valid_i(result_valid),

    .demo_done_o(demo_done)
);

ws_tiled_batch_engine u_engine (
    .clk(clk),
    .resetn(resetn),

    .job_start_i(job_start),

    .tile_start_i(tile_start),
    .tile_ready_o(tile_ready),
    .tile_last_i(tile_last),

    .weight_ch0_vec_i(weight_ch0_vec),
    .weight_ch1_vec_i(weight_ch1_vec),

    .act_valid_i(act_valid),
    .act_ready_o(act_ready),
    .act_sample_id_i(act_sample_id),
    .act_vec_i(act_vec),

    .tile_done_o(tile_done),
    .job_done_o(job_done),
    .result_valid_o(result_valid),

    .result_ch0_batch_o(result_ch0_batch),
    .result_ch1_batch_o(result_ch1_batch),

    .weight_tile_loads_o(weight_tile_loads),
    .activation_groups_o(activation_groups),
    .dot_results_o(dot_results)
);

ws_result_sink u_result_sink (
    .clk(clk),
    .resetn(resetn),

    .result_valid_i(result_valid),
    .result_ch1_batch_i(result_ch1_batch),

    .led_o(led_o)
);

endmodule
