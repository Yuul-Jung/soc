module vector_dot_controller_basys3_top (
    input  wire        clk,
    input  wire        btnC,
    output wire [15:0] led_o
);

// Pure board Shell / Wrapper.

wire resetn;

wire        start;
wire [15:0] vector_length;

wire        vec_valid;
wire        vec_ready;
wire [31:0] a_vec;
wire [31:0] b_vec;

wire        busy;
wire        done;
wire        result_valid;
wire signed [31:0] result;

wire [15:0] accepted_groups;
wire [15:0] completed_groups;

reset_active_high_to_active_low u_reset_adapter (
    .reset_i(btnC),
    .resetn_o(resetn)
);

vector_demo_source_len10 u_demo_source (
    .clk(clk),
    .resetn(resetn),

    .start_o(start),
    .vector_length_o(vector_length),

    .vec_valid_o(vec_valid),
    .vec_ready_i(vec_ready),
    .a_vec_o(a_vec),
    .b_vec_o(b_vec),

    .done_i(done)
);

vector_dot_controller_pe4 u_controller (
    .clk(clk),
    .resetn(resetn),

    .start_i(start),
    .vector_length_i(vector_length),

    .vec_valid_i(vec_valid),
    .vec_ready_o(vec_ready),
    .a_vec_i(a_vec),
    .b_vec_i(b_vec),

    .busy_o(busy),
    .done_o(done),
    .result_valid_o(result_valid),
    .result_o(result),

    .accepted_groups_o(accepted_groups),
    .completed_groups_o(completed_groups)
);

vector_result_sink u_result_sink (
    .clk(clk),
    .resetn(resetn),

    .result_i(result),
    .result_valid_i(result_valid),

    .led_o(led_o)
);

endmodule
