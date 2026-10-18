module requantize_batch2x4_parallel4 (
    input  wire                 clk,
    input  wire                 resetn,

    input  wire                 start_i,

    input  wire [127:0]         acc_ch0_batch_i,
    input  wire [127:0]         acc_ch1_batch_i,

    input  wire signed [31:0]   bias_ch0_i,
    input  wire signed [31:0]   bias_ch1_i,

    input  wire signed [15:0]   mult_ch0_i,
    input  wire signed [15:0]   mult_ch1_i,

    input  wire        [5:0]    shift_ch0_i,
    input  wire        [5:0]    shift_ch1_i,

    input  wire signed [15:0]   zp_ch0_i,
    input  wire signed [15:0]   zp_ch1_i,

    output wire                 busy_o,
    output reg                  done_o,
    output reg                  result_valid_o,

    output reg  [31:0]          q_ch0_batch_o,
    output reg  [31:0]          q_ch1_batch_o,

    output reg  [7:0]           saturation_count_o
);

// ------------------------------------------------------------
// SoC 39 · 4-lane Parallel Requantization
// ------------------------------------------------------------
//
// Baseline SoC 38:
//   one requant core
//   CH0[0..3], CH1[0..3] -> 8 serial feed clocks
//
// SoC 39:
//   four identical pipelined requant cores
//   clock A -> CH0 samples 0..3 in parallel
//   clock B -> CH1 samples 0..3 in parallel
//
// The arithmetic core itself is unchanged.
// The optimization changes spatial parallelism, not the formula.
//
// Requant phase reduction:
//   14 cycles -> 8 cycles
//
// Resource trade-off:
//   requant core instances 1 -> 4
//   actual DSP48/LUT/FF mapping must be measured after synthesis.

localparam [1:0] ST_IDLE     = 2'd0;
localparam [1:0] ST_FEED_CH0 = 2'd1;
localparam [1:0] ST_FEED_CH1 = 2'd2;
localparam [1:0] ST_DRAIN    = 2'd3;

reg [1:0] state_q;

assign busy_o =
    (state_q != ST_IDLE);

wire lanes_valid_i;

assign lanes_valid_i =
    (state_q == ST_FEED_CH0) ||
    (state_q == ST_FEED_CH1);

wire current_is_ch1_w;

assign current_is_ch1_w =
    (state_q == ST_FEED_CH1);

// ------------------------------------------------------------
// Four accumulator lanes.
//
// Packed-vector meaning:
// lane0 -> [31:0]
// lane1 -> [63:32]
// lane2 -> [95:64]
// lane3 -> [127:96]
// ------------------------------------------------------------
wire signed [31:0] lane_acc_0_w;
wire signed [31:0] lane_acc_1_w;
wire signed [31:0] lane_acc_2_w;
wire signed [31:0] lane_acc_3_w;

assign lane_acc_0_w =
    current_is_ch1_w
    ? $signed(acc_ch1_batch_i[31:0])
    : $signed(acc_ch0_batch_i[31:0]);

assign lane_acc_1_w =
    current_is_ch1_w
    ? $signed(acc_ch1_batch_i[63:32])
    : $signed(acc_ch0_batch_i[63:32]);

assign lane_acc_2_w =
    current_is_ch1_w
    ? $signed(acc_ch1_batch_i[95:64])
    : $signed(acc_ch0_batch_i[95:64]);

assign lane_acc_3_w =
    current_is_ch1_w
    ? $signed(acc_ch1_batch_i[127:96])
    : $signed(acc_ch0_batch_i[127:96]);

wire signed [31:0] lane_bias_w;
wire signed [15:0] lane_mult_w;
wire        [5:0]  lane_shift_w;
wire signed [15:0] lane_zp_w;

assign lane_bias_w =
    current_is_ch1_w
    ? bias_ch1_i
    : bias_ch0_i;

assign lane_mult_w =
    current_is_ch1_w
    ? mult_ch1_i
    : mult_ch0_i;

assign lane_shift_w =
    current_is_ch1_w
    ? shift_ch1_i
    : shift_ch0_i;

assign lane_zp_w =
    current_is_ch1_w
    ? zp_ch1_i
    : zp_ch0_i;

// ------------------------------------------------------------
// Four identical pipelined requantization lanes.
// ------------------------------------------------------------
wire lane0_valid_o;
wire lane1_valid_o;
wire lane2_valid_o;
wire lane3_valid_o;

wire signed [7:0] lane0_q_w;
wire signed [7:0] lane1_q_w;
wire signed [7:0] lane2_q_w;
wire signed [7:0] lane3_q_w;

wire lane0_sat_pos_w;
wire lane1_sat_pos_w;
wire lane2_sat_pos_w;
wire lane3_sat_pos_w;

wire lane0_sat_neg_w;
wire lane1_sat_neg_w;
wire lane2_sat_neg_w;
wire lane3_sat_neg_w;

requantize_s32_to_s8 u_lane0 (
    .clk(clk),
    .resetn(resetn),
    .valid_i(lanes_valid_i),
    .acc_i(lane_acc_0_w),
    .bias_i(lane_bias_w),
    .multiplier_i(lane_mult_w),
    .shift_i(lane_shift_w),
    .zero_point_i(lane_zp_w),
    .valid_o(lane0_valid_o),
    .q_o(lane0_q_w),
    .sat_pos_o(lane0_sat_pos_w),
    .sat_neg_o(lane0_sat_neg_w)
);

