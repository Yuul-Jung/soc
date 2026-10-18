module ws_result_sink (
    input  wire         clk,
    input  wire         resetn,

    input  wire         result_valid_i,
    input  wire [127:0] result_ch1_batch_i,

    output reg  [15:0]  led_o
);

// Display CH1 sample3.
// Expected board demo value:
// 128 decimal = 0x0080.

wire signed [31:0] selected_result_w;

assign selected_result_w =
    $signed(result_ch1_batch_i[127:96]);

always @(posedge clk) begin
    if (!resetn) begin
        led_o <= 16'h0000;
    end else if (result_valid_i) begin
        led_o <= selected_result_w[15:0];
    end
end

endmodule
