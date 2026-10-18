`timescale 1ns / 1ps

module tb_requantize_s32_to_s8;

logic clk = 1'b0;
logic resetn = 1'b0;

logic valid_i = 1'b0;
logic signed [31:0] acc_i = 32'sd0;
logic signed [31:0] bias_i = 32'sd0;
logic signed [15:0] multiplier_i = 16'sd1;
logic [5:0] shift_i = 6'd0;
logic signed [15:0] zero_point_i = 16'sd0;

wire valid_o;
wire signed [7:0] q_o;
wire sat_pos_o;
wire sat_neg_o;

integer check_count = 0;
integer error_count = 0;

integer wr_ptr = 0;
integer rd_ptr = 0;

reg signed [7:0] expected_q [0:255];
reg expected_sat_pos [0:255];
reg expected_sat_neg [0:255];

always #5 clk = ~clk;

requantize_s32_to_s8 dut (
    .clk(clk),
    .resetn(resetn),

    .valid_i(valid_i),

    .acc_i(acc_i),
    .bias_i(bias_i),

    .multiplier_i(multiplier_i),
    .shift_i(shift_i),
    .zero_point_i(zero_point_i),

    .valid_o(valid_o),
    .q_o(q_o),

    .sat_pos_o(sat_pos_o),
    .sat_neg_o(sat_neg_o)
);

function automatic integer signed ref_requant(
    input integer signed acc,
    input integer signed bias,
    input integer signed mult,
    input integer shift,
    input integer signed zp
);
    reg signed [63:0] biased;
    reg signed [63:0] product;
    reg signed [63:0] magnitude;
    reg signed [63:0] rounded;
    reg signed [63:0] shifted;
    reg signed [63:0] rounding_add;

    begin
        biased = acc;
        biased = biased + bias;

        product = biased * mult;

        if (product < 0)
            magnitude = -product;
        else
            magnitude = product;

        if (shift == 0) begin
            rounded = magnitude;
        end else begin
            rounding_add = 64'sd1 <<< (shift - 1);
            rounded = (magnitude + rounding_add) >>> shift;
        end

        if (product < 0)
            rounded = -rounded;

        shifted = rounded + zp;

        if (shifted > 127)
            ref_requant = 127;
        else if (shifted < -128)
            ref_requant = -128;
        else
            ref_requant = shifted;
    end
endfunction

function automatic bit ref_sat_pos(
    input integer signed acc,
    input integer signed bias,
    input integer signed mult,
    input integer shift,
    input integer signed zp
);
    reg signed [63:0] biased;
    reg signed [63:0] product;
    reg signed [63:0] magnitude;
    reg signed [63:0] rounded;
    reg signed [63:0] shifted;

    begin
        biased = acc;
        biased = biased + bias;
        product = biased * mult;

        magnitude = (product < 0) ? -product : product;

        if (shift == 0)
            rounded = magnitude;
        else
            rounded =
                (magnitude + (64'sd1 <<< (shift - 1))) >>> shift;

        if (product < 0)
            rounded = -rounded;

        shifted = rounded + zp;

        ref_sat_pos = (shifted > 127);
    end
endfunction

function automatic bit ref_sat_neg(
    input integer signed acc,
    input integer signed bias,
    input integer signed mult,
    input integer shift,
    input integer signed zp
);
    reg signed [63:0] biased;
    reg signed [63:0] product;
    reg signed [63:0] magnitude;
    reg signed [63:0] rounded;
    reg signed [63:0] shifted;

    begin
        biased = acc;
        biased = biased + bias;
        product = biased * mult;

        magnitude = (product < 0) ? -product : product;

        if (shift == 0)
            rounded = magnitude;
        else
            rounded =
                (magnitude + (64'sd1 <<< (shift - 1))) >>> shift;

        if (product < 0)
            rounded = -rounded;

        shifted = rounded + zp;

        ref_sat_neg = (shifted < -128);
    end
endfunction

task automatic send_case(
    input integer signed acc,
    input integer signed bias,
    input integer signed mult,
    input integer shift,
    input integer signed zp
);
    integer signed q_ref;

    begin
        q_ref = ref_requant(
            acc,
            bias,
            mult,
            shift,
            zp
        );

        expected_q[wr_ptr] =
            q_ref[7:0];

        expected_sat_pos[wr_ptr] =
            ref_sat_pos(acc, bias, mult, shift, zp);

        expected_sat_neg[wr_ptr] =
            ref_sat_neg(acc, bias, mult, shift, zp);

        wr_ptr = wr_ptr + 1;

        @(negedge clk);

        acc_i = acc;
        bias_i = bias;
        multiplier_i = mult;
        shift_i = shift[5:0];
        zero_point_i = zp;
        valid_i = 1'b1;
    end
endtask

task automatic stop_input;
    begin
        @(negedge clk);
        valid_i = 1'b0;
    end
endtask

always @(posedge clk) begin
    #1;

    if (valid_o) begin
        check_count = check_count + 1;

        if (q_o !== expected_q[rd_ptr]) begin
            error_count = error_count + 1;

            $error(
                "Q FAIL idx=%0d actual=%0d expected=%0d",
                rd_ptr,
                q_o,
                expected_q[rd_ptr]
            );
        end

        if (sat_pos_o !== expected_sat_pos[rd_ptr]) begin
            error_count = error_count + 1;

            $error(
                "SAT+ FAIL idx=%0d",
                rd_ptr
            );
        end

        if (sat_neg_o !== expected_sat_neg[rd_ptr]) begin
            error_count = error_count + 1;

            $error(
                "SAT- FAIL idx=%0d",
                rd_ptr
            );
        end

        rd_ptr = rd_ptr + 1;
    end
end

initial begin
    integer i;
    integer signed r_acc;
    integer signed r_bias;
    integer signed r_mult;
    integer r_shift;
    integer signed r_zp;

    repeat (5) @(posedge clk);
    resetn = 1'b1;

    // Directed midpoint / sign / saturation cases.
    send_case(0, 0, 1, 0, 0);

    send_case(3, 0, 1, 1, 0);    // +1.5 -> +2
    send_case(-3, 0, 1, 1, 0);   // -1.5 -> -2

    send_case(1, 0, 1, 1, 0);    // +0.5 -> +1
    send_case(-1, 0, 1, 1, 0);   // -0.5 -> -1

    send_case(200, 0, 1, 0, 0);  // + saturation
    send_case(-200, 0, 1, 0, 0); // - saturation

    send_case(120, 20, 1, 0, 0);
    send_case(-120, -20, 1, 0, 0);

    send_case(100, 0, 3, 1, -3);
    send_case(-100, 0, 3, 1, 5);

    send_case(10, 0, 1, 0, 5);
    send_case(-10, 0, 1, 0, 5);

    // Bias addition must not overflow at 32-bit boundary.
    send_case(32'sh7FFF_FFFF, 32'sh7FFF_FFFF, 1, 25, 0);
    send_case(32'sh8000_0000, -32'sh7FFF_FFFF, 1, 25, 0);

    // Randomized moderate-range regression.
    for (i = 0; i < 80; i = i + 1) begin
        r_acc = ($urandom % 4001) - 2000;
        r_bias = ($urandom % 401) - 200;
        r_mult = ($urandom % 15) + 1;
        r_shift = $urandom % 9;
        r_zp = ($urandom % 21) - 10;

        send_case(
            r_acc,
            r_bias,
            r_mult,
            r_shift,
            r_zp
        );
    end

    stop_input();

    while (rd_ptr < wr_ptr) begin
        @(posedge clk);
    end

    repeat (3) @(posedge clk);

    $display("");
    $display("SOC30 CORE CASES  : %0d", wr_ptr);
    $display("SOC30 CORE CHECKS : %0d", check_count);
    $display("SOC30 CORE ERRORS : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC30 REQUANT CORE TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC30 REQUANT CORE TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
