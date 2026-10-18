`timescale 1ns / 1ps

module tb_legacy_processing_core;

reg clk = 1'b0;
reg rst_n = 1'b0;
reg launch_i = 1'b0;
reg [1:0] opcode_i = 2'b00;
reg [31:0] operand_i = 32'h0;

wire active_o;
wire done_pulse_o;
wire [31:0] result_o;

integer errors = 0;

always #5 clk = ~clk;

legacy_processing_core #(
    .LATENCY_CYCLES(4)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .launch_i(launch_i),
    .opcode_i(opcode_i),
    .operand_i(operand_i),
    .active_o(active_o),
    .done_pulse_o(done_pulse_o),
    .result_o(result_o)
);

task automatic run_case;
    input [1:0] op;
    input [31:0] value;
    input [31:0] expected;
    begin
        wait (!active_o);

        @(negedge clk);
        opcode_i = op;
        operand_i = value;
        launch_i = 1'b1;

        @(negedge clk);
        launch_i = 1'b0;

        wait (done_pulse_o === 1'b1);

        if (result_o !== expected) begin
            $display("FAIL: op=%0d in=%08h out=%08h expected=%08h",
                     op, value, result_o, expected);
            errors = errors + 1;
        end else begin
            $display("PASS: op=%0d in=%08h out=%08h",
                     op, value, result_o);
        end

        @(posedge clk);

        // (추가) 비차단 대입이 반영된 뒤 펄스 해제를 확인한다.

        #1;

        if (done_pulse_o !== 1'b0) begin
            $display("FAIL: done_pulse_o wider than one clock");
            errors = errors + 1;
        end
    end
endtask

initial begin
    repeat (4) @(posedge clk);
    rst_n = 1'b1;
    repeat (2) @(posedge clk);

    run_case(2'b00, 32'h12345678, 32'h12345678);
    run_case(2'b01, 32'hFFFFFFFF, 32'h00000000);
    run_case(2'b10, 32'h80000001, 32'h00000002);
    run_case(2'b11, 32'hA5A55A5A, 32'h5A5AA5A5);

    if (errors == 0) begin
        $display("LEGACY PROCESSING CORE TEST: PASS");
    end else begin
        $display("LEGACY PROCESSING CORE TEST: FAIL (%0d errors)", errors);
    end

    #30;
    $finish;
end

endmodule
