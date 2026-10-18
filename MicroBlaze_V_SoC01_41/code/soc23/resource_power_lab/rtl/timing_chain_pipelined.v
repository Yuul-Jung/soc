module timing_chain_pipelined (
    input  wire        clk,
    input  wire        resetn,

    input  wire [31:0] a_i,
    input  wire [31:0] b_i,
    input  wire [31:0] c_i,
    input  wire [31:0] d_i,
    input  wire [31:0] e_i,
    input  wire [31:0] f_i,
    input  wire [31:0] g_i,
    input  wire [31:0] h_i,
    input  wire        valid_i,

    output reg  [31:0] result_o,
    output reg         valid_o
);

// Stage 0 input registers.
reg [31:0] a_q;
reg [31:0] b_q;
reg [31:0] c_q;
reg [31:0] d_q;
reg [31:0] e_q;
reg [31:0] f_q;
reg [31:0] g_q;
reg [31:0] h_q;
reg        valid_q;

// First half of the original dependent chain.
wire [31:0] s1_t1;
wire [31:0] s1_t2;
wire [31:0] s1_t3;
wire [31:0] s1_t4;

assign s1_t1 = a_q + b_q;
assign s1_t2 = s1_t1 ^ {c_q[15:0], c_q[31:16]};
assign s1_t3 = s1_t2 + d_q;
assign s1_t4 = {s1_t3[30:0], s1_t3[31]} ^ e_q;

// Pipeline registers split the long combinational path.
reg [31:0] mid_data_q;
reg [31:0] f_mid_q;
reg [31:0] g_mid_q;
reg [31:0] h_mid_q;
reg        mid_valid_q;

// Second half of the chain.
wire [31:0] s2_t5;
wire [31:0] s2_t6;
wire [31:0] s2_t7;
wire [31:0] s2_t8;

assign s2_t5 = mid_data_q + f_mid_q;
assign s2_t6 = s2_t5 ^ {g_mid_q[7:0], g_mid_q[31:8]};
assign s2_t7 = s2_t6 + h_mid_q;
assign s2_t8 = (s2_t7 ^ {s2_t7[3:0], s2_t7[31:4]}) + 32'h1357_9BDF;

always @(posedge clk) begin
    if (!resetn) begin
        a_q         <= 32'h0000_0000;
        b_q         <= 32'h0000_0000;
        c_q         <= 32'h0000_0000;
        d_q         <= 32'h0000_0000;
        e_q         <= 32'h0000_0000;
        f_q         <= 32'h0000_0000;
        g_q         <= 32'h0000_0000;
        h_q         <= 32'h0000_0000;
        valid_q     <= 1'b0;

        mid_data_q  <= 32'h0000_0000;
        f_mid_q     <= 32'h0000_0000;
        g_mid_q     <= 32'h0000_0000;
        h_mid_q     <= 32'h0000_0000;
        mid_valid_q <= 1'b0;

        result_o    <= 32'h0000_0000;
        valid_o     <= 1'b0;
    end else begin
        a_q     <= a_i;
        b_q     <= b_i;
        c_q     <= c_i;
        d_q     <= d_i;
        e_q     <= e_i;
        f_q     <= f_i;
        g_q     <= g_i;
        h_q     <= h_i;
        valid_q <= valid_i;

        mid_data_q  <= s1_t4;
        f_mid_q     <= f_q;
        g_mid_q     <= g_q;
        h_mid_q     <= h_q;
        mid_valid_q <= valid_q;

        result_o <= s2_t8;
        valid_o  <= mid_valid_q;
    end
end

endmodule
