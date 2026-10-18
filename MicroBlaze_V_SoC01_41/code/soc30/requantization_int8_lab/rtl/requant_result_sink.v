module requant_result_sink (
    input  wire        clk,
    input  wire        resetn,

    input  wire        result_valid_i,

    input  wire [31:0] q_ch0_batch_i,
    input  wire [31:0] q_ch1_batch_i,

    output reg  [15:0] led_o
);

// Display:
//   LED[15:8] = CH0 sample3
//   LED[7:0]  = CH1 sample3
//
// Expected:
//   CH0 sample3 = 32  = 0x20
//   CH1 sample3 = 127 = 0x7F
//
// LED[15:0] = 0x207F.

always @(posedge clk) begin
    if (!resetn) begin
        led_o <= 16'h0000;
    end else if (result_valid_i) begin
        led_o <= {
            q_ch0_batch_i[31:24],
            q_ch1_batch_i[31:24]
        };
    end
end

endmodule
