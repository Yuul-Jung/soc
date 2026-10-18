`timescale 1ns / 1ps

module tb_ws_tiled_batch_engine;

logic clk = 1'b0;
logic resetn = 1'b0;

logic job_start_i = 1'b0;

logic tile_start_i = 1'b0;
wire  tile_ready_o;
logic tile_last_i = 1'b0;

logic [31:0] weight_ch0_vec_i = 32'h0;
logic [31:0] weight_ch1_vec_i = 32'h0;

logic act_valid_i = 1'b0;
wire  act_ready_o;
logic [1:0] act_sample_id_i = 2'd0;
logic [31:0] act_vec_i = 32'h0;

wire tile_done_o;
wire job_done_o;
wire result_valid_o;

wire [127:0] result_ch0_batch_o;
wire [127:0] result_ch1_batch_o;

wire [15:0] weight_tile_loads_o;
wire [15:0] activation_groups_o;
wire [15:0] dot_results_o;

int error_count = 0;
int check_count = 0;

integer signed expected_ch0 [0:3];
integer signed expected_ch1 [0:3];

always #5 clk = ~clk;

ws_tiled_batch_engine dut (
    .clk(clk),
    .resetn(resetn),

    .job_start_i(job_start_i),

    .tile_start_i(tile_start_i),
    .tile_ready_o(tile_ready_o),
    .tile_last_i(tile_last_i),

    .weight_ch0_vec_i(weight_ch0_vec_i),
    .weight_ch1_vec_i(weight_ch1_vec_i),

    .act_valid_i(act_valid_i),
    .act_ready_o(act_ready_o),
    .act_sample_id_i(act_sample_id_i),
    .act_vec_i(act_vec_i),

    .tile_done_o(tile_done_o),
    .job_done_o(job_done_o),
    .result_valid_o(result_valid_o),

    .result_ch0_batch_o(result_ch0_batch_o),
    .result_ch1_batch_o(result_ch1_batch_o),

    .weight_tile_loads_o(weight_tile_loads_o),
    .activation_groups_o(activation_groups_o),
    .dot_results_o(dot_results_o)
);

function automatic integer signed signed8(
    input integer value
);
    integer temp;

    begin
        temp = value & 8'hFF;

        if (temp >= 128) begin
            temp = temp - 256;
        end

        signed8 = temp;
    end
endfunction

function automatic integer signed weight0_value(
    input integer k
);
    begin
        weight0_value =
            signed8(((k * 3) + 5) % 17 - 8);
    end
endfunction

function automatic integer signed weight1_value(
    input integer k
);
    begin
        weight1_value =
            signed8(((k * 5) + 2) % 19 - 9);
    end
endfunction

function automatic integer signed activation_value(
    input integer sample_id,
    input integer k
);
    begin
        activation_value =
            signed8(
                (((sample_id + 1) * 7) + (k * 4)) % 23 - 11
            );
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

// (변경) SystemVerilog 예약어와 충돌하지 않는 packed_result를 사용한다.
function automatic logic signed [31:0] unpack_result(
    input [127:0] packed_result,
    input integer sample_id
);
    begin
        case (sample_id)
            0: unpack_result = $signed(packed_result[31:0]);
            1: unpack_result = $signed(packed_result[63:32]);
            2: unpack_result = $signed(packed_result[95:64]);
            default: unpack_result = $signed(packed_result[127:96]);
        endcase
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

task automatic pulse_job_start;
    begin
        @(negedge clk);
        job_start_i = 1'b1;

        @(negedge clk);
        job_start_i = 1'b0;
    end
endtask

task automatic start_tile(
    input integer tile_index
);
    integer base_k;

    begin
        base_k = tile_index * 4;

        while (tile_ready_o !== 1'b1) begin
            @(negedge clk);
        end

        @(negedge clk);

        weight_ch0_vec_i = pack4(
            weight0_value(base_k + 0),
            weight0_value(base_k + 1),
            weight0_value(base_k + 2),
            weight0_value(base_k + 3)
        );

        weight_ch1_vec_i = pack4(
            weight1_value(base_k + 0),
            weight1_value(base_k + 1),
            weight1_value(base_k + 2),
            weight1_value(base_k + 3)
        );

        tile_last_i = (tile_index == 3);
        tile_start_i = 1'b1;

        @(negedge clk);
        tile_start_i = 1'b0;
        tile_last_i = 1'b0;
    end
endtask

task automatic send_activation(
    input integer sample_id,
    input integer tile_index
);
    integer base_k;
    integer signed a0;
    integer signed a1;
    integer signed a2;
    integer signed a3;

    begin
        base_k = tile_index * 4;

        a0 = activation_value(sample_id, base_k + 0);
        a1 = activation_value(sample_id, base_k + 1);
        a2 = activation_value(sample_id, base_k + 2);
        a3 = activation_value(sample_id, base_k + 3);

        // Deliberate source gap before odd samples.
        if ((sample_id & 1) != 0) begin
            @(negedge clk);
            act_valid_i = 1'b0;
        end

        while (act_ready_o !== 1'b1) begin
            @(negedge clk);
        end

        @(negedge clk);

        act_sample_id_i = sample_id[1:0];
        act_vec_i = pack4(a0, a1, a2, a3);
        act_valid_i = 1'b1;

        // Check READY before the sampling edge. On the fourth sample,
        // the engine may leave FEED immediately after that edge.
        check_true(
            "activation presented only in FEED",
            act_ready_o === 1'b1
        );

        @(posedge clk);
        #1;

        @(negedge clk);
        act_valid_i = 1'b0;
    end
endtask

task automatic wait_tile_done;
    integer timeout;

    begin
        timeout = 0;

        while (
            (tile_done_o !== 1'b1) &&
            (timeout < 100)
        ) begin
            @(posedge clk);
            #1;
            timeout++;
        end

        check_true(
            "tile_done arrived",
            tile_done_o === 1'b1
        );
    end
endtask

initial begin
    integer tile_index;
    integer sample_id;
    integer k;

    for (sample_id = 0; sample_id < 4; sample_id++) begin
        expected_ch0[sample_id] = 0;
        expected_ch1[sample_id] = 0;

        for (k = 0; k < 16; k++) begin
            expected_ch0[sample_id] =
                expected_ch0[sample_id] +
                activation_value(sample_id, k) *
                weight0_value(k);

            expected_ch1[sample_id] =
                expected_ch1[sample_id] +
                activation_value(sample_id, k) *
                weight1_value(k);
        end
    end

    repeat (5) @(posedge clk);
    resetn = 1'b1;

    pulse_job_start();

    for (tile_index = 0; tile_index < 4; tile_index++) begin
        start_tile(tile_index);

        for (sample_id = 0; sample_id < 4; sample_id++) begin
            send_activation(
                sample_id,
                tile_index
            );
        end

        wait_tile_done();
    end

    // Final results follow the final tile completion.
    while (result_valid_o !== 1'b1) begin
        @(posedge clk);
        #1;
    end

    check_true(
        "job_done with final result",
        job_done_o === 1'b1
    );

    for (sample_id = 0; sample_id < 4; sample_id++) begin
        check_eq32(
            $sformatf("CH0 sample%0d", sample_id),
            unpack_result(result_ch0_batch_o, sample_id),
            expected_ch0[sample_id]
        );

        check_eq32(
            $sformatf("CH1 sample%0d", sample_id),
            unpack_result(result_ch1_batch_o, sample_id),
            expected_ch1[sample_id]
        );
    end

    check_true(
        "weight tile load count = 4",
        weight_tile_loads_o == 16'd4
    );

    check_true(
        "activation group count = 16",
        activation_groups_o == 16'd16
    );

    check_true(
        "dot result count = 32",
        dot_results_o == 16'd32
    );

    $display("");
    $display("SOC29 WEIGHT LOADS      : %0d", weight_tile_loads_o);
    $display("SOC29 ACTIVATION GROUPS : %0d", activation_groups_o);
    $display("SOC29 DOT RESULTS       : %0d", dot_results_o);
    $display("SOC29 CHECK COUNT       : %0d", check_count);
    $display("SOC29 ERROR COUNT       : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC29 WEIGHT-STATIONARY/TILING TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC29 WEIGHT-STATIONARY/TILING TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
