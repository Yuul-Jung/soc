module timing_chain_unpipelined (
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

// Input registers create a true internal register-to-register timing path.
reg [31:0] a_q;
reg [31:0] b_q;
reg [31:0] c_q;
reg [31:0] d_q;
reg [31:0] e_q;
reg [31:0] f_q;
reg [31:0] g_q;
reg [31:0] h_q;
reg        valid_q;

// Dependent logic chain.
// Each result feeds the next operation, so logic depth matters.
wire [31:0] t1;
wire [31:0] t2;
wire [31:0] t3;
wire [31:0] t4;
wire [31:0] t5;
wire [31:0] t6;
wire [31:0] t7;
wire [31:0] t8;

assign t1 = a_q + b_q;
assign t2 = t1 ^ {c_q[15:0], c_q[31:16]};
assign t3 = t2 + d_q;
assign t4 = {t3[30:0], t3[31]} ^ e_q;
assign t5 = t4 + f_q;
assign t6 = t5 ^ {g_q[7:0], g_q[31:8]};
assign t7 = t6 + h_q;
assign t8 = (t7 ^ {t7[3:0], t7[31:4]}) + 32'h1357_9BDF;

always @(posedge clk) begin
    if (!resetn) begin
        a_q      <= 32'h0000_0000;
        b_q      <= 32'h0000_0000;
        c_q      <= 32'h0000_0000;
        d_q      <= 32'h0000_0000;
        e_q      <= 32'h0000_0000;
        f_q      <= 32'h0000_0000;
        g_q      <= 32'h0000_0000;
        h_q      <= 32'h0000_0000;
        valid_q  <= 1'b0;

        result_o <= 32'h0000_0000;
        valid_o  <= 1'b0;
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

        result_o <= t8;
        valid_o  <= valid_q;
    end
end

endmodule
