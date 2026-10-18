`timescale 1ns / 1ps

module tb_pe4_dot_accum_compare;

logic clk = 1'b0;
logic resetn = 1'b0;
logic clear_i = 1'b0;
logic valid_i = 1'b0;

logic [31:0] a_vec_i = 32'h0;
logic [31:0] b_vec_i = 32'h0;

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

pe4_dot_accum_basic u_basic (
    .clk(clk),
    .resetn(resetn),
    .clear_i(clear_i),
    .valid_i(valid_i),
    .a_vec_i(a_vec_i),
    .b_vec_i(b_vec_i),
    .acc_o(basic_acc_o),
    .valid_o(basic_valid_o)
);

pe4_dot_accum_pipelined u_pipe (
    .clk(clk),
    .resetn(resetn),
    .clear_i(clear_i),
    .valid_i(valid_i),
    .a_vec_i(a_vec_i),
    .b_vec_i(b_vec_i),
    .acc_o(pipe_acc_o),
    .valid_o(pipe_valid_o)
);

function automatic logic [31:0] pack4(
    input integer x0,
    input integer x1,
    input integer x2,
    input integer x3
);
    begin
        pack4 = {
            x3[7:0],
            x2[7:0],
            x1[7:0],
            x0[7:0]
        };
    end
endfunction

function automatic logic signed [17:0] dot4_reference(
    input logic [31:0] avec,
    input logic [31:0] bvec
);
    logic signed [7:0] a0;
    logic signed [7:0] a1;
    logic signed [7:0] a2;
    logic signed [7:0] a3;

    logic signed [7:0] b0;
    logic signed [7:0] b1;
    logic signed [7:0] b2;
    logic signed [7:0] b3;

    logic signed [15:0] p0;
    logic signed [15:0] p1;
    logic signed [15:0] p2;
    logic signed [15:0] p3;

    logic signed [16:0] s01;
    logic signed [16:0] s23;

    begin
        a0 = $signed(avec[7:0]);
        a1 = $signed(avec[15:8]);
        a2 = $signed(avec[23:16]);
        a3 = $signed(avec[31:24]);

        b0 = $signed(bvec[7:0]);
        b1 = $signed(bvec[15:8]);
        b2 = $signed(bvec[23:16]);
        b3 = $signed(bvec[31:24]);

        p0 = a0 * b0;
        p1 = a1 * b1;
        p2 = a2 * b2;
        p3 = a3 * b3;

        s01 =
            $signed({p0[15], p0}) +
            $signed({p1[15], p1});

        s23 =
            $signed({p2[15], p2}) +
            $signed({p3[15], p3});

        dot4_reference =
            $signed({s01[16], s01}) +
            $signed({s23[16], s23});
    end
endfunction

function automatic logic signed [31:0] accum_reference(
    input logic signed [31:0] acc,
    input logic [31:0] avec,
    input logic [31:0] bvec
);
    logic signed [17:0] dot4;
    logic signed [31:0] dot4_ext;

    begin
        dot4 = dot4_reference(avec, bvec);

        dot4_ext = {
            {14{dot4[17]}},
            dot4
        };

        accum_reference = acc + dot4_ext;
    end
endfunction

task automatic drive_vector(
    input integer a0,
    input integer a1,
    input integer a2,
    input integer a3,
    input integer b0,
    input integer b1,
    input integer b2,
    input integer b3
);
    logic [31:0] avec;
    logic [31:0] bvec;
    logic signed [31:0] next_acc;

    begin
        @(negedge clk);

        avec = pack4(a0, a1, a2, a3);
        bvec = pack4(b0, b1, b2, b3);

        a_vec_i = avec;
        b_vec_i = bvec;
        valid_i = 1'b1;
        clear_i = 1'b0;

        next_acc = accum_reference(
            reference_acc,
            avec,
            bvec
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
        a_vec_i = 32'h0;
        b_vec_i = 32'h0;
    end
endtask

task automatic wait_queues_empty;
    int k;

    begin
        drive_idle();

        for (k = 0; k < 32; k++) begin
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
            "TIMEOUT: basic_q=%0d pipe_q=%0d",
            expected_basic_q.size(),
            expected_pipe_q.size()
        );
    end
endtask

task automatic clear_pe;
    begin
        wait_queues_empty();

        @(negedge clk);
        clear_i = 1'b1;
        valid_i = 1'b0;

        @(negedge clk);
        clear_i = 1'b0;

        reference_acc = 32'sd0;
    end
endtask

always @(posedge clk) begin
    #1;

    if (resetn && basic_valid_o) begin
        check_count++;

        if (expected_basic_q.size() == 0) begin
            error_count++;
            $error("BASIC PE4: unexpected valid");
        end else begin
            if (basic_acc_o !== expected_basic_q[0]) begin
                error_count++;
                $error(
                    "BASIC PE4 mismatch actual=%0d expected=%0d",
                    basic_acc_o,
                    expected_basic_q[0]
                );
            end else begin
                $display(
                    "PASS BASIC PE4: acc=%0d",
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
            $error("PIPE PE4: unexpected valid");
        end else begin
            if (pipe_acc_o !== expected_pipe_q[0]) begin
                error_count++;
                $error(
                    "PIPE PE4 mismatch actual=%0d expected=%0d",
                    pipe_acc_o,
                    expected_pipe_q[0]
                );
            end else begin
                $display(
                    "PASS PIPE PE4: acc=%0d",
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

    // 4 lanes of +0.5 * +0.5.
    // Each lane = 0.25, dot4 = 1.0.
    drive_vector(
        64, 64, 64, 64,
        64, 64, 64, 64
    );

    // Mixed signs, dot4 = 0.0.
    drive_vector(
        64, -64, 32, -32,
        64, 64, 64, 64
    );

    // Worst positive lane product: -128 * -128.
    // Four lanes produce raw dot4 = 65536.
    drive_vector(
        -128, -128, -128, -128,
        -128, -128, -128, -128
    );

    // Large negative dot product.
    drive_vector(
        -128, -128, -128, -128,
        127, 127, 127, 127
    );

    wait_queues_empty();
    clear_pe();

    // Random signed 8-bit vectors.
    repeat (32) begin
        drive_vector(
            $urandom_range(0, 255),
            $urandom_range(0, 255),
            $urandom_range(0, 255),
            $urandom_range(0, 255),
            $urandom_range(0, 255),
            $urandom_range(0, 255),
            $urandom_range(0, 255),
            $urandom_range(0, 255)
        );
    end

    wait_queues_empty();

    $display("");
    $display("SOC25 CHECK COUNT : %0d", check_count);
    $display("SOC25 ERROR COUNT : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC25 PE4 SELF-CHECKING TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC25 PE4 SELF-CHECKING TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
