module tensor_job_engine_parallel4_requant #(
    parameter integer BRAM_READ_LATENCY = 1
) (
    input  wire                 clk,
    input  wire                 resetn,

    input  wire                 start_i,

    input  wire [11:0]          input_base_i,
    input  wire [11:0]          output_base_i,
    input  wire [15:0]          length_words_i,

    input  wire signed [31:0]   bias_ch0_i,
    input  wire signed [31:0]   bias_ch1_i,

    input  wire signed [15:0]   mult_ch0_i,
    input  wire signed [15:0]   mult_ch1_i,

    input  wire        [5:0]    shift_ch0_i,
    input  wire        [5:0]    shift_ch1_i,

    input  wire signed [15:0]   zp_ch0_i,
    input  wire signed [15:0]   zp_ch1_i,

    output wire                 busy_o,
    output reg                  done_o,
    output reg                  error_o,

    output reg                  bram_en_o,
    output reg  [3:0]           bram_we_o,
    output reg  [11:0]          bram_addr_o,
    output reg  [31:0]          bram_wdata_o,
    input  wire [31:0]          bram_rdata_i,

    output reg  [15:0]          read_word_count_o,
    output reg  [15:0]          write_word_count_o
);

// ------------------------------------------------------------
// SoC 39 · Pipelined BRAM Read + 4-Lane Parallel Requantization
// ------------------------------------------------------------
//
// Baseline:
//   READ_REQ -> READ_CAPTURE -> READ_REQ -> READ_CAPTURE ...
//   8 words -> 16 cycles
//
// Optimized:
//   issue word0
//   issue word1 + wait/capture pipeline
//   issue word2 + capture word0
//   ...
//   drain final read
//
// With BRAM_READ_LATENCY=1:
//   8 words -> 9 cycles
//
// Important:
// - The BRAM remains synchronous.
// - This design does NOT remove a BRAM output register.
// - It pipelines requests so the read latency is hidden after startup.
// - If the actual BMG Port-B read latency is changed, set
//   BRAM_READ_LATENCY to match the configured synchronous output latency.
// - BRAM_READ_LATENCY must be >= 1.

localparam [2:0] ST_IDLE          = 3'd0;
localparam [2:0] ST_READ_STREAM   = 3'd1;
localparam [2:0] ST_START_REQUANT = 3'd2;
localparam [2:0] ST_WAIT_RESULT   = 3'd3;
localparam [2:0] ST_WRITE_CH0     = 3'd4;
localparam [2:0] ST_WRITE_CH1     = 3'd5;
localparam [2:0] ST_DONE          = 3'd6;

reg [2:0] state_q;

reg [3:0] issue_index_q;
reg [3:0] capture_index_q;
reg       issue_done_q;

reg [127:0] acc_ch0_batch_q;
reg [127:0] acc_ch1_batch_q;

reg requant_start_q;

// One bit per configured BRAM output-latency stage.
// Example BRAM_READ_LATENCY=1:
//   issue_read_w -> read_valid_pipe_q[0] -> capture on next clock
reg [BRAM_READ_LATENCY-1:0] read_valid_pipe_q;

integer valid_stage;

wire issue_read_w;
wire capture_valid_w;

assign issue_read_w =
    (state_q == ST_READ_STREAM) &&
    !issue_done_q;

assign capture_valid_w =
    read_valid_pipe_q[BRAM_READ_LATENCY-1];

wire requant_busy_w;
wire requant_done_w;
wire requant_result_valid_w;

wire [31:0] q_ch0_batch_w;
wire [31:0] q_ch1_batch_w;

wire [7:0] saturation_count_w;

assign busy_o =
    (state_q != ST_IDLE) &&
    (state_q != ST_DONE);

requantize_batch2x4_parallel4 u_requant_batch (
    .clk(clk),
    .resetn(resetn),

    .start_i(requant_start_q),

    .acc_ch0_batch_i(acc_ch0_batch_q),
    .acc_ch1_batch_i(acc_ch1_batch_q),

    .bias_ch0_i(bias_ch0_i),
    .bias_ch1_i(bias_ch1_i),

    .mult_ch0_i(mult_ch0_i),
    .mult_ch1_i(mult_ch1_i),

    .shift_ch0_i(shift_ch0_i),
    .shift_ch1_i(shift_ch1_i),

    .zp_ch0_i(zp_ch0_i),
    .zp_ch1_i(zp_ch1_i),

    .busy_o(requant_busy_w),
    .done_o(requant_done_w),
    .result_valid_o(requant_result_valid_w),

    .q_ch0_batch_o(q_ch0_batch_w),
    .q_ch1_batch_o(q_ch1_batch_w),

    .saturation_count_o(saturation_count_w)
);

