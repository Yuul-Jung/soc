module local_bram_dot_accelerator #(
    parameter integer ADDR_WIDTH = 8
) (
    input  wire                      clk,
    input  wire                      resetn,

    // Buffer load ports.
    input  wire                      act_wr_en_i,
    input  wire [ADDR_WIDTH-1:0]     act_wr_addr_i,
    input  wire [31:0]               act_wr_data_i,

    input  wire                      weight_wr_en_i,
    input  wire [ADDR_WIDTH-1:0]     weight_wr_addr_i,
    input  wire [31:0]               weight_wr_data_i,

    // Compute command.
    input  wire                      start_i,
    input  wire [15:0]               vector_length_i,

    // Status/result.
    output wire                      busy_o,
    output wire                      done_o,
    output wire                      result_valid_o,
    output wire signed [31:0]        result_o,

    // Debug/teaching status.
    output wire [15:0]               requested_groups_o,
    output wire [15:0]               delivered_groups_o,
    output wire [15:0]               accepted_groups_o,
    output wire [15:0]               completed_groups_o,

    output wire                      range_error_o
);

// Architecture:
//
// Activation BRAM ---\
//                     > BRAM feeder -> SoC26 controller/PE4 -> result
// Weight BRAM ------/
//
// Each 32-bit BRAM word contains four signed 8-bit scalar values.
//
// With ADDR_WIDTH=8:
//   depth        = 256 words
//   scalar lanes = 256 * 4 = 1024 elements
//
// Commands larger than the local-buffer capacity are rejected.

localparam [16:0] MAX_ELEMENTS_W =
    (17'd4 << ADDR_WIDTH);

wire range_error_w;
wire start_valid_w;

assign range_error_w =
    ({1'b0, vector_length_i} > MAX_ELEMENTS_W);

assign range_error_o =
    start_i && range_error_w;

assign start_valid_w =
    start_i && !range_error_w;

wire                      act_rd_en;
wire [ADDR_WIDTH-1:0]     act_rd_addr;
wire [31:0]               act_rd_data;
wire                      act_rd_valid;

wire                      weight_rd_en;
wire [ADDR_WIDTH-1:0]     weight_rd_addr;
wire [31:0]               weight_rd_data;
wire                      weight_rd_valid;

wire                      vec_valid;
wire                      vec_ready;
wire [31:0]               a_vec;
wire [31:0]               b_vec;

vector_bram_sdp #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(32)
) u_activation_bram (
    .clk(clk),
    .resetn(resetn),

    .wr_en_i(act_wr_en_i),
    .wr_addr_i(act_wr_addr_i),
    .wr_data_i(act_wr_data_i),

    .rd_en_i(act_rd_en),
    .rd_addr_i(act_rd_addr),
    .rd_data_o(act_rd_data),
    .rd_valid_o(act_rd_valid)
);

vector_bram_sdp #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(32)
) u_weight_bram (
    .clk(clk),
    .resetn(resetn),

    .wr_en_i(weight_wr_en_i),
    .wr_addr_i(weight_wr_addr_i),
    .wr_data_i(weight_wr_data_i),

    .rd_en_i(weight_rd_en),
    .rd_addr_i(weight_rd_addr),
    .rd_data_o(weight_rd_data),
    .rd_valid_o(weight_rd_valid)
);

bram_vector_feeder #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_bram_vector_feeder (
    .clk(clk),
    .resetn(resetn),

    .start_i(start_valid_w),
    .vector_length_i(vector_length_i),

    .downstream_ready_i(vec_ready),

    .act_rd_en_o(act_rd_en),
    .act_rd_addr_o(act_rd_addr),
    .act_rd_data_i(act_rd_data),
    .act_rd_valid_i(act_rd_valid),

    .weight_rd_en_o(weight_rd_en),
    .weight_rd_addr_o(weight_rd_addr),
    .weight_rd_data_i(weight_rd_data),
    .weight_rd_valid_i(weight_rd_valid),

    .vec_valid_o(vec_valid),
    .a_vec_o(a_vec),
    .b_vec_o(b_vec),

    .requested_groups_o(requested_groups_o),
    .delivered_groups_o(delivered_groups_o),
    .active_o()
);

vector_dot_controller_pe4 u_vector_controller (
    .clk(clk),
    .resetn(resetn),

    .start_i(start_valid_w),
    .vector_length_i(vector_length_i),

    .vec_valid_i(vec_valid),
    .vec_ready_o(vec_ready),
    .a_vec_i(a_vec),
    .b_vec_i(b_vec),

    .busy_o(busy_o),
    .done_o(done_o),
    .result_valid_o(result_valid_o),
    .result_o(result_o),

    .accepted_groups_o(accepted_groups_o),
    .completed_groups_o(completed_groups_o)
);

endmodule
