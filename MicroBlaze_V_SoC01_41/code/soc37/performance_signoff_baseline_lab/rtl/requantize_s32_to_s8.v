module requantize_s32_to_s8 (
    input  wire                 clk,
    input  wire                 resetn,

    input  wire                 valid_i,

    input  wire signed [31:0]   acc_i,
    input  wire signed [31:0]   bias_i,

    input  wire signed [15:0]   multiplier_i,
    input  wire        [5:0]    shift_i,
    input  wire signed [15:0]   zero_point_i,

    output reg                  valid_o,
    output reg signed [7:0]     q_o,

    output reg                  sat_pos_o,
    output reg                  sat_neg_o
);

// Educational integer-only requantization core.
//
// Formula:
//
//   biased = acc + bias
//
//   scaled_product = biased * multiplier
//
//   rounded = round_away_from_zero(
//       scaled_product / 2^shift
//   )
//
//   shifted = rounded + zero_point
//
//   q = saturate_to_int8(shifted)
//
// Notes:
// - acc+bias uses 33 bits to preserve the full signed sum.
// - 33x16 multiply produces a signed 49-bit product.
// - multiplier is normally positive for NN requantization.
// - shift=0 means no right shift and no rounding offset.
// - rounding policy is explicitly symmetric:
//     +0.5 -> +1
//     -0.5 -> -1
// - saturation range is signed int8: -128..127.
//
// Pipeline:
//   S1 : bias add + parameter capture
//   S2 : fixed-point multiply
//   S3 : symmetric rounding/right shift
//   S4 : zero-point add + int8 saturation

// ---------------- Stage 1: bias ----------------
reg signed [32:0] biased_s1_q;
reg signed [15:0] mult_s1_q;
reg        [5:0]  shift_s1_q;
reg signed [15:0] zp_s1_q;
reg               valid_s1_q;

wire signed [32:0] biased_w;

assign biased_w =
    $signed({acc_i[31], acc_i}) +
    $signed({bias_i[31], bias_i});

always @(posedge clk) begin
    if (!resetn) begin
        biased_s1_q <= 33'sd0;
        mult_s1_q   <= 16'sd0;
        shift_s1_q  <= 6'd0;
        zp_s1_q     <= 16'sd0;
        valid_s1_q  <= 1'b0;
    end else begin
        valid_s1_q <= valid_i;

        if (valid_i) begin
            biased_s1_q <= biased_w;
            mult_s1_q   <= multiplier_i;
            shift_s1_q  <= shift_i;
            zp_s1_q     <= zero_point_i;
        end
    end
end

// ---------------- Stage 2: scale multiply ----------------
(* use_dsp = "yes" *)
wire signed [48:0] product_w;

assign product_w =
    biased_s1_q *
    mult_s1_q;

reg signed [48:0] product_s2_q;
reg        [5:0]  shift_s2_q;
reg signed [15:0] zp_s2_q;
reg               valid_s2_q;

always @(posedge clk) begin
    if (!resetn) begin
        product_s2_q <= 49'sd0;
        shift_s2_q   <= 6'd0;
        zp_s2_q      <= 16'sd0;
        valid_s2_q   <= 1'b0;
    end else begin
        valid_s2_q <= valid_s1_q;

        if (valid_s1_q) begin
            product_s2_q <= product_w;
            shift_s2_q   <= shift_s1_q;
            zp_s2_q      <= zp_s1_q;
        end
    end
end

// ---------------- Stage 3: symmetric rounding ----------------
//
// Magnitude-domain rounding avoids the common bug where adding the
// same positive rounding constant to negative two's-complement values
// rounds midpoint cases toward zero instead of away from zero.

wire product_negative_w;

assign product_negative_w =
    product_s2_q[48];

wire [48:0] product_magnitude_w;

assign product_magnitude_w =
    product_negative_w
    ? $unsigned(-product_s2_q)
    : $unsigned(product_s2_q);

wire [48:0] rounding_add_w;

assign rounding_add_w =
    (shift_s2_q == 6'd0)
    ? 49'd0
    : (49'd1 << (shift_s2_q - 6'd1));

wire [49:0] rounded_magnitude_extended_w;

assign rounded_magnitude_extended_w =
    {1'b0, product_magnitude_w} +
    {1'b0, rounding_add_w};

wire [49:0] shifted_magnitude_w;

assign shifted_magnitude_w =
    rounded_magnitude_extended_w >>
    shift_s2_q;

wire signed [50:0] rounded_signed_w;

assign rounded_signed_w =
    product_negative_w
    ? -$signed({1'b0, shifted_magnitude_w})
    :  $signed({1'b0, shifted_magnitude_w});

reg signed [50:0] rounded_s3_q;
reg signed [15:0] zp_s3_q;
reg               valid_s3_q;

always @(posedge clk) begin
    if (!resetn) begin
        rounded_s3_q <= 51'sd0;
        zp_s3_q      <= 16'sd0;
        valid_s3_q   <= 1'b0;
    end else begin
        valid_s3_q <= valid_s2_q;

        if (valid_s2_q) begin
            rounded_s3_q <= rounded_signed_w;
            zp_s3_q      <= zp_s2_q;
        end
    end
end

// ---------------- Stage 4: zero point + saturation ----------------
wire signed [51:0] shifted_with_zp_w;

assign shifted_with_zp_w =
    $signed({rounded_s3_q[50], rounded_s3_q}) +
    $signed({
        {36{zp_s3_q[15]}},
        zp_s3_q
    });

wire sat_pos_w;
wire sat_neg_w;

assign sat_pos_w =
    (shifted_with_zp_w > 52'sd127);

assign sat_neg_w =
    (shifted_with_zp_w < -52'sd128);

wire signed [7:0] saturated_w;

assign saturated_w =
    sat_pos_w
    ? 8'sd127
    : sat_neg_w
      ? -8'sd128
      : shifted_with_zp_w[7:0];

always @(posedge clk) begin
    if (!resetn) begin
        q_o       <= 8'sd0;
        valid_o   <= 1'b0;
        sat_pos_o <= 1'b0;
        sat_neg_o <= 1'b0;
    end else begin
        valid_o <= valid_s3_q;

        if (valid_s3_q) begin
            q_o       <= saturated_w;
            sat_pos_o <= sat_pos_w;
            sat_neg_o <= sat_neg_w;
        end else begin
            sat_pos_o <= 1'b0;
            sat_neg_o <= 1'b0;
        end
    end
end

endmodule
