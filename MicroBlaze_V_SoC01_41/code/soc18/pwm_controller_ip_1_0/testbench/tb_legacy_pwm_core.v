`timescale 1ns / 1ps

module tb_legacy_pwm_core;

reg clk = 1'b0;
reg resetn = 1'b0;
reg enable_i = 1'b0;
reg invert_i = 1'b0;
reg [31:0] period_i = 32'd8;
reg [31:0] duty_i = 32'd2;

wire pwm_o;
wire active_o;

integer high_count = 0;
integer sample_count = 0;
integer errors = 0;

always #5 clk = ~clk;

legacy_pwm_core dut (
    .clk(clk),
    .resetn(resetn),
    .enable_i(enable_i),
    .invert_i(invert_i),
    .period_i(period_i),
    .duty_i(duty_i),
    .pwm_o(pwm_o),
    .active_o(active_o)
);

initial begin
    repeat (4) @(posedge clk);
    resetn = 1'b1;
    enable_i = 1'b1;

    repeat (8) begin
        @(posedge clk);
        sample_count = sample_count + 1;
        if (pwm_o) begin
            high_count = high_count + 1;
        end
    end

    if (high_count != 2) begin
        $display("FAIL: PWM high count=%0d expected=2", high_count);
        errors = errors + 1;
    end

    if (errors == 0) begin
        $display("SOC18 LEGACY PWM CORE TEST: PASS");
    end else begin
        $display("SOC18 LEGACY PWM CORE TEST: FAIL (%0d)", errors);
    end

    #30;
    $finish;
end

endmodule
