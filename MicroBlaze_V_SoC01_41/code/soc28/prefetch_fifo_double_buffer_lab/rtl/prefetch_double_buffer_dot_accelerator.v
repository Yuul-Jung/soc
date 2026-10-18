module prefetch_double_buffer_dot_accelerator #(
    parameter integer ADDR_WIDTH = 8
) (
    input  wire                      clk,
    input  wire                      resetn,

    // ---------------- Load side ----------------
    input  wire                      load_bank_i,
    input  wire                      load_active_i,

    input  wire                      act_wr_en_i,
    input  wire [ADDR_WIDTH-1:0]     act_wr_addr_i,
    input  wire [31:0]               act_wr_data_i,

    input  wire                      weight_wr_en_i,
    input  wire [ADDR_WIDTH-1:0]     weight_wr_addr_i,
    input  wire [31:0]               weight_wr_data_i,

    // ---------------- Compute command ----------------
    input  wire                      compute_bank_i,
    input  wire                      start_i,
    input  wire [15:0]               vector_length_i,

    // Teaching/test hook:
    // when high, temporarily backpressure the stream between
    // prefetch FIFO and the SoC26 vector controller.
    input  wire                      feed_stall_i,

    // ---------------- Result/status ----------------
    output wire                      busy_o,
    output wire                      done_o,
    output wire                      result_valid_o,
    output wire signed [31:0]        result_o,

    output wire [15:0]               requested_groups_o,
    output wire [15:0]               received_groups_o,
    output wire [15:0]               delivered_groups_o,
    output wire [15:0]               accepted_groups_o,
    output wire [15:0]               completed_groups_o,

    output wire [2:0]                fifo_count_o,
    output wire [2:0]                outstanding_reads_o,

    output wire                      bank_conflict_o,
    output wire                      range_error_o,
    output wire                      response_mismatch_error_o,
    output wire                      fifo_overflow_error_o
);

// SoC 28 architecture:
//
// Ping-pong local memory
//      ↓
// BRAM prefetch + credit control
//      ↓
// 64-bit elastic FIFO
//      ↓
// optional backpressure gate
//      ↓
// SoC 26 vector controller + PE4
//
// The compute-bank selection is latched on a valid start command so the
// memory bank cannot change in the middle of an operation.

localparam [16:0] MAX_ELEMENTS_W =
    (17'd4 << ADDR_WIDTH);

wire range_error_w;
wire start_valid_w;

assign range_error_w =
    ({1'b0, vector_length_i} > MAX_ELEMENTS_W);

assign range_error_o =
    start_i &&
    range_error_w;

assign start_valid_w =
    start_i &&
    !range_error_w;

reg compute_bank_q;

always @(posedge clk) begin
    if (!resetn) begin
        compute_bank_q <= 1'b0;
    end else if (start_valid_w) begin
        compute_bank_q <= compute_bank_i;
    end
end

// ---------------- Ping-pong memory ----------------
wire                      act_rd_en;
wire [ADDR_WIDTH-1:0]     act_rd_addr;
wire [31:0]               act_rd_data;
wire                      act_rd_valid;

wire                      weight_rd_en;
wire [ADDR_WIDTH-1:0]     weight_rd_addr;
wire [31:0]               weight_rd_data;
wire                      weight_rd_valid;

wire compute_active_w;

assign compute_active_w =
    busy_o ||
    start_valid_w;

pingpong_vector_memory #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_pingpong_memory (
    .clk(clk),
    .resetn(resetn),

    .load_bank_i(load_bank_i),
    .load_active_i(load_active_i),

    .act_wr_en_i(act_wr_en_i),
    .act_wr_addr_i(act_wr_addr_i),
    .act_wr_data_i(act_wr_data_i),

    .weight_wr_en_i(weight_wr_en_i),
    .weight_wr_addr_i(weight_wr_addr_i),
    .weight_wr_data_i(weight_wr_data_i),

    .compute_bank_i(compute_bank_q),
    .compute_active_i(compute_active_w),

    .act_rd_en_i(act_rd_en),
    .act_rd_addr_i(act_rd_addr),
    .act_rd_data_o(act_rd_data),
    .act_rd_valid_o(act_rd_valid),

    .weight_rd_en_i(weight_rd_en),
    .weight_rd_addr_i(weight_rd_addr),
    .weight_rd_data_o(weight_rd_data),
    .weight_rd_valid_o(weight_rd_valid),

    .bank_conflict_o(bank_conflict_o)
);

// ---------------- Prefetch FIFO feeder ----------------
wire        feeder_vec_valid;
wire [31:0] feeder_a_vec;
wire [31:0] feeder_b_vec;

wire        controller_vec_ready;
wire        feeder_downstream_ready;

assign feeder_downstream_ready =
    controller_vec_ready &&
    !feed_stall_i;

bram_prefetch_fifo_feeder #(
    .ADDR_WIDTH(ADDR_WIDTH)
) u_prefetch_feeder (
    .clk(clk),
    .resetn(resetn),

    .start_i(start_valid_w),
    .vector_length_i(vector_length_i),

    .downstream_ready_i(feeder_downstream_ready),

    .act_rd_en_o(act_rd_en),
    .act_rd_addr_o(act_rd_addr),
    .act_rd_data_i(act_rd_data),
    .act_rd_valid_i(act_rd_valid),

    .weight_rd_en_o(weight_rd_en),
    .weight_rd_addr_o(weight_rd_addr),
    .weight_rd_data_i(weight_rd_data),
    .weight_rd_valid_i(weight_rd_valid),

    .vec_valid_o(feeder_vec_valid),
    .a_vec_o(feeder_a_vec),
    .b_vec_o(feeder_b_vec),

    .requested_groups_o(requested_groups_o),
    .received_groups_o(received_groups_o),
    .delivered_groups_o(delivered_groups_o),

    .fifo_count_o(fifo_count_o),
    .outstanding_reads_o(outstanding_reads_o),

    .response_mismatch_error_o(
        response_mismatch_error_o
    ),
    .fifo_overflow_error_o(
        fifo_overflow_error_o
    ),
    .active_o()
);

// ---------------- SoC26 controller + PE4 ----------------
wire controller_vec_valid;

assign controller_vec_valid =
    feeder_vec_valid &&
    !feed_stall_i;

vector_dot_controller_pe4 u_vector_controller (
    .clk(clk),
    .resetn(resetn),

    .start_i(start_valid_w),
    .vector_length_i(vector_length_i),

    .vec_valid_i(controller_vec_valid),
    .vec_ready_o(controller_vec_ready),
    .a_vec_i(feeder_a_vec),
    .b_vec_i(feeder_b_vec),

    .busy_o(busy_o),
    .done_o(done_o),
    .result_valid_o(result_valid_o),
    .result_o(result_o),

    .accepted_groups_o(accepted_groups_o),
    .completed_groups_o(completed_groups_o)
);

endmodule
