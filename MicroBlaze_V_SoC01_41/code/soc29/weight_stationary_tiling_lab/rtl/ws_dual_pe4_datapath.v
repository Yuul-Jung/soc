module ws_dual_pe4_datapath (
    input  wire               clk,
    input  wire               resetn,

    input  wire               load_weights_i,
    input  wire [31:0]        weight_ch0_vec_i,
    input  wire [31:0]        weight_ch1_vec_i,

    input  wire               act_valid_i,
    input  wire [1:0]         sample_id_i,
    input  wire [31:0]        act_vec_i,

    output reg                dot_valid_o,
    output reg  [1:0]         sample_id_o,
    output reg signed [17:0]  dot_ch0_o,
    output reg signed [17:0]  dot_ch1_o,

    output reg                weights_loaded_o
);

// Mini weight-stationary datapath.
//
// Two output-channel PE rows:
//   CH0: 4 stationary weights
//   CH1: 4 stationary weights
//
// One 4-lane activation group is broadcast to both PE rows.
//
// Pipeline:
//   Stage 1: 8 signed 8x8 products
//   Stage 2: pair sums
//   Stage 3: final dot4 sums
//
// Weight registers remain unchanged while multiple activation
// sample groups pass through the PE rows.

reg [31:0] weight_ch0_q;
reg [31:0] weight_ch1_q;

always @(posedge clk) begin
    if (!resetn) begin
        weight_ch0_q    <= 32'h0000_0000;
        weight_ch1_q    <= 32'h0000_0000;
        weights_loaded_o<= 1'b0;
    end else if (load_weights_i) begin
        weight_ch0_q    <= weight_ch0_vec_i;
        weight_ch1_q    <= weight_ch1_vec_i;
        weights_loaded_o<= 1'b1;
    end
end

wire signed [7:0] a0;
wire signed [7:0] a1;
wire signed [7:0] a2;
wire signed [7:0] a3;

assign a0 = $signed(act_vec_i[7:0]);
assign a1 = $signed(act_vec_i[15:8]);
assign a2 = $signed(act_vec_i[23:16]);
assign a3 = $signed(act_vec_i[31:24]);

wire signed [7:0] w00;
wire signed [7:0] w01;
wire signed [7:0] w02;
wire signed [7:0] w03;

wire signed [7:0] w10;
wire signed [7:0] w11;
wire signed [7:0] w12;
wire signed [7:0] w13;

assign w00 = $signed(weight_ch0_q[7:0]);
assign w01 = $signed(weight_ch0_q[15:8]);
assign w02 = $signed(weight_ch0_q[23:16]);
assign w03 = $signed(weight_ch0_q[31:24]);

assign w10 = $signed(weight_ch1_q[7:0]);
assign w11 = $signed(weight_ch1_q[15:8]);
assign w12 = $signed(weight_ch1_q[23:16]);
assign w13 = $signed(weight_ch1_q[31:24]);

wire signed [15:0] p00_w;
wire signed [15:0] p01_w;
wire signed [15:0] p02_w;
wire signed [15:0] p03_w;

wire signed [15:0] p10_w;
wire signed [15:0] p11_w;
wire signed [15:0] p12_w;
wire signed [15:0] p13_w;

mul_s8_dsp u_mul00 (.a_i(a0), .b_i(w00), .p_o(p00_w));
mul_s8_dsp u_mul01 (.a_i(a1), .b_i(w01), .p_o(p01_w));
mul_s8_dsp u_mul02 (.a_i(a2), .b_i(w02), .p_o(p02_w));
mul_s8_dsp u_mul03 (.a_i(a3), .b_i(w03), .p_o(p03_w));

mul_s8_dsp u_mul10 (.a_i(a0), .b_i(w10), .p_o(p10_w));
mul_s8_dsp u_mul11 (.a_i(a1), .b_i(w11), .p_o(p11_w));
mul_s8_dsp u_mul12 (.a_i(a2), .b_i(w12), .p_o(p12_w));
mul_s8_dsp u_mul13 (.a_i(a3), .b_i(w13), .p_o(p13_w));

// ---------------- Stage 1 ----------------
reg signed [15:0] p00_q;
reg signed [15:0] p01_q;
reg signed [15:0] p02_q;
reg signed [15:0] p03_q;

reg signed [15:0] p10_q;
reg signed [15:0] p11_q;
reg signed [15:0] p12_q;
reg signed [15:0] p13_q;

reg               valid_s1_q;
reg [1:0]         sample_s1_q;

always @(posedge clk) begin
    if (!resetn) begin
        p00_q <= 16'sd0;
        p01_q <= 16'sd0;
        p02_q <= 16'sd0;
        p03_q <= 16'sd0;

        p10_q <= 16'sd0;
        p11_q <= 16'sd0;
        p12_q <= 16'sd0;
        p13_q <= 16'sd0;

        valid_s1_q  <= 1'b0;
        sample_s1_q <= 2'd0;
    end else begin
        valid_s1_q  <= act_valid_i;
        sample_s1_q <= sample_id_i;

        if (act_valid_i) begin
            p00_q <= p00_w;
            p01_q <= p01_w;
            p02_q <= p02_w;
            p03_q <= p03_w;

            p10_q <= p10_w;
            p11_q <= p11_w;
            p12_q <= p12_w;
            p13_q <= p13_w;
        end
    end
end

// ---------------- Stage 2 ----------------
wire signed [16:0] s00_w;
wire signed [16:0] s01_w;

wire signed [16:0] s10_w;
wire signed [16:0] s11_w;

assign s00_w =
    $signed({p00_q[15], p00_q}) +
    $signed({p01_q[15], p01_q});

assign s01_w =
    $signed({p02_q[15], p02_q}) +
    $signed({p03_q[15], p03_q});

assign s10_w =
    $signed({p10_q[15], p10_q}) +
    $signed({p11_q[15], p11_q});

assign s11_w =
    $signed({p12_q[15], p12_q}) +
    $signed({p13_q[15], p13_q});

reg signed [16:0] s00_q;
reg signed [16:0] s01_q;

reg signed [16:0] s10_q;
reg signed [16:0] s11_q;

reg               valid_s2_q;
reg [1:0]         sample_s2_q;

always @(posedge clk) begin
    if (!resetn) begin
        s00_q <= 17'sd0;
        s01_q <= 17'sd0;
        s10_q <= 17'sd0;
        s11_q <= 17'sd0;

        valid_s2_q  <= 1'b0;
        sample_s2_q <= 2'd0;
    end else begin
        valid_s2_q  <= valid_s1_q;
        sample_s2_q <= sample_s1_q;

        if (valid_s1_q) begin
            s00_q <= s00_w;
            s01_q <= s01_w;
            s10_q <= s10_w;
            s11_q <= s11_w;
        end
    end
end

// ---------------- Stage 3 ----------------
wire signed [17:0] dot0_w;
wire signed [17:0] dot1_w;

assign dot0_w =
    $signed({s00_q[16], s00_q}) +
    $signed({s01_q[16], s01_q});

assign dot1_w =
    $signed({s10_q[16], s10_q}) +
    $signed({s11_q[16], s11_q});

always @(posedge clk) begin
    if (!resetn) begin
        dot_ch0_o  <= 18'sd0;
        dot_ch1_o  <= 18'sd0;
        dot_valid_o<= 1'b0;
        sample_id_o<= 2'd0;
    end else begin
        dot_valid_o <= valid_s2_q;
        sample_id_o <= sample_s2_q;

        if (valid_s2_q) begin
            dot_ch0_o <= dot0_w;
            dot_ch1_o <= dot1_w;
        end
    end
end

endmodule
