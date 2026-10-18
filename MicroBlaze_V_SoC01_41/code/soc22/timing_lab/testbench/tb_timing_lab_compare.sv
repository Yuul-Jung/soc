`timescale 1ns / 1ps

module tb_timing_lab_compare;

logic clk = 1'b0;
logic resetn = 1'b0;

logic [31:0] a_i;
logic [31:0] b_i;
logic [31:0] c_i;
logic [31:0] d_i;
logic [31:0] e_i;
logic [31:0] f_i;
logic [31:0] g_i;
logic [31:0] h_i;
logic        valid_i;

wire [31:0] unpipelined_result_o;
wire        unpipelined_valid_o;

wire [31:0] pipelined_result_o;
wire        pipelined_valid_o;

int errors = 0;
int checks = 0;

logic [31:0] expected_unpipelined_q[$];
logic [31:0] expected_pipelined_q[$];

always #5 clk = ~clk;

timing_lab_compare_top dut (
    .clk(clk),
    .resetn(resetn),

    .a_i(a_i),
    .b_i(b_i),
    .c_i(c_i),
    .d_i(d_i),
    .e_i(e_i),
    .f_i(f_i),
    .g_i(g_i),
    .h_i(h_i),
    .valid_i(valid_i),

    .unpipelined_result_o(unpipelined_result_o),
    .unpipelined_valid_o(unpipelined_valid_o),

    .pipelined_result_o(pipelined_result_o),
    .pipelined_valid_o(pipelined_valid_o)
);

function automatic logic [31:0] reference_model(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic [31:0] d,
    input logic [31:0] e,
    input logic [31:0] f,
    input logic [31:0] g,
    input logic [31:0] h
);
    logic [31:0] t1;
    logic [31:0] t2;
    logic [31:0] t3;
    logic [31:0] t4;
    logic [31:0] t5;
    logic [31:0] t6;
    logic [31:0] t7;
    logic [31:0] t8;

    begin
        t1 = a + b;
        t2 = t1 ^ {c[15:0], c[31:16]};
        t3 = t2 + d;
        t4 = {t3[30:0], t3[31]} ^ e;
        t5 = t4 + f;
        t6 = t5 ^ {g[7:0], g[31:8]};
        t7 = t6 + h;
        t8 = (t7 ^ {t7[3:0], t7[31:4]}) + 32'h1357_9BDF;

        reference_model = t8;
    end
endfunction

task automatic drive_case(
    input logic [31:0] a,
    input logic [31:0] b,
    input logic [31:0] c,
    input logic [31:0] d,
    input logic [31:0] e,
    input logic [31:0] f,
    input logic [31:0] g,
    input logic [31:0] h
);
    begin
        @(negedge clk);

        a_i = a;
        b_i = b;
        c_i = c;
        d_i = d;
        e_i = e;
        f_i = f;
        g_i = g;
        h_i = h;
        valid_i = 1'b1;

        expected_unpipelined_q.push_back(
            reference_model(a, b, c, d, e, f, g, h)
        );

        expected_pipelined_q.push_back(
            reference_model(a, b, c, d, e, f, g, h)
        );
    end
endtask

task automatic stop_input;
    begin
        @(negedge clk);
        valid_i = 1'b0;
    end
endtask

always @(posedge clk) begin
    if (resetn && unpipelined_valid_o) begin
        checks++;

        if (expected_unpipelined_q.size() == 0) begin
            errors++;
            $error("UNPIPELINED: unexpected valid");
        end else if (
            unpipelined_result_o !== expected_unpipelined_q[0]
        ) begin
            errors++;
            $error(
                "UNPIPELINED mismatch actual=%08h expected=%08h",
                unpipelined_result_o,
                expected_unpipelined_q[0]
            );
            expected_unpipelined_q.pop_front();
        end else begin
            $display(
                "PASS: unpipelined result=%08h",
                unpipelined_result_o
            );
            expected_unpipelined_q.pop_front();
        end
    end

    if (resetn && pipelined_valid_o) begin
        checks++;

        if (expected_pipelined_q.size() == 0) begin
            errors++;
            $error("PIPELINED: unexpected valid");
        end else if (
            pipelined_result_o !== expected_pipelined_q[0]
        ) begin
            errors++;
            $error(
                "PIPELINED mismatch actual=%08h expected=%08h",
                pipelined_result_o,
                expected_pipelined_q[0]
            );
            expected_pipelined_q.pop_front();
        end else begin
            $display(
                "PASS: pipelined result=%08h",
                pipelined_result_o
            );
            expected_pipelined_q.pop_front();
        end
    end
end

initial begin
    a_i = 0;
    b_i = 0;
    c_i = 0;
    d_i = 0;
    e_i = 0;
    f_i = 0;
    g_i = 0;
    h_i = 0;
    valid_i = 0;

    repeat (5) @(posedge clk);
    resetn = 1'b1;

    drive_case(
        32'h0000_0001,
        32'h0000_0002,
        32'h1234_5678,
        32'h0000_0010,
        32'hA5A5_5A5A,
        32'h0102_0304,
        32'h89AB_CDEF,
        32'h0000_1000
    );

    drive_case(
        32'hFFFF_FFFF,
        32'h0000_0001,
        32'h0F0F_F0F0,
        32'h1111_1111,
        32'h2222_2222,
        32'h3333_3333,
        32'h4444_4444,
        32'h5555_5555
    );

    repeat (20) begin
        drive_case(
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom(),
            $urandom()
        );
    end

    stop_input();

    repeat (8) @(posedge clk);

    if (expected_unpipelined_q.size() != 0) begin
        errors++;
        $error(
            "Unpipelined expected queue not empty: %0d entries",
            expected_unpipelined_q.size()
        );
    end

    if (expected_pipelined_q.size() != 0) begin
        errors++;
        $error(
            "Pipelined expected queue not empty: %0d entries",
            expected_pipelined_q.size()
        );
    end

    $display("");
    $display("SOC22 CHECK COUNT : %0d", checks);
    $display("SOC22 ERROR COUNT : %0d", errors);

    if (errors == 0) begin
        $display("SOC22 FUNCTIONAL REGRESSION: PASS");
    end else begin
        $fatal(
            1,
            "SOC22 FUNCTIONAL REGRESSION: FAIL (%0d errors)",
            errors
        );
    end

    #30;
    $finish;
end

endmodule