requantize_s32_to_s8 u_lane1 (
    .clk(clk),
    .resetn(resetn),
    .valid_i(lanes_valid_i),
    .acc_i(lane_acc_1_w),
    .bias_i(lane_bias_w),
    .multiplier_i(lane_mult_w),
    .shift_i(lane_shift_w),
    .zero_point_i(lane_zp_w),
    .valid_o(lane1_valid_o),
    .q_o(lane1_q_w),
    .sat_pos_o(lane1_sat_pos_w),
    .sat_neg_o(lane1_sat_neg_w)
);

requantize_s32_to_s8 u_lane2 (
    .clk(clk),
    .resetn(resetn),
    .valid_i(lanes_valid_i),
    .acc_i(lane_acc_2_w),
    .bias_i(lane_bias_w),
    .multiplier_i(lane_mult_w),
    .shift_i(lane_shift_w),
    .zero_point_i(lane_zp_w),
    .valid_o(lane2_valid_o),
    .q_o(lane2_q_w),
    .sat_pos_o(lane2_sat_pos_w),
    .sat_neg_o(lane2_sat_neg_w)
);

requantize_s32_to_s8 u_lane3 (
    .clk(clk),
    .resetn(resetn),
    .valid_i(lanes_valid_i),
    .acc_i(lane_acc_3_w),
    .bias_i(lane_bias_w),
    .multiplier_i(lane_mult_w),
    .shift_i(lane_shift_w),
    .zero_point_i(lane_zp_w),
    .valid_o(lane3_valid_o),
    .q_o(lane3_q_w),
    .sat_pos_o(lane3_sat_pos_w),
    .sat_neg_o(lane3_sat_neg_w)
);

// All four lanes share the same valid schedule.
// Keep an explicit check signal for readability.
wire all_lanes_valid_o;

assign all_lanes_valid_o =
    lane0_valid_o &&
    lane1_valid_o &&
    lane2_valid_o &&
    lane3_valid_o;

// ------------------------------------------------------------
// Channel tag pipeline.
//
// The core has four registered stages.
// tag=0 -> CH0 group
// tag=1 -> CH1 group
// ------------------------------------------------------------
reg group_tag_s1_q;
reg group_tag_s2_q;
reg group_tag_s3_q;
reg group_tag_s4_q;

reg valid_tag_s1_q;
reg valid_tag_s2_q;
reg valid_tag_s3_q;
reg valid_tag_s4_q;

always @(posedge clk) begin
    if (!resetn) begin
        group_tag_s1_q <= 1'b0;
        group_tag_s2_q <= 1'b0;
        group_tag_s3_q <= 1'b0;
        group_tag_s4_q <= 1'b0;

        valid_tag_s1_q <= 1'b0;
        valid_tag_s2_q <= 1'b0;
        valid_tag_s3_q <= 1'b0;
        valid_tag_s4_q <= 1'b0;
    end else begin
        valid_tag_s1_q <= lanes_valid_i;
        valid_tag_s2_q <= valid_tag_s1_q;
        valid_tag_s3_q <= valid_tag_s2_q;
        valid_tag_s4_q <= valid_tag_s3_q;

        if (lanes_valid_i) begin
            group_tag_s1_q <= current_is_ch1_w;
        end

        if (valid_tag_s1_q) begin
            group_tag_s2_q <= group_tag_s1_q;
        end

        if (valid_tag_s2_q) begin
            group_tag_s3_q <= group_tag_s2_q;
        end

        if (valid_tag_s3_q) begin
            group_tag_s4_q <= group_tag_s3_q;
        end
    end
end

// ------------------------------------------------------------
// Saturation count for the four current outputs.
// ------------------------------------------------------------
wire [2:0] lane_sat_count_w;

assign lane_sat_count_w =
    {2'b00, (lane0_sat_pos_w || lane0_sat_neg_w)} +
    {2'b00, (lane1_sat_pos_w || lane1_sat_neg_w)} +
    {2'b00, (lane2_sat_pos_w || lane2_sat_neg_w)} +
    {2'b00, (lane3_sat_pos_w || lane3_sat_neg_w)};

// ------------------------------------------------------------
// Batch control / result collection.
// ------------------------------------------------------------
always @(posedge clk) begin
    if (!resetn) begin
        state_q <= ST_IDLE;

        done_o <= 1'b0;
        result_valid_o <= 1'b0;

        q_ch0_batch_o <= 32'h0000_0000;
        q_ch1_batch_o <= 32'h0000_0000;

        saturation_count_o <= 8'd0;
    end else begin
        done_o <= 1'b0;
        result_valid_o <= 1'b0;

        if (
            all_lanes_valid_o &&
            valid_tag_s4_q
        ) begin
            if (!group_tag_s4_q) begin
                q_ch0_batch_o <= {
                    lane3_q_w,
                    lane2_q_w,
                    lane1_q_w,
                    lane0_q_w
                };
            end else begin
                q_ch1_batch_o <= {
                    lane3_q_w,
                    lane2_q_w,
                    lane1_q_w,
                    lane0_q_w
                };

                done_o <= 1'b1;
                result_valid_o <= 1'b1;
                state_q <= ST_IDLE;
            end

            saturation_count_o <=
                saturation_count_o +
                {5'd0, lane_sat_count_w};
        end

        case (state_q)
            ST_IDLE: begin
                if (start_i) begin
                    q_ch0_batch_o <= 32'h0000_0000;
                    q_ch1_batch_o <= 32'h0000_0000;
                    saturation_count_o <= 8'd0;

                    state_q <= ST_FEED_CH0;
                end
            end

            ST_FEED_CH0: begin
                state_q <= ST_FEED_CH1;
            end

            ST_FEED_CH1: begin
                state_q <= ST_DRAIN;
            end

            ST_DRAIN: begin
                // Wait for CH0 then CH1 to return from the four lanes.
            end

            default: begin
                state_q <= ST_IDLE;
            end
        endcase
    end
end

endmodule
