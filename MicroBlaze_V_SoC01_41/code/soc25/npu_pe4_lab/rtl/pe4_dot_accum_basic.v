module pe4_dot_accum_basic (
    input  wire                    clk,
    input  wire                    resetn,
    input  wire                    clear_i,
    input  wire                    valid_i,

    input  wire [31:0]             a_vec_i,
    input  wire [31:0]             b_vec_i,

    output reg  signed [31:0]      acc_o,
    output reg                     valid_o
);

// 4-lane PE:
//   4 parallel signed 8x8 multipliers
//   balanced adder tree
//   32-bit accumulator
//
// Packed lane mapping:
//   lane0 = [7:0]
//   lane1 = [15:8]
//   lane2 = [23:16]
//   lane3 = [31:24]

wire signed [7:0] a0;
wire signed [7:0] a1;
wire signed [7:0] a2;
wire signed [7:0] a3;

wire signed [7:0] b0;
wire signed [7:0] b1;
wire signed [7:0] b2;
wire signed [7:0] b3;

assign a0 = $signed(a_vec_i[7:0]);
assign a1 = $signed(a_vec_i[15:8]);
assign a2 = $signed(a_vec_i[23:16]);
assign a3 = $signed(a_vec_i[31:24]);

assign b0 = $signed(b_vec_i[7:0]);
assign b1 = $signed(b_vec_i[15:8]);
assign b2 = $signed(b_vec_i[23:16]);
assign b3 = $signed(b_vec_i[31:24]);

wire signed [15:0] p0;
wire signed [15:0] p1;
wire signed [15:0] p2;
wire signed [15:0] p3;

mul_s8_dsp u_mul0 (.a_i(a0), .b_i(b0), .p_o(p0));
mul_s8_dsp u_mul1 (.a_i(a1), .b_i(b1), .p_o(p1));
mul_s8_dsp u_mul2 (.a_i(a2), .b_i(b2), .p_o(p2));
mul_s8_dsp u_mul3 (.a_i(a3), .b_i(b3), .p_o(p3));

// Pair sums need one extra signed bit.
wire signed [16:0] sum01;
wire signed [16:0] sum23;

assign sum01 =
    $signed({p0[15], p0}) +
    $signed({p1[15], p1});

assign sum23 =
    $signed({p2[15], p2}) +
    $signed({p3[15], p3});

// Four-product sum needs 18 signed bits.
// Worst positive case:
//   4 * (-128 * -128) = 65536
// which does not fit in signed 17-bit.
wire signed [17:0] dot4_w;

assign dot4_w =
    $signed({sum01[16], sum01}) +
    $signed({sum23[16], sum23});

wire signed [31:0] dot4_ext_w;

assign dot4_ext_w =
    {{14{dot4_w[17]}}, dot4_w};

always @(posedge clk) begin
    if (!resetn) begin
        acc_o   <= 32'sd0;
        valid_o <= 1'b0;
    end else if (clear_i) begin
        acc_o   <= 32'sd0;
        valid_o <= 1'b0;
    end else begin
        valid_o <= valid_i;

        if (valid_i) begin
            acc_o <= acc_o + dot4_ext_w;
        end
    end
end

endmodule
