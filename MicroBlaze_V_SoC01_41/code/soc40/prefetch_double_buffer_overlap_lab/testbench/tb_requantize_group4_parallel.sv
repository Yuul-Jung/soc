`timescale 1ns / 1ps

module tb_requantize_group4_parallel;

logic clk = 1'b0;
logic resetn = 1'b0;

logic valid_i = 1'b0;
logic tag_i = 1'b0;
logic [127:0] acc_group_i;

logic signed [31:0] bias_i;
logic signed [15:0] multiplier_i;
logic [5:0] shift_i;
logic signed [15:0] zero_point_i;

wire valid_o;
wire tag_o;
wire [31:0] q_group_o;
wire [2:0] saturation_count_o;

integer errors = 0;

always #5 clk = ~clk;

requantize_group4_parallel dut (
    .clk(clk),
    .resetn(resetn),
    .valid_i(valid_i),
    .tag_i(tag_i),
    .acc_group_i(acc_group_i),
    .bias_i(bias_i),
    .multiplier_i(multiplier_i),
    .shift_i(shift_i),
    .zero_point_i(zero_point_i),
    .valid_o(valid_o),
    .tag_o(tag_o),
    .q_group_o(q_group_o),
    .saturation_count_o(saturation_count_o)
);

task automatic launch_group(
    input logic tag,
    input logic [127:0] acc,
    input logic signed [31:0] bias,
    input logic signed [15:0] mult,
    input logic [5:0] shift,
    input logic signed [15:0] zp
);
    begin
        @(negedge clk);
        tag_i = tag;
        acc_group_i = acc;
        bias_i = bias;
        multiplier_i = mult;
        shift_i = shift;
        zero_point_i = zp;
        valid_i = 1'b1;

        @(negedge clk);
        valid_i = 1'b0;
    end
endtask

initial begin
    repeat (4) @(posedge clk);
    resetn = 1'b1;

    launch_group(
        1'b0,
        {32'd64, 32'd48, 32'd32, 32'd16},
        32'sd0, 16'sd1, 6'd1, 16'sd0
    );

    wait (valid_o === 1'b1);
    #1;

    if (
        (tag_o !== 1'b0) ||
        (q_group_o !== 32'h2018_1008) ||
        (saturation_count_o !== 3'd0)
    ) begin
        errors = errors + 1;
        $error("CH0 group mismatch");
    end

    launch_group(
        1'b1,
        {32'd128, 32'd96, 32'd64, 32'd32},
        32'sd4, 16'sd3, 6'd1, -16'sd3
    );

    wait (valid_o === 1'b1);
    #1;

    if (
        (tag_o !== 1'b1) ||
        (q_group_o !== 32'h7F7F_6333) ||
        (saturation_count_o !== 3'd2)
    ) begin
        errors = errors + 1;
        $error("CH1 group mismatch");
    end

    if (errors == 0)
        $display("SOC40 GROUP4 TEST: PASS");
    else
        $fatal(1, "SOC40 GROUP4 TEST: FAIL");

    #20;
    $finish;
end

endmodule
