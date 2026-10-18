`timescale 1ns / 1ps

module tb_requantize_batch2x4_serial;

logic clk = 1'b0;
logic resetn = 1'b0;
logic start_i = 1'b0;

logic [127:0] acc_ch0_batch_i;
logic [127:0] acc_ch1_batch_i;

logic signed [31:0] bias_ch0_i;
logic signed [31:0] bias_ch1_i;

logic signed [15:0] mult_ch0_i;
logic signed [15:0] mult_ch1_i;

logic [5:0] shift_ch0_i;
logic [5:0] shift_ch1_i;

logic signed [15:0] zp_ch0_i;
logic signed [15:0] zp_ch1_i;

wire busy_o;
wire done_o;
wire result_valid_o;

wire [31:0] q_ch0_batch_o;
wire [31:0] q_ch1_batch_o;

wire [7:0] saturation_count_o;

integer error_count = 0;
integer check_count = 0;

always #5 clk = ~clk;

requantize_batch2x4_serial dut (
    .clk(clk),
    .resetn(resetn),

    .start_i(start_i),

    .acc_ch0_batch_i(acc_ch0_batch_i),
    .acc_ch1_batch_i(acc_ch1_batch_i),

    .bias_ch0_i(bias_ch0_i),
    .bias_ch1_i(bias_ch1_i),

    .mult_ch0_i(mult_ch0_i),
    .mult_ch1_i(mult_ch1_i),

    .shift_ch0_i(shift_ch0_i),
    .shift_ch1_i(shift_ch1_i),

    .zp_ch0_i(zp_ch0_i),
    .zp_ch1_i(zp_ch1_i),

    .busy_o(busy_o),
    .done_o(done_o),
    .result_valid_o(result_valid_o),

    .q_ch0_batch_o(q_ch0_batch_o),
    .q_ch1_batch_o(q_ch1_batch_o),

    .saturation_count_o(saturation_count_o)
);

task automatic check_true(
    input string name,
    input bit condition
);
    begin
        check_count = check_count + 1;

        if (!condition) begin
            error_count = error_count + 1;
            $error("CHECK FAIL: %s", name);
        end else begin
            $display("CHECK PASS: %s", name);
        end
    end
endtask

initial begin
    integer timeout;

    // SoC 29 board-demo int32 output:
    // CH0 = [16, 32, 48, 64]
    // CH1 = [32, 64, 96, 128]
    acc_ch0_batch_i = {
        32'sd64,
        32'sd48,
        32'sd32,
        32'sd16
    };

    acc_ch1_batch_i = {
        32'sd128,
        32'sd96,
        32'sd64,
        32'sd32
    };

    // CH0:
    // q = round(x / 2)
    // -> [8, 16, 24, 32]
    bias_ch0_i = 32'sd0;
    mult_ch0_i = 16'sd1;
    shift_ch0_i = 6'd1;
    zp_ch0_i = 16'sd0;

    // CH1:
    // q = round((x + 4) * 3 / 2) - 3
    // -> [51, 99, 127, 127]
    // last two saturate positive.
    bias_ch1_i = 32'sd4;
    mult_ch1_i = 16'sd3;
    shift_ch1_i = 6'd1;
    zp_ch1_i = -16'sd3;

    repeat (5) @(posedge clk);
    resetn = 1'b1;

    @(negedge clk);
    start_i = 1'b1;

    @(negedge clk);
    start_i = 1'b0;

    timeout = 0;

    while (
        (result_valid_o !== 1'b1) &&
        (timeout < 100)
    ) begin
        @(posedge clk);
        #1;
        timeout = timeout + 1;
    end

    check_true(
        "result_valid arrived",
        result_valid_o === 1'b1
    );

    check_true(
        "done aligned with result",
        done_o === 1'b1
    );

    check_true(
        "CH0 packed int8",
        q_ch0_batch_o == 32'h2018_1008
    );

    check_true(
        "CH1 packed int8",
        q_ch1_batch_o == 32'h7F7F_6333
    );

    check_true(
        "saturation count = 2",
        saturation_count_o == 8'd2
    );

    $display("");
    $display("CH0 quantized = 0x%08h", q_ch0_batch_o);
    $display("CH1 quantized = 0x%08h", q_ch1_batch_o);
    $display("saturation count = %0d", saturation_count_o);

    if (error_count == 0) begin
        $display("SOC30 BATCH REQUANT TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC30 BATCH REQUANT TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
