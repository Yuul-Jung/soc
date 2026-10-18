module requantize_group4_parallel (
    input  wire                 clk,
    input  wire                 resetn,

    input  wire                 valid_i,
    input  wire                 tag_i,

    input  wire [127:0]         acc_group_i,

    input  wire signed [31:0]   bias_i,
    input  wire signed [15:0]   multiplier_i,
    input  wire        [5:0]    shift_i,
    input  wire signed [15:0]   zero_point_i,

    output wire                 valid_o,
    output wire                 tag_o,
    output wire [31:0]          q_group_o,
    output wire [2:0]           saturation_count_o
);

// Four identical arithmetic lanes.
// The arithmetic core itself is byte-identical to SoC 39.

wire signed [7:0] q0_w;
wire signed [7:0] q1_w;
wire signed [7:0] q2_w;
wire signed [7:0] q3_w;

wire v0_w;
wire v1_w;
wire v2_w;
wire v3_w;

wire sp0_w, sp1_w, sp2_w, sp3_w;
wire sn0_w, sn1_w, sn2_w, sn3_w;

requantize_s32_to_s8 u_lane0 (
    .clk(clk), .resetn(resetn), .valid_i(valid_i),
    .acc_i($signed(acc_group_i[31:0])),
    .bias_i(bias_i), .multiplier_i(multiplier_i),
    .shift_i(shift_i), .zero_point_i(zero_point_i),
    .valid_o(v0_w), .q_o(q0_w),
    .sat_pos_o(sp0_w), .sat_neg_o(sn0_w)
);

requantize_s32_to_s8 u_lane1 (
    .clk(clk), .resetn(resetn), .valid_i(valid_i),
    .acc_i($signed(acc_group_i[63:32])),
    .bias_i(bias_i), .multiplier_i(multiplier_i),
    .shift_i(shift_i), .zero_point_i(zero_point_i),
    .valid_o(v1_w), .q_o(q1_w),
    .sat_pos_o(sp1_w), .sat_neg_o(sn1_w)
);

requantize_s32_to_s8 u_lane2 (
    .clk(clk), .resetn(resetn), .valid_i(valid_i),
    .acc_i($signed(acc_group_i[95:64])),
    .bias_i(bias_i), .multiplier_i(multiplier_i),
    .shift_i(shift_i), .zero_point_i(zero_point_i),
    .valid_o(v2_w), .q_o(q2_w),
    .sat_pos_o(sp2_w), .sat_neg_o(sn2_w)
);

requantize_s32_to_s8 u_lane3 (
    .clk(clk), .resetn(resetn), .valid_i(valid_i),
    .acc_i($signed(acc_group_i[127:96])),
    .bias_i(bias_i), .multiplier_i(multiplier_i),
    .shift_i(shift_i), .zero_point_i(zero_point_i),
    .valid_o(v3_w), .q_o(q3_w),
    .sat_pos_o(sp3_w), .sat_neg_o(sn3_w)
);

// Four arithmetic stages -> matching tag pipeline.
reg tag_s1_q;
reg tag_s2_q;
reg tag_s3_q;
reg tag_s4_q;

always @(posedge clk) begin
    if (!resetn) begin
        tag_s1_q <= 1'b0;
        tag_s2_q <= 1'b0;
        tag_s3_q <= 1'b0;
        tag_s4_q <= 1'b0;
    end else begin
        if (valid_i)
            tag_s1_q <= tag_i;

        tag_s2_q <= tag_s1_q;
        tag_s3_q <= tag_s2_q;
        tag_s4_q <= tag_s3_q;
    end
end

assign valid_o =
    v0_w && v1_w && v2_w && v3_w;

assign tag_o = tag_s4_q;

assign q_group_o = {
    q3_w, q2_w, q1_w, q0_w
};

assign saturation_count_o =
    {2'b00, (sp0_w || sn0_w)} +
    {2'b00, (sp1_w || sn1_w)} +
    {2'b00, (sp2_w || sn2_w)} +
    {2'b00, (sp3_w || sn3_w)};

endmodule
