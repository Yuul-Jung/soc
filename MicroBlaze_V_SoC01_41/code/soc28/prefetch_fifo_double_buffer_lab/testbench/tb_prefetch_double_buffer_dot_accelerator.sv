`timescale 1ns / 1ps

module tb_prefetch_double_buffer_dot_accelerator;

logic clk = 1'b0;
logic resetn = 1'b0;

// Load side.
logic        load_bank_i = 1'b0;
logic        load_active_i = 1'b0;

logic        act_wr_en_i = 1'b0;
logic [7:0]  act_wr_addr_i = 8'd0;
logic [31:0] act_wr_data_i = 32'h0;

logic        weight_wr_en_i = 1'b0;
logic [7:0]  weight_wr_addr_i = 8'd0;
logic [31:0] weight_wr_data_i = 32'h0;

// Compute side.
logic        compute_bank_i = 1'b0;
logic        start_i = 1'b0;
logic [15:0] vector_length_i = 16'd0;

logic        feed_stall_i = 1'b0;

wire         busy_o;
wire         done_o;
wire         result_valid_o;
wire signed [31:0] result_o;

wire [15:0] requested_groups_o;
wire [15:0] received_groups_o;
wire [15:0] delivered_groups_o;
wire [15:0] accepted_groups_o;
wire [15:0] completed_groups_o;

wire [2:0]  fifo_count_o;
wire [2:0]  outstanding_reads_o;

wire bank_conflict_o;
wire range_error_o;
wire response_mismatch_error_o;
wire fifo_overflow_error_o;

int error_count = 0;
int check_count = 0;

int stall_counter = 0;
bit stall_enable = 0;
int max_fifo_seen = 0;

always #5 clk = ~clk;

prefetch_double_buffer_dot_accelerator #(
    .ADDR_WIDTH(8)
) dut (
    .clk(clk),
    .resetn(resetn),

    .load_bank_i(load_bank_i),
    .load_active_i(load_active_i),

    .act_wr_en_i(act_wr_en_i),
    .act_wr_addr_i(act_wr_addr_i),
    .act_wr_data_i(act_wr_data_i),

    .weight_wr_en_i(weight_wr_en_i),
    .weight_wr_addr_i(weight_wr_addr_i),
    .weight_wr_data_i(weight_wr_data_i),

    .compute_bank_i(compute_bank_i),
    .start_i(start_i),
    .vector_length_i(vector_length_i),

    .feed_stall_i(feed_stall_i),

    .busy_o(busy_o),
    .done_o(done_o),
    .result_valid_o(result_valid_o),
    .result_o(result_o),

    .requested_groups_o(requested_groups_o),
    .received_groups_o(received_groups_o),
    .delivered_groups_o(delivered_groups_o),
    .accepted_groups_o(accepted_groups_o),
    .completed_groups_o(completed_groups_o),

    .fifo_count_o(fifo_count_o),
    .outstanding_reads_o(outstanding_reads_o),

    .bank_conflict_o(bank_conflict_o),
    .range_error_o(range_error_o),
    .response_mismatch_error_o(response_mismatch_error_o),
    .fifo_overflow_error_o(fifo_overflow_error_o)
);

always @(posedge clk) begin
    if (fifo_count_o > max_fifo_seen) begin
        max_fifo_seen <= fifo_count_o;
    end
end

// Deterministic consumer backpressure.
// Pattern contains both single-cycle and two-cycle stalls.
always @(negedge clk) begin
    if (!resetn) begin
        stall_counter <= 0;
        feed_stall_i <= 1'b0;
    end else if (stall_enable) begin
        stall_counter <= stall_counter + 1;

        feed_stall_i <=
            ((stall_counter % 7) == 2) ||
            ((stall_counter % 7) == 3) ||
            ((stall_counter % 11) == 6);
    end else begin
        feed_stall_i <= 1'b0;
        stall_counter <= 0;
    end
end

function automatic integer ceil_div4(
    input integer n
);
    ceil_div4 = (n + 3) / 4;
endfunction

function automatic integer signed signed8(
    input integer value
);
    integer temp;
    begin
        temp = value & 8'hFF;

        if (temp >= 128)
            temp = temp - 256;

        signed8 = temp;
    end
endfunction

function automatic integer signed gen_a0(
    input integer index
);
    gen_a0 = signed8((index * 29) + 17);
endfunction

function automatic integer signed gen_b0(
    input integer index
);
    gen_b0 = signed8((index * 47) + 91);
endfunction

function automatic integer signed gen_a1(
    input integer index
);
    gen_a1 = signed8((index * 13) + 33);
endfunction

function automatic integer signed gen_b1(
    input integer index
);
    gen_b1 = signed8((index * 19) + 7);
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
    input integer bank,
    input integer group_index,
    input integer length,
    input integer pattern_id,
    inout integer signed expected_acc
);
    integer lane;
    integer scalar_index;

    integer signed a_lane [0:3];
    integer signed b_lane [0:3];

    integer signed a_value;
    integer signed b_value;

    begin
        // Intentional garbage first. Tail elements must be masked later.
        for (lane = 0; lane < 4; lane++) begin
            a_lane[lane] = 127;
            b_lane[lane] = -128;
        end

        for (lane = 0; lane < 4; lane++) begin
            scalar_index = (group_index * 4) + lane;

            if (scalar_index < length) begin
                if (pattern_id == 0) begin
                    a_value = gen_a0(scalar_index);
                    b_value = gen_b0(scalar_index);
                end else begin
                    a_value = gen_a1(scalar_index);
                    b_value = gen_b1(scalar_index);
                end

                a_lane[lane] = a_value;
                b_lane[lane] = b_value;

                expected_acc =
                    expected_acc +
                    (a_value * b_value);
            end
        end

        @(negedge clk);

        load_bank_i = bank[0];
        load_active_i = 1'b1;

        act_wr_addr_i = group_index[7:0];
        act_wr_data_i = pack4(
            a_lane[0],
            a_lane[1],
            a_lane[2],
            a_lane[3]
        );
        act_wr_en_i = 1'b1;

        weight_wr_addr_i = group_index[7:0];
        weight_wr_data_i = pack4(
            b_lane[0],
            b_lane[1],
            b_lane[2],
            b_lane[3]
        );
        weight_wr_en_i = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        act_wr_en_i = 1'b0;
        weight_wr_en_i = 1'b0;
        load_active_i = 1'b0;
    end
endtask

task automatic load_vector(
    input integer bank,
    input integer length,
    input integer pattern_id,
    output integer signed expected_acc
);
    integer groups;
    integer group_index;

    begin
        groups = ceil_div4(length);
        expected_acc = 0;

        for (
            group_index = 0;
            group_index < groups;
            group_index++
        ) begin
            write_group(
                bank,
                group_index,
                length,
                pattern_id,
                expected_acc
            );
        end
    end
endtask

task automatic pulse_start(
    input integer bank,
    input integer length
);
    begin
        @(negedge clk);
        compute_bank_i = bank[0];
        vector_length_i = length[15:0];
        start_i = 1'b1;

        @(negedge clk);
        start_i = 1'b0;
    end
endtask

task automatic wait_and_check_result(
    input string name,
    input integer length,
    input integer signed expected_acc
);
    integer groups;
    integer timeout;

    begin
        groups = ceil_div4(length);
        timeout = 0;

        while (
            (result_valid_o !== 1'b1) &&
            (timeout < 4000)
        ) begin
            @(posedge clk);
            #1;
            timeout++;
        end

        check_true(
            {name, " result_valid"},
            result_valid_o === 1'b1
        );

        check_true(
            {name, " done"},
            done_o === 1'b1
        );

        check_eq32(
            {name, " result"},
            result_o,
            expected_acc
        );

        check_true(
            {name, " requested"},
            requested_groups_o == groups
        );

        check_true(
            {name, " received"},
            received_groups_o == groups
        );

        check_true(
            {name, " delivered"},
            delivered_groups_o == groups
        );

        check_true(
            {name, " accepted"},
            accepted_groups_o == groups
        );

        check_true(
            {name, " completed"},
            completed_groups_o == groups
        );

        check_true(
            {name, " no response mismatch"},
            response_mismatch_error_o === 1'b0
        );

        check_true(
            {name, " no FIFO overflow"},
            fifo_overflow_error_o === 1'b0
        );

        @(posedge clk);
        #1;
    end
endtask

task automatic attempt_same_bank_write_conflict;
    begin
        check_true(
            "compute still busy before conflict test",
            busy_o === 1'b1
        );

        @(negedge clk);

        load_bank_i = 1'b0;
        load_active_i = 1'b1;

        act_wr_addr_i = 8'd0;
        act_wr_data_i = 32'hDEAD_BEEF;
        act_wr_en_i = 1'b1;

        weight_wr_addr_i = 8'd0;
        weight_wr_data_i = 32'hCAFE_BABE;
        weight_wr_en_i = 1'b1;

        #1;

        check_true(
            "same-bank write conflict asserted",
            bank_conflict_o === 1'b1
        );

        @(posedge clk);
        #1;

        @(negedge clk);
        act_wr_en_i = 1'b0;
        weight_wr_en_i = 1'b0;
        load_active_i = 1'b0;
    end
endtask

task automatic run_range_error_case;
    begin
        @(negedge clk);

        compute_bank_i = 1'b0;
        vector_length_i = 16'd1025;
        start_i = 1'b1;

        #1;

        check_true(
            "length 1025 range error",
            range_error_o === 1'b1
        );

        @(posedge clk);
        #1;

        @(negedge clk);
        start_i = 1'b0;

        repeat (4) @(posedge clk);
        #1;

        check_true(
            "range error command not busy",
            busy_o === 1'b0
        );
    end
endtask

initial begin
    integer signed expected_bank0;
    integer signed expected_bank1;
    integer group_index;

    repeat (5) @(posedge clk);
    resetn = 1'b1;

    // --------------------------------------------------------
    // 1. Load Bank 0 completely.
    // --------------------------------------------------------
    load_vector(
        0,
        64,
        0,
        expected_bank0
    );

    // --------------------------------------------------------
    // 2. Start computing Bank 0 with backpressure enabled.
    // --------------------------------------------------------
    stall_enable = 1'b1;

    pulse_start(
        0,
        64
    );

    // --------------------------------------------------------
    // 3. While Bank 0 computes, load Bank 1.
    // --------------------------------------------------------
    expected_bank1 = 0;

    for (group_index = 0; group_index < ceil_div4(31); group_index++) begin
        write_group(
            1,
            group_index,
            31,
            1,
            expected_bank1
        );
    end

    // Wrong-bank write must be rejected while Bank 0 is active.
    attempt_same_bank_write_conflict();

    wait_and_check_result(
        "bank0",
        64,
        expected_bank0
    );

    check_true(
        "prefetch FIFO exercised",
        max_fifo_seen >= 2
    );

    // --------------------------------------------------------
    // 4. Compute the Bank 1 data loaded during Bank 0 compute.
    // --------------------------------------------------------
    stall_enable = 1'b1;

    pulse_start(
        1,
        31
    );

    wait_and_check_result(
        "bank1",
        31,
        expected_bank1
    );

    stall_enable = 1'b0;

    // --------------------------------------------------------
    // 5. Capacity guard.
    // --------------------------------------------------------
    run_range_error_case();

    $display("");
    $display("SOC28 MAX FIFO COUNT : %0d", max_fifo_seen);
    $display("SOC28 CHECK COUNT    : %0d", check_count);
    $display("SOC28 ERROR COUNT    : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC28 PREFETCH/DOUBLE-BUFFER TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC28 PREFETCH/DOUBLE-BUFFER TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