// ------------------------------------------------------------
// BRAM interface.
// ------------------------------------------------------------
always @(*) begin
    bram_en_o    = 1'b0;
    bram_we_o    = 4'b0000;
    bram_addr_o  = 12'h000;
    bram_wdata_o = 32'h0000_0000;

    case (state_q)
        ST_READ_STREAM: begin
            if (!issue_done_q) begin
                bram_en_o = 1'b1;
                bram_we_o = 4'b0000;

                bram_addr_o =
                    input_base_i +
                    {issue_index_q, 2'b00};
            end
        end

        ST_WRITE_CH0: begin
            bram_en_o    = 1'b1;
            bram_we_o    = 4'b1111;
            bram_addr_o  = output_base_i;
            bram_wdata_o = q_ch0_batch_w;
        end

        ST_WRITE_CH1: begin
            bram_en_o    = 1'b1;
            bram_we_o    = 4'b1111;
            bram_addr_o  = output_base_i + 12'd4;
            bram_wdata_o = q_ch1_batch_w;
        end

        default: begin
        end
    endcase
end

// ------------------------------------------------------------
// Read-valid pipeline.
//
// This tracks when a previously-issued synchronous BRAM read becomes
// safe to capture into the job-engine batch registers.
// ------------------------------------------------------------
always @(posedge clk) begin
    if (!resetn) begin
        read_valid_pipe_q <=
            {BRAM_READ_LATENCY{1'b0}};
    end else begin
        read_valid_pipe_q[0] <=
            issue_read_w;

        for (
            valid_stage = 1;
            valid_stage < BRAM_READ_LATENCY;
            valid_stage = valid_stage + 1
        ) begin
            read_valid_pipe_q[valid_stage] <=
                read_valid_pipe_q[valid_stage - 1];
        end
    end
end

// ------------------------------------------------------------
// Main state machine.
// ------------------------------------------------------------
always @(posedge clk) begin
    if (!resetn) begin
        state_q <= ST_IDLE;

        issue_index_q <= 4'd0;
        capture_index_q <= 4'd0;
        issue_done_q <= 1'b0;

        acc_ch0_batch_q <= 128'd0;
        acc_ch1_batch_q <= 128'd0;

        requant_start_q <= 1'b0;

        done_o <= 1'b0;
        error_o <= 1'b0;

        read_word_count_o <= 16'd0;
        write_word_count_o <= 16'd0;
    end else begin
        requant_start_q <= 1'b0;
        done_o <= 1'b0;

        case (state_q)
            ST_IDLE: begin
                if (start_i) begin
                    if (length_words_i != 16'd8) begin
                        error_o <= 1'b1;
                        done_o <= 1'b1;
                    end else begin
                        error_o <= 1'b0;

                        issue_index_q <= 4'd0;
                        capture_index_q <= 4'd0;
                        issue_done_q <= 1'b0;

                        acc_ch0_batch_q <= 128'd0;
                        acc_ch1_batch_q <= 128'd0;

                        read_word_count_o <= 16'd0;
                        write_word_count_o <= 16'd0;

                        state_q <= ST_READ_STREAM;
                    end
                end
            end

            ST_READ_STREAM: begin
                // One new address is presented every clock until word 7.
                if (issue_read_w) begin
                    if (issue_index_q == 4'd7) begin
                        issue_done_q <= 1'b1;
                    end else begin
                        issue_index_q <=
                            issue_index_q + 4'd1;
                    end
                end

                // After the initial latency, one word is captured per clock.
                if (capture_valid_w) begin
                    read_word_count_o <=
                        read_word_count_o + 16'd1;

                    case (capture_index_q)
                        4'd0: acc_ch0_batch_q[31:0]   <= bram_rdata_i;
                        4'd1: acc_ch0_batch_q[63:32]  <= bram_rdata_i;
                        4'd2: acc_ch0_batch_q[95:64]  <= bram_rdata_i;
                        4'd3: acc_ch0_batch_q[127:96] <= bram_rdata_i;

                        4'd4: acc_ch1_batch_q[31:0]   <= bram_rdata_i;
                        4'd5: acc_ch1_batch_q[63:32]  <= bram_rdata_i;
                        4'd6: acc_ch1_batch_q[95:64]  <= bram_rdata_i;

                        default:
                            acc_ch1_batch_q[127:96] <= bram_rdata_i;
                    endcase

                    if (capture_index_q == 4'd7) begin
                        state_q <= ST_START_REQUANT;
                    end else begin
                        capture_index_q <=
                            capture_index_q + 4'd1;
                    end
                end
            end

            ST_START_REQUANT: begin
                if (!requant_busy_w) begin
                    requant_start_q <= 1'b1;
                    state_q <= ST_WAIT_RESULT;
                end
            end

            ST_WAIT_RESULT: begin
                if (requant_result_valid_w) begin
                    state_q <= ST_WRITE_CH0;
                end
            end

            ST_WRITE_CH0: begin
                write_word_count_o <=
                    write_word_count_o + 16'd1;

                state_q <= ST_WRITE_CH1;
            end

            ST_WRITE_CH1: begin
                write_word_count_o <=
                    write_word_count_o + 16'd1;

                state_q <= ST_DONE;
            end

            ST_DONE: begin
                done_o <= 1'b1;
                state_q <= ST_IDLE;
            end

            default: begin
                error_o <= 1'b1;
                state_q <= ST_IDLE;
            end
        endcase
    end
end

endmodule
