module prefetch_double_buffer_basys3_top (
    input  wire        clk,
    input  wire        btnC,
    output wire [15:0] led_o
);

// Pure board Shell / Wrapper.

wire resetn;

wire        load_bank;
wire        load_active;

wire        act_wr_en;
wire [7:0]  act_wr_addr;
wire [31:0] act_wr_data;

wire        weight_wr_en;
wire [7:0]  weight_wr_addr;
wire [31:0] weight_wr_data;

wire        compute_bank;
wire        start;
wire [15:0] vector_length;

wire        busy;
wire        done;
wire        result_valid;
wire signed [31:0] result;

wire [15:0] requested_groups;
wire [15:0] received_groups;
wire [15:0] delivered_groups;
wire [15:0] accepted_groups;
wire [15:0] completed_groups;

wire [2:0] fifo_count;
wire [2:0] outstanding_reads;

wire bank_conflict;
wire range_error;
wire response_mismatch_error;
wire fifo_overflow_error;

wire signed [31:0] first_result;
wire signed [31:0] second_result;
wire demo_done;

reset_active_high_to_active_low u_reset_adapter (
    .reset_i(btnC),
    .resetn_o(resetn)
);

double_buffer_demo_controller u_demo_controller (
    .clk(clk),
    .resetn(resetn),

    .load_bank_o(load_bank),
    .load_active_o(load_active),

    .act_wr_en_o(act_wr_en),
    .act_wr_addr_o(act_wr_addr),
    .act_wr_data_o(act_wr_data),

    .weight_wr_en_o(weight_wr_en),
    .weight_wr_addr_o(weight_wr_addr),
    .weight_wr_data_o(weight_wr_data),

    .compute_bank_o(compute_bank),
    .start_o(start),
    .vector_length_o(vector_length),

    .busy_i(busy),
    .done_i(done),
    .result_valid_i(result_valid),
    .result_i(result),

    .first_result_o(first_result),
    .second_result_o(second_result),
    .demo_done_o(demo_done)
);

prefetch_double_buffer_dot_accelerator #(
    .ADDR_WIDTH(8)
) u_accelerator (
    .clk(clk),
    .resetn(resetn),

    .load_bank_i(load_bank),
    .load_active_i(load_active),

    .act_wr_en_i(act_wr_en),
    .act_wr_addr_i(act_wr_addr),
    .act_wr_data_i(act_wr_data),

    .weight_wr_en_i(weight_wr_en),
    .weight_wr_addr_i(weight_wr_addr),
    .weight_wr_data_i(weight_wr_data),

    .compute_bank_i(compute_bank),
    .start_i(start),
    .vector_length_i(vector_length),

    .feed_stall_i(1'b0),

    .busy_o(busy),
    .done_o(done),
    .result_valid_o(result_valid),
    .result_o(result),

    .requested_groups_o(requested_groups),
    .received_groups_o(received_groups),
    .delivered_groups_o(delivered_groups),
    .accepted_groups_o(accepted_groups),
    .completed_groups_o(completed_groups),

    .fifo_count_o(fifo_count),
    .outstanding_reads_o(outstanding_reads),

    .bank_conflict_o(bank_conflict),
    .range_error_o(range_error),
    .response_mismatch_error_o(response_mismatch_error),
    .fifo_overflow_error_o(fifo_overflow_error)
);

double_buffer_result_sink u_result_sink (
    .clk(clk),
    .resetn(resetn),

    .result_i(result),
    .result_valid_i(result_valid),

    .led_o(led_o)
);

endmodule
