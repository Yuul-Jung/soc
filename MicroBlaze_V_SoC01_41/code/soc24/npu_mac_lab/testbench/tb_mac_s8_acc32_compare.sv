`timescale 1ns / 1ps

module tb_mac_s8_acc32_compare;

logic clk = 1'b0;
logic resetn = 1'b0;
logic clear_i = 1'b0;
logic valid_i = 1'b0;

logic signed [7:0] a_i = 8'sd0;
logic signed [7:0] b_i = 8'sd0;

wire signed [31:0] basic_acc_o;
wire               basic_valid_o;

wire signed [31:0] pipe_acc_o;
wire               pipe_valid_o;

logic signed [31:0] expected_basic_q[$];
logic signed [31:0] expected_pipe_q[$];

logic signed [31:0] reference_acc;

int error_count = 0;
int check_count = 0;

always #5 clk = ~clk;

mac_s8_acc32_basic u_basic (
    .clk(clk),
    .resetn(resetn),
    .clear_i(clear_i),
    .valid_i(valid_i),

    .a_i(a_i),
    .b_i(b_i),

    .acc_o(basic_acc_o),
    .valid_o(basic_valid_o)
);

mac_s8_acc32_pipelined u_pipe (
    .clk(clk),
    .resetn(resetn),
    .clear_i(clear_i),
    .valid_i(valid_i),

    .a_i(a_i),
    .b_i(b_i),

    .acc_o(pipe_acc_o),
    .valid_o(pipe_valid_o)
);

function automatic logic signed [31:0] reference_next(
    input logic signed [31:0] acc,
    input logic signed [7:0]  a,
    input logic signed [7:0]  b
);
    logic signed [15:0] product;
    logic signed [31:0] product_ext;

    begin
        product = a * b;
        product_ext = {
            {16{product[15]}},
            product
        };

        reference_next = acc + product_ext;
    end
endfunction

task automatic drive_valid(
    input integer a_value,
    input integer b_value
);
    logic signed [31:0] next_acc;

    begin
        @(negedge clk);

        clear_i = 1'b0;
        valid_i = 1'b1;
        a_i = a_value;
        b_i = b_value;

        next_acc = reference_next(
            reference_acc,
            a_i,
            b_i
        );

        reference_acc = next_acc;

        expected_basic_q.push_back(next_acc);
        expected_pipe_q.push_back(next_acc);
    end
endtask

task automatic drive_idle;
    begin
        @(negedge clk);
        valid_i = 1'b0;
        a_i = 8'sd0;
        b_i = 8'sd0;
    end
endtask

task automatic clear_mac;
    begin
        // Only call after pending expected queues are empty.
        @(negedge clk);
        valid_i = 1'b0;
        clear_i = 1'b1;

        @(negedge clk);
        clear_i = 1'b0;

        reference_acc = 32'sd0;
    end
endtask

task automatic wait_queues_empty;
    int k;

    begin
        drive_idle();

        for (k = 0; k < 20; k++) begin
            @(posedge clk);

            if (
                (expected_basic_q.size() == 0) &&
                (expected_pipe_q.size() == 0)
            ) begin
                return;
            end
        end

        error_count++;
        $error(
            "TIMEOUT: expected queues basic=%0d pipe=%0d",
            expected_basic_q.size(),
            expected_pipe_q.size()
        );
    end
endtask

always @(posedge clk) begin
    #1;

    if (resetn && basic_valid_o) begin
        check_count++;

        if (expected_basic_q.size() == 0) begin
            error_count++;
            $error("BASIC: unexpected valid");
        end else begin
            if (basic_acc_o !== expected_basic_q[0]) begin
                error_count++;
                $error(
                    "BASIC mismatch actual=%0d expected=%0d",
                    basic_acc_o,
                    expected_basic_q[0]
                );
            end else begin
                $display(
                    "PASS BASIC: acc=%0d",
                    basic_acc_o
                );
            end

            expected_basic_q.pop_front();
        end
    end

    if (resetn && pipe_valid_o) begin
        check_count++;

        if (expected_pipe_q.size() == 0) begin
            error_count++;
            $error("PIPE: unexpected valid");
        end else begin
            if (pipe_acc_o !== expected_pipe_q[0]) begin
                error_count++;
                $error(
                    "PIPE mismatch actual=%0d expected=%0d",
                    pipe_acc_o,
                    expected_pipe_q[0]
                );
            end else begin
                $display(
                    "PASS PIPE: acc=%0d",
                    pipe_acc_o
                );
            end

            expected_pipe_q.pop_front();
        end
    end
end

initial begin
    reference_acc = 32'sd0;

    repeat (5) @(posedge clk);
    resetn = 1'b1;

    // Directed signed/fixed-point cases.
    // FRAC_BITS = 7:
    // 64 -> +0.5, -32 -> -0.25.
    drive_valid(64, -32);   // product raw -2048 -> -0.125 real
    drive_valid(127, 127);  // max positive x max positive
    drive_valid(-128, 127); // min negative x max positive
    drive_valid(-128, -128);
    drive_valid(1, -1);
    drive_valid(0, 127);

    wait_queues_empty();
    clear_mac();

    // Random signed 8-bit regression.
    repeat (32) begin
        drive_valid(
            $signed($urandom_range(0, 255)),
            $signed($urandom_range(0, 255))
        );
    end

    wait_queues_empty();

    $display("");
    $display("SOC24 CHECK COUNT : %0d", check_count);
    $display("SOC24 ERROR COUNT : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC24 MAC SELF-CHECKING TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC24 MAC SELF-CHECKING TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
