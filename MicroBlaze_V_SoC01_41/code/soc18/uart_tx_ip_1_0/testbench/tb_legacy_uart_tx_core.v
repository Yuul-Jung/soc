`timescale 1ns / 1ps

module tb_legacy_uart_tx_core;

localparam integer CLKS_PER_BIT_TB = 4;

reg clk = 1'b0;
reg resetn = 1'b0;
reg tx_start_i = 1'b0;
reg [7:0] tx_data_i = 8'h00;

wire tx_o;
wire busy_o;
wire done_pulse_o;

integer errors = 0;

always #5 clk = ~clk;

legacy_uart_tx_core #(
    .CLKS_PER_BIT(CLKS_PER_BIT_TB)
) dut (
    .clk(clk),
    .resetn(resetn),
    .tx_start_i(tx_start_i),
    .tx_data_i(tx_data_i),
    .tx_o(tx_o),
    .busy_o(busy_o),
    .done_pulse_o(done_pulse_o)
);

initial begin
    repeat (4) @(posedge clk);
    resetn = 1'b1;

    @(negedge clk);
    tx_data_i = 8'h55;
    tx_start_i = 1'b1;

    @(negedge clk);
    tx_start_i = 1'b0;

    wait (busy_o === 1'b1);
    wait (done_pulse_o === 1'b1);

    if (tx_o !== 1'b1) begin
        $display("FAIL: UART TX should return to idle high");
        errors = errors + 1;
    end

    @(posedge clk);
    // (추가) 비차단 대입이 반영된 뒤 펄스 해제를 확인한다.
    #1;
    if (done_pulse_o !== 1'b0) begin
        $display("FAIL: done_pulse wider than one clock");
        errors = errors + 1;
    end

    if (errors == 0) begin
        $display("SOC18 LEGACY UART TX CORE TEST: PASS");
    end else begin
        $display("SOC18 LEGACY UART TX CORE TEST: FAIL (%0d)", errors);
    end

    #50;
    $finish;
end

endmodule
