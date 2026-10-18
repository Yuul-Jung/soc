module local_bram_dot_basys3_top (
    input  wire        clk,
    input  wire        btnC,
    output wire [15:0] led_o
);

// Pure board Shell / Wrapper.

wire resetn;

wire        act_wr_en;
wire [7:0]  act_wr_addr;
wire [31:0] act_wr_data;

wire        weight_wr_en;
wire [7:0]  weight_wr_addr;
wire [31:0] weight_wr_data;

wire        start;
wire [15:0] vector_length;

wire        busy;
wire        done;
wire        result_valid;
wire signed [31:0] result;

wire [15:0] requested_groups;
wire [15:0] delivered_groups;
wire [15:0] accepted_groups;
wire [15:0] completed_groups;
wire        range_error;

reset_active_high_to_active_low u_reset_adapter (
    .reset_i(btnC),
    .resetn_o(resetn)
);

local_bram_demo_loader_len10 u_demo_loader (
    .clk(clk),
    .resetn(resetn),

    .act_wr_en_o(act_wr_en),
    .act_wr_addr_o(act_wr_addr),
    .act_wr_data_o(act_wr_data),

    .weight_wr_en_o(weight_wr_en),
    .weight_wr_addr_o(weight_wr_addr),
    .weight_wr_data_o(weight_wr_data),

    .start_o(start),
    .vector_length_o(vector_length),

    .done_i(done)
);

local_bram_dot_accelerator #(
    .ADDR_WIDTH(8)
) u_accelerator (
    .clk(clk),
    .resetn(resetn),

    .act_wr_en_i(act_wr_en),
    .act_wr_addr_i(act_wr_addr),
    .act_wr_data_i(act_wr_data),

    .weight_wr_en_i(weight_wr_en),
    .weight_wr_addr_i(weight_wr_addr),
    .weight_wr_data_i(weight_wr_data),

    .start_i(start),
    .vector_length_i(vector_length),

    .busy_o(busy),
    .done_o(done),
    .result_valid_o(result_valid),
    .result_o(result),

    .requested_groups_o(requested_groups),
    .delivered_groups_o(delivered_groups),
    .accepted_groups_o(accepted_groups),
    .completed_groups_o(completed_groups),

    .range_error_o(range_error)
);

local_bram_result_sink u_result_sink (
    .clk(clk),
    .resetn(resetn),

    .result_i(result),
    .result_valid_i(result_valid),

    .led_o(led_o)
);

endmodule
