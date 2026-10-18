`timescale 1ns / 1ps

module tb_local_bram_dot_accelerator;

logic clk = 1'b0;
logic resetn = 1'b0;

logic        act_wr_en_i = 1'b0;
logic [7:0]  act_wr_addr_i = 8'd0;
logic [31:0] act_wr_data_i = 32'h0;

logic        weight_wr_en_i = 1'b0;
logic [7:0]  weight_wr_addr_i = 8'd0;
logic [31:0] weight_wr_data_i = 32'h0;

logic        start_i = 1'b0;
logic [15:0] vector_length_i = 16'd0;

wire         busy_o;
wire         done_o;
wire         result_valid_o;
wire signed [31:0] result_o;

wire [15:0] requested_groups_o;
wire [15:0] delivered_groups_o;
wire [15:0] accepted_groups_o;
wire [15:0] completed_groups_o;
wire         range_error_o;

int error_count = 0;
int check_count = 0;

always #5 clk = ~clk;

local_bram_dot_accelerator #(
    .ADDR_WIDTH(8)
) dut (
    .clk(clk),
    .resetn(resetn),

    .act_wr_en_i(act_wr_en_i),
    .act_wr_addr_i(act_wr_addr_i),
    .act_wr_data_i(act_wr_data_i),

    .weight_wr_en_i(weight_wr_en_i),
    .weight_wr_addr_i(weight_wr_addr_i),
    .weight_wr_data_i(weight_wr_data_i),

    .start_i(start_i),
    .vector_length_i(vector_length_i),

    .busy_o(busy_o),
    .done_o(done_o),
    .result_valid_o(result_valid_o),
    .result_o(result_o),

    .requested_groups_o(requested_groups_o),
    .delivered_groups_o(delivered_groups_o),
    .accepted_groups_o(accepted_groups_o),
    .completed_groups_o(completed_groups_o),

    .range_error_o(range_error_o)
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
        temp = ((scalar_index * 29) + 17) & 8'hFF;

        if (temp >= 128)
            temp = temp - 256;

        gen_a = temp;
    end
endfunction

function automatic integer signed gen_b(
    input integer scalar_index
);
    integer temp;
    begin
        temp = ((scalar_index * 47) + 91) & 8'hFF;

        if (temp >= 128)
            temp = temp - 256;

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

task automatic write_group(
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
        // Intentional garbage in all lanes first.
        a0 = 127;
        a1 = 127;
        a2 = 127;
        a3 = 127;

        b0 = -128;
        b1 = -128;
        b2 = -128;
        b3 = -128;

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

        act_wr_addr_i = group_index[7:0];
        act_wr_data_i = pack4(a0, a1, a2, a3);
        act_wr_en_i = 1'b1;

        weight_wr_addr_i = group_index[7:0];
        weight_wr_data_i = pack4(b0, b1, b2, b3);
        weight_wr_en_i = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        act_wr_en_i = 1'b0;
        weight_wr_en_i = 1'b0;
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

task automatic run_case(
    input integer length
);
    integer groups;
    integer group_index;
    integer timeout;
    integer signed expected_acc;

    begin
        groups = ceil_div4(length);
        expected_acc = 0;

        $display("");
        $display(
            "RUN length=%0d groups=%0d",
            length,
            groups
        );

        for (
            group_index = 0;
            group_index < groups;
            group_index++
        ) begin
            write_group(
                group_index,
                length,
                expected_acc
            );
        end

        pulse_start(length);

        timeout = 0;

        while (
            (result_valid_o !== 1'b1) &&
            (timeout < 2000)
        ) begin
            @(posedge clk);
            #1;
            timeout++;
        end

        check_true(
            "result_valid arrived",
            result_valid_o === 1'b1
        );

        check_true(
            "done with result",
            done_o === 1'b1
        );

        check_eq32(
            "local BRAM vector result",
            result_o,
            expected_acc
        );

        check_true(
            "requested group count",
            requested_groups_o == groups
        );

        check_true(
            "delivered group count",
            delivered_groups_o == groups
        );

        check_true(
            "accepted group count",
            accepted_groups_o == groups
        );

        check_true(
            "completed group count",
            completed_groups_o == groups
        );

        check_true(
            "busy low at completion",
            busy_o === 1'b0
        );

        @(posedge clk);
        #1;
    end
endtask

task automatic run_range_error_case;
    begin
        $display("");
        $display("RUN out-of-range length=1025");

        @(negedge clk);
        vector_length_i = 16'd1025;
        start_i = 1'b1;
        #1;

        check_true(
            "range error asserted",
            range_error_o === 1'b1
        );

        @(posedge clk);
        #1;

        @(negedge clk);
        start_i = 1'b0;

        repeat (4) @(posedge clk);
        #1;

        check_true(
            "invalid command did not start busy",
            busy_o === 1'b0
        );

        check_true(
            "invalid command did not produce result",
            result_valid_o === 1'b0
        );
    end
endtask

initial begin
    repeat (5) @(posedge clk);
    resetn = 1'b1;

    run_case(0);
    run_case(1);
    run_case(2);
    run_case(3);
    run_case(4);
    run_case(5);
    run_case(10);
    run_case(16);
    run_case(17);
    run_case(31);
    run_case(64);

    run_range_error_case();

    $display("");
    $display("SOC27 CHECK COUNT : %0d", check_count);
    $display("SOC27 ERROR COUNT : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC27 LOCAL BRAM FEEDING TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC27 LOCAL BRAM FEEDING TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
