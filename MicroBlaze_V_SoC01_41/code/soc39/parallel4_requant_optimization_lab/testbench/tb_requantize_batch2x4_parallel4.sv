`timescale 1ns / 1ps

module tb_requantize_batch2x4_parallel4;

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

integer cycle_count = 0;
integer start_cycle = -1;
integer result_cycle = -1;
integer errors = 0;

always #5 clk = ~clk;

always @(posedge clk) begin
    cycle_count = cycle_count + 1;
    #1;

    if (
        start_i &&
        (start_cycle < 0)
    ) begin
        start_cycle = cycle_count;
    end

    if (
        result_valid_o &&
        (result_cycle < 0)
    ) begin
        result_cycle = cycle_count;
    end
end

requantize_batch2x4_parallel4 dut (
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

task automatic check32(
    input string name,
    input logic [31:0] actual,
    input logic [31:0] expected
);
    begin
        if (actual !== expected) begin
            errors = errors + 1;
            $error(
                "%s actual=0x%08h expected=0x%08h",
                name,
                actual,
                expected
            );
        end else begin
            $display(
                "PASS %s = 0x%08h",
                name,
                actual
            );
        end
    end
endtask

initial begin
    // CH0 raw accumulators: 16, 32, 48, 64
    acc_ch0_batch_i = {
        32'd64,
        32'd48,
        32'd32,
        32'd16
    };

    // CH1 raw accumulators: 32, 64, 96, 128
    acc_ch1_batch_i = {
        32'd128,
        32'd96,
        32'd64,
        32'd32
    };

    bias_ch0_i = 32'sd0;
    bias_ch1_i = 32'sd4;

    mult_ch0_i = 16'sd1;
    mult_ch1_i = 16'sd3;

    shift_ch0_i = 6'd1;
    shift_ch1_i = 6'd1;

    zp_ch0_i = 16'sd0;
    zp_ch1_i = -16'sd3;

    repeat (4) @(posedge clk);
    resetn = 1'b1;

    @(negedge clk);
    start_i = 1'b1;

    @(posedge clk);
    #1;

    @(negedge clk);
    start_i = 1'b0;

    wait (result_valid_o === 1'b1);
    #1;

    check32(
        "CH0",
        q_ch0_batch_o,
        32'h2018_1008
    );

    check32(
        "CH1",
        q_ch1_batch_o,
        32'h7F7F_6333
    );

    if (saturation_count_o !== 8'd2) begin
        errors = errors + 1;
        $error(
            "saturation_count actual=%0d expected=2",
            saturation_count_o
        );
    end

    if (errors == 0) begin
        $display("SOC39 PARALLEL4 BATCH TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC39 PARALLEL4 BATCH TEST: FAIL"
        );
    end

    #20;
    $finish;
end

endmodule
