module pe4_pattern_source (
    input  wire        clk,
    input  wire        resetn,

    output wire [31:0] a_vec_o,
    output wire [31:0] b_vec_o,
    output wire        valid_o
);

// Two independent LFSRs generate four signed 8-bit lanes.

reg [31:0] lfsr_a_q;
reg [31:0] lfsr_b_q;

wire feedback_a;
wire feedback_b;

assign feedback_a =
    lfsr_a_q[31] ^
    lfsr_a_q[21] ^
    lfsr_a_q[1] ^
    lfsr_a_q[0];

assign feedback_b =
    lfsr_b_q[31] ^
    lfsr_b_q[28] ^
    lfsr_b_q[3] ^
    lfsr_b_q[0];

always @(posedge clk) begin
    if (!resetn) begin
        lfsr_a_q <= 32'h1ACE_B00C;
        lfsr_b_q <= 32'hC001_D00D;
    end else begin
        lfsr_a_q <= {
            lfsr_a_q[30:0],
            feedback_a
        };

        lfsr_b_q <= {
            lfsr_b_q[30:0],
            feedback_b
        };
    end
end

assign a_vec_o = lfsr_a_q;
assign b_vec_o = lfsr_b_q;
assign valid_o = resetn;

endmodule
