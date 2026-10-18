module timing_pattern_source (
    input  wire        clk,
    input  wire        resetn,

    output wire [31:0] a_o,
    output wire [31:0] b_o,
    output wire [31:0] c_o,
    output wire [31:0] d_o,
    output wire [31:0] e_o,
    output wire [31:0] f_o,
    output wire [31:0] g_o,
    output wire [31:0] h_o,
    output wire        valid_o
);

// Low-cost internal stimulus keeps the timing lab independent of
// hundreds of external FPGA pins.
reg [31:0] lfsr_q;

wire feedback;

assign feedback =
    lfsr_q[31] ^
    lfsr_q[21] ^
    lfsr_q[1] ^
    lfsr_q[0];

always @(posedge clk) begin
    if (!resetn) begin
        lfsr_q <= 32'h1ACE_B00C;
    end else begin
        lfsr_q <= {
            lfsr_q[30:0],
            feedback
        };
    end
end

assign a_o = lfsr_q;
assign b_o = {lfsr_q[15:0], lfsr_q[31:16]};
assign c_o = lfsr_q ^ 32'hA5A5_5A5A;
assign d_o = {lfsr_q[7:0], lfsr_q[31:8]};
assign e_o = ~lfsr_q;
assign f_o = lfsr_q + 32'h0101_0101;
assign g_o = {lfsr_q[0], lfsr_q[31:1]};
assign h_o = lfsr_q ^ 32'h3C3C_C3C3;

assign valid_o = resetn;

endmodule
