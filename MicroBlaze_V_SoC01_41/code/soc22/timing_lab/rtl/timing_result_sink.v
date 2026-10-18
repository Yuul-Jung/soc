module timing_result_sink (
    input  wire        clk,
    input  wire        resetn,

    input  wire [31:0] result_i,
    input  wire        valid_i,

    output reg  [15:0] led_o
);

always @(posedge clk) begin
    if (!resetn) begin
        led_o <= 16'h0000;
    end else if (valid_i) begin
        led_o <= result_i[15:0];
    end
end

endmodule
