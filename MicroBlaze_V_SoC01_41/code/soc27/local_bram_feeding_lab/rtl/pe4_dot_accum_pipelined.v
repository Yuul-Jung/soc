module pe4_dot_accum_pipelined (
    input  wire                    clk,
    input  wire                    resetn,
    input  wire                    clear_i,
    input  wire                    valid_i,

    input  wire [31:0]             a_vec_i,
    input  wire [31:0]             b_vec_i,

    output reg  signed [31:0]      acc_o,
    output reg                     valid_o
);

// Four-stage datapath:
//   Stage 1: 4 parallel products
//   Stage 2: 2 pair sums
//   Stage 3: final 4-way dot-product sum
//   Stage 4: accumulator
//
// valid_i is pipelined through the same stages.

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

wire signed [15:0] p0_w;
wire signed [15:0] p1_w;
wire signed [15:0] p2_w;
wire signed [15:0] p3_w;

mul_s8_dsp u_mul0 (.a_i(a0), .b_i(b0), .p_o(p0_w));
mul_s8_dsp u_mul1 (.a_i(a1), .b_i(b1), .p_o(p1_w));
mul_s8_dsp u_mul2 (.a_i(a2), .b_i(b2), .p_o(p2_w));
mul_s8_dsp u_mul3 (.a_i(a3), .b_i(b3), .p_o(p3_w));

// Stage 1 registers.
reg signed [15:0] p0_q;
reg signed [15:0] p1_q;
reg signed [15:0] p2_q;
reg signed [15:0] p3_q;
reg               valid_s1_q;

// Stage 2 combinational pair sums.
wire signed [16:0] sum01_w;
wire signed [16:0] sum23_w;

assign sum01_w =
    $signed({p0_q[15], p0_q}) +
    $signed({p1_q[15], p1_q});

assign sum23_w =
    $signed({p2_q[15], p2_q}) +
    $signed({p3_q[15], p3_q});

// Stage 2 registers.
reg signed [16:0] sum01_q;
reg signed [16:0] sum23_q;
reg               valid_s2_q;

// Stage 3 final reduction.
wire signed [17:0] dot4_w;

assign dot4_w =
    $signed({sum01_q[16], sum01_q}) +
    $signed({sum23_q[16], sum23_q});

reg signed [17:0] dot4_q;
reg               valid_s3_q;

wire signed [31:0] dot4_ext_w;

assign dot4_ext_w =
    {{14{dot4_q[17]}}, dot4_q};

always @(posedge clk) begin
    if (!resetn) begin
        p0_q       <= 16'sd0;
        p1_q       <= 16'sd0;
        p2_q       <= 16'sd0;
        p3_q       <= 16'sd0;
        valid_s1_q <= 1'b0;

        sum01_q    <= 17'sd0;
        sum23_q    <= 17'sd0;
        valid_s2_q <= 1'b0;

        dot4_q     <= 18'sd0;
        valid_s3_q <= 1'b0;

        acc_o      <= 32'sd0;
        valid_o    <= 1'b0;
    end else if (clear_i) begin
        p0_q       <= 16'sd0;
        p1_q       <= 16'sd0;
        p2_q       <= 16'sd0;
        p3_q       <= 16'sd0;
        valid_s1_q <= 1'b0;

        sum01_q    <= 17'sd0;
        sum23_q    <= 17'sd0;
        valid_s2_q <= 1'b0;

        dot4_q     <= 18'sd0;
        valid_s3_q <= 1'b0;

        acc_o      <= 32'sd0;
        valid_o    <= 1'b0;
    end else begin
        // Stage 1
        valid_s1_q <= valid_i;

        if (valid_i) begin
            p0_q <= p0_w;
            p1_q <= p1_w;
            p2_q <= p2_w;
            p3_q <= p3_w;
        end

        // Stage 2
        valid_s2_q <= valid_s1_q;

        if (valid_s1_q) begin
            sum01_q <= sum01_w;
            sum23_q <= sum23_w;
        end

        // Stage 3
        valid_s3_q <= valid_s2_q;

        if (valid_s2_q) begin
            dot4_q <= dot4_w;
        end

        // Stage 4
        valid_o <= valid_s3_q;

        if (valid_s3_q) begin
            acc_o <= acc_o + dot4_ext_w;
        end
    end
end

endmodule
