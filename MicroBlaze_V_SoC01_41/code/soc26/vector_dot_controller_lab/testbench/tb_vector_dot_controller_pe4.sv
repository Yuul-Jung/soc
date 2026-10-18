`timescale 1ns / 1ps

module tb_vector_dot_controller_pe4;

logic clk = 1'b0;
logic resetn = 1'b0;

logic        start_i = 1'b0;
logic [15:0] vector_length_i = 16'd0;

logic        vec_valid_i = 1'b0;
wire         vec_ready_o;
logic [31:0] a_vec_i = 32'h0;
logic [31:0] b_vec_i = 32'h0;

wire         busy_o;
wire         done_o;
wire         result_valid_o;
wire signed [31:0] result_o;

wire [15:0] accepted_groups_o;
wire [15:0] completed_groups_o;

int error_count = 0;
int check_count = 0;

always #5 clk = ~clk;

vector_dot_controller_pe4 dut (
    .clk(clk),
    .resetn(resetn),

    .start_i(start_i),
    .vector_length_i(vector_length_i),

    .vec_valid_i(vec_valid_i),
    .vec_ready_o(vec_ready_o),
    .a_vec_i(a_vec_i),
    .b_vec_i(b_vec_i),

    .busy_o(busy_o),
    .done_o(done_o),
    .result_valid_o(result_valid_o),
    .result_o(result_o),

    .accepted_groups_o(accepted_groups_o),
    .completed_groups_o(completed_groups_o)
);

function automatic integer ceil_div4(
    input integer n
);
    ceil_div4 = (n + 3) / 4;
endfunction

function automatic integer signed gen_a(
    input integer scalar_index
);
    integer temp;

    begin
        // Deterministic signed 8-bit pattern.
        temp = ((scalar_index * 29) + 17) & 8'hFF;

        if (temp >= 128) begin
            temp = temp - 256;
        end

        gen_a = temp;
    end
endfunction

function automatic integer signed gen_b(
    input integer scalar_index
);
    integer temp;

    begin
        temp = ((scalar_index * 47) + 91) & 8'hFF;

        if (temp >= 128) begin
            temp = temp - 256;
        end

        gen_b = temp;
    end
endfunction

function automatic [31:0] pack4(
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

task automatic check_true(
    input string name,
    input bit condition
);
    begin
        check_count++;

        if (!condition) begin
            error_count++;
            $error("CHECK FAIL: %s", name);
        end else begin
            $display("CHECK PASS: %s", name);
        end
    end
endtask

task automatic check_eq32(
    input string name,
    input logic signed [31:0] actual,
    input logic signed [31:0] expected
);
    begin
        check_count++;

        if (actual !== expected) begin
            error_count++;
            $error(
                "CHECK FAIL: %s actual=%0d expected=%0d",
                name,
                actual,
                expected
            );
        end else begin
            $display(
                "CHECK PASS: %s = %0d",
                name,
                actual
            );
        end
    end
endtask

task automatic pulse_start(
    input integer length
);
    begin
        @(negedge clk);
        vector_length_i = length[15:0];
        start_i = 1'b1;

        @(negedge clk);
        start_i = 1'b0;
    end
endtask

task automatic drive_group(
    input integer group_index,
    input integer length,
    inout integer signed expected_acc
);
    integer lane;
    integer scalar_index;

    integer signed a0;
    integer signed a1;
    integer signed a2;
    integer signed a3;

    integer signed b0;
    integer signed b1;
    integer signed b2;
    integer signed b3;

    integer signed lane_a;
    integer signed lane_b;

    begin
        // Deliberately insert a one-cycle source gap before odd groups.
        if ((group_index & 1) != 0) begin
            @(negedge clk);
            vec_valid_i = 1'b0;
            a_vec_i = 32'h0;
            b_vec_i = 32'h0;
        end

        while (vec_ready_o !== 1'b1) begin
            @(negedge clk);
        end

        a0 = 127;
        a1 = 127;
        a2 = 127;
        a3 = 127;

        b0 = -128;
        b1 = -128;
        b2 = -128;
        b3 = -128;

        // Values beyond vector_length are intentional garbage.
        // The DUT tail-mask must remove them.
        for (lane = 0; lane < 4; lane++) begin
            scalar_index = (group_index * 4) + lane;

            if (scalar_index < length) begin
                lane_a = gen_a(scalar_index);
                lane_b = gen_b(scalar_index);

                expected_acc =
                    expected_acc +
                    (lane_a * lane_b);

                case (lane)
                    0: begin a0 = lane_a; b0 = lane_b; end
                    1: begin a1 = lane_a; b1 = lane_b; end
                    2: begin a2 = lane_a; b2 = lane_b; end
                    3: begin a3 = lane_a; b3 = lane_b; end
                endcase
            end
        end

        @(negedge clk);

        while (vec_ready_o !== 1'b1) begin
            @(negedge clk);
        end

        a_vec_i = pack4(a0, a1, a2, a3);
        b_vec_i = pack4(b0, b1, b2, b3);
        vec_valid_i = 1'b1;

        // READY is checked before the sampling edge because the DUT may
        // deassert READY immediately after the final group is accepted.
        check_true(
            "group presented only when ready",
            vec_ready_o === 1'b1
        );

        // Handshake occurs on the next rising edge.
        @(posedge clk);
        #1;

        @(negedge clk);
        vec_valid_i = 1'b0;
    end
endtask

task automatic run_case(
    input integer length
);
    integer group_count;
    integer group_index;
    integer signed expected_acc;
    integer timeout;

    begin
        expected_acc = 0;
        group_count = ceil_div4(length);

        $display("");
        $display(
            "RUN length=%0d groups=%0d",
            length,
            group_count
        );

        pulse_start(length);

        if (length == 0) begin
            timeout = 0;

            while (
                (result_valid_o !== 1'b1) &&
                (timeout < 20)
            ) begin
                @(posedge clk);
                #1;
                timeout++;
            end

            check_true(
                "zero-length result_valid",
                result_valid_o === 1'b1
            );

            check_true(
                "zero-length done",
                done_o === 1'b1
            );

            check_eq32(
                "zero-length result",
                result_o,
                32'sd0
            );

            check_true(
                "zero-length busy low",
                busy_o === 1'b0
            );

            @(posedge clk);
            #1;
            return;
        end

        // Wait for CLEAR state to finish and FEED to begin.
        while (vec_ready_o !== 1'b1) begin
            @(posedge clk);
            #1;
        end

        check_true(
            "busy asserted during operation",
            busy_o === 1'b1
        );

        for (
            group_index = 0;
            group_index < group_count;
            group_index++
        ) begin
            drive_group(
                group_index,
                length,
                expected_acc
            );
        end

        // Tail garbage has been sent for partial final groups.
        // Now wait for the PE pipeline to drain.
        timeout = 0;

        while (
            (result_valid_o !== 1'b1) &&
            (timeout < 100)
        ) begin
            @(posedge clk);
            #1;
            timeout++;
        end

        check_true(
            "result_valid after pipeline drain",
            result_valid_o === 1'b1
        );

        check_true(
            "done with result_valid",
            done_o === 1'b1
        );

        check_true(
            "busy low when done pulses",
            busy_o === 1'b0
        );

        check_eq32(
            "vector dot result",
            result_o,
            expected_acc
        );

        check_true(
            "accepted group count",
            accepted_groups_o == group_count
        );

        check_true(
            "completed group count",
            completed_groups_o == group_count
        );

        @(posedge clk);
        #1;

        check_true(
            "result_valid is one-cycle pulse",
            result_valid_o === 1'b0
        );
    end
endtask

initial begin
    repeat (5) @(posedge clk);
    resetn = 1'b1;

    // Zero length is explicitly defined as immediate result 0.
    run_case(0);

    // Every tail size: 1, 2, 3, and full 4 lanes.
    run_case(1);
    run_case(2);
    run_case(3);
    run_case(4);

    // Multiple groups + tail cases.
    run_case(5);
    run_case(10);
    run_case(16);
    run_case(17);
    run_case(31);

    $display("");
    $display("SOC26 CHECK COUNT : %0d", check_count);
    $display("SOC26 ERROR COUNT : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC26 VECTOR CONTROLLER TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC26 VECTOR CONTROLLER TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
