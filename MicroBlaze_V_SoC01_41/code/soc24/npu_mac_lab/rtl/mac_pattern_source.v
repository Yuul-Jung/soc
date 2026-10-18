module mac_pattern_source (
    input  wire              clk,
    input  wire              resetn,

    output wire signed [7:0] a_o,
    output wire signed [7:0] b_o,
    output wire              valid_o
);

// Internal source avoids using many board switches while still creating
// continuously changing signed MAC inputs.

reg [15:0] lfsr_q;

wire feedback;

assign feedback =
    lfsr_q[15] ^
    lfsr_q[13] ^
    lfsr_q[12] ^
    lfsr_q[10];

always @(posedge clk) begin
    if (!resetn) begin
        lfsr_q <= 16'hACE1;
    end else begin
        lfsr_q <= {
            lfsr_q[14:0],
            feedback
        };
    end
end

assign a_o = $signed(lfsr_q[7:0]);
assign b_o = $signed(lfsr_q[15:8]);
assign valid_o = resetn;

endmodule
