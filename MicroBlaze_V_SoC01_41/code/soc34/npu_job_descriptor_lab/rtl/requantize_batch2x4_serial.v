module requantize_batch2x4_serial (
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

// Serializes the 2-channel x 4-sample int32 result block from SoC 29
// through one pipelined requantization core.
//
// Feed order:
//   index 0..3 -> CH0 sample 0..3
//   index 4..7 -> CH1 sample 0..3
//
// One item is launched per clock while FEED is active.
// The requantizer itself is fully pipelined, so after startup it also
// produces one result per clock.

localparam [1:0] ST_IDLE  = 2'd0;
localparam [1:0] ST_FEED  = 2'd1;
localparam [1:0] ST_DRAIN = 2'd2;

reg [1:0] state_q;
reg [3:0] feed_index_q;
reg [3:0] output_count_q;

assign busy_o =
    (state_q != ST_IDLE);

wire core_valid_i;

assign core_valid_i =
    (state_q == ST_FEED);

wire current_is_ch1_w;
wire [1:0] current_sample_w;

assign current_is_ch1_w =
    feed_index_q[2];

assign current_sample_w =
    feed_index_q[1:0];

reg signed [31:0] selected_acc_w;

always @(*) begin
    case (feed_index_q)
        4'd0: selected_acc_w = $signed(acc_ch0_batch_i[31:0]);
        4'd1: selected_acc_w = $signed(acc_ch0_batch_i[63:32]);
        4'd2: selected_acc_w = $signed(acc_ch0_batch_i[95:64]);
        4'd3: selected_acc_w = $signed(acc_ch0_batch_i[127:96]);

        4'd4: selected_acc_w = $signed(acc_ch1_batch_i[31:0]);
        4'd5: selected_acc_w = $signed(acc_ch1_batch_i[63:32]);
        4'd6: selected_acc_w = $signed(acc_ch1_batch_i[95:64]);

        default:
            selected_acc_w = $signed(acc_ch1_batch_i[127:96]);
    endcase
end

wire signed [31:0] selected_bias_w;
wire signed [15:0] selected_mult_w;
wire        [5:0]  selected_shift_w;
wire signed [15:0] selected_zp_w;

assign selected_bias_w =
    current_is_ch1_w
    ? bias_ch1_i
    : bias_ch0_i;

assign selected_mult_w =
    current_is_ch1_w
    ? mult_ch1_i
    : mult_ch0_i;

assign selected_shift_w =
    current_is_ch1_w
    ? shift_ch1_i
    : shift_ch0_i;

assign selected_zp_w =
    current_is_ch1_w
    ? zp_ch1_i
    : zp_ch0_i;

wire              core_valid_o;
wire signed [7:0] core_q_w;
wire              core_sat_pos_w;
wire              core_sat_neg_w;

requantize_s32_to_s8 u_requantizer (
    .clk(clk),
    .resetn(resetn),

    .valid_i(core_valid_i),

    .acc_i(selected_acc_w),
    .bias_i(selected_bias_w),

    .multiplier_i(selected_mult_w),
    .shift_i(selected_shift_w),
    .zero_point_i(selected_zp_w),

    .valid_o(core_valid_o),
    .q_o(core_q_w),

    .sat_pos_o(core_sat_pos_w),
    .sat_neg_o(core_sat_neg_w)
);

// Tag pipeline matches the 4 registered stages in requantize_s32_to_s8.
reg [3:0] tag_s1_q;
reg [3:0] tag_s2_q;
reg [3:0] tag_s3_q;
reg [3:0] tag_s4_q;

reg valid_tag_s1_q;
reg valid_tag_s2_q;
reg valid_tag_s3_q;
reg valid_tag_s4_q;

always @(posedge clk) begin
    if (!resetn) begin
        tag_s1_q <= 4'd0;
        tag_s2_q <= 4'd0;
        tag_s3_q <= 4'd0;
        tag_s4_q <= 4'd0;

        valid_tag_s1_q <= 1'b0;
        valid_tag_s2_q <= 1'b0;
        valid_tag_s3_q <= 1'b0;
        valid_tag_s4_q <= 1'b0;
    end else begin
        valid_tag_s1_q <= core_valid_i;
        valid_tag_s2_q <= valid_tag_s1_q;
        valid_tag_s3_q <= valid_tag_s2_q;
        valid_tag_s4_q <= valid_tag_s3_q;

        if (core_valid_i) begin
            tag_s1_q <= feed_index_q;
        end

        if (valid_tag_s1_q) begin
            tag_s2_q <= tag_s1_q;
        end

        if (valid_tag_s2_q) begin
            tag_s3_q <= tag_s2_q;
        end

        if (valid_tag_s3_q) begin
            tag_s4_q <= tag_s3_q;
        end
    end
end

always @(posedge clk) begin
    if (!resetn) begin
        state_q             <= ST_IDLE;
        feed_index_q        <= 4'd0;
        output_count_q      <= 4'd0;

        done_o              <= 1'b0;
        result_valid_o      <= 1'b0;

        q_ch0_batch_o       <= 32'h0000_0000;
        q_ch1_batch_o       <= 32'h0000_0000;

        saturation_count_o  <= 8'd0;
    end else begin
        done_o         <= 1'b0;
        result_valid_o <= 1'b0;

        if (core_valid_o) begin
            case (tag_s4_q)
                4'd0: q_ch0_batch_o[7:0]   <= core_q_w;
                4'd1: q_ch0_batch_o[15:8]  <= core_q_w;
                4'd2: q_ch0_batch_o[23:16] <= core_q_w;
                4'd3: q_ch0_batch_o[31:24] <= core_q_w;

                4'd4: q_ch1_batch_o[7:0]   <= core_q_w;
                4'd5: q_ch1_batch_o[15:8]  <= core_q_w;
                4'd6: q_ch1_batch_o[23:16] <= core_q_w;

                default:
                    q_ch1_batch_o[31:24] <= core_q_w;
            endcase

            if (
                core_sat_pos_w ||
                core_sat_neg_w
            ) begin
                saturation_count_o <=
                    saturation_count_o + 8'd1;
            end

            output_count_q <=
                output_count_q + 4'd1;

            if (tag_s4_q == 4'd7) begin
                done_o         <= 1'b1;
                result_valid_o <= 1'b1;
                state_q        <= ST_IDLE;
            end
        end

        case (state_q)
            ST_IDLE: begin
                if (start_i) begin
                    feed_index_q       <= 4'd0;
                    output_count_q     <= 4'd0;

                    q_ch0_batch_o      <= 32'h0000_0000;
                    q_ch1_batch_o      <= 32'h0000_0000;

                    saturation_count_o <= 8'd0;

                    state_q <= ST_FEED;
                end
            end

            ST_FEED: begin
                if (feed_index_q == 4'd7) begin
                    state_q <= ST_DRAIN;
                end else begin
                    feed_index_q <=
                        feed_index_q + 4'd1;
                end
            end

            ST_DRAIN: begin
                // Wait for tag 7 to return from the 4-stage core.
            end

            default: begin
                state_q <= ST_IDLE;
            end
        endcase
    end
end

endmodule
