module tensor_job_engine_overlap #(
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

// SoC 40:
// - keep synchronous BRAM
// - keep one read request per clock
// - split 8 words into two 4-word ping/pong groups
// - launch CH0 compute as soon as word3 is captured
// - continue prefetching CH1 while CH0 computes
// - launch CH1 when word7 is captured
// - write CH0/CH1 results as soon as each result returns

reg job_active_q;
reg finish_pending_q;

reg [3:0] issue_index_q;
reg [3:0] capture_index_q;
reg       issue_done_q;
reg       reads_complete_q;

reg [127:0] ping_group_q;
reg [127:0] pong_group_q;

reg ping_ready_q;
reg pong_ready_q;
reg ping_launched_q;
reg pong_launched_q;

reg ch0_written_q;
reg ch1_written_q;

reg [BRAM_READ_LATENCY-1:0] read_valid_pipe_q;
integer valid_stage;

wire issue_read_w;
wire capture_valid_w;

assign issue_read_w =
    job_active_q &&
    !issue_done_q;

assign capture_valid_w =
    read_valid_pipe_q[BRAM_READ_LATENCY-1];

// ------------------------------------------------------------
// Group launch arbitration.
// Ping = CH0, Pong = CH1.
// ------------------------------------------------------------
wire rq_valid_i_w;
wire rq_tag_i_w;
wire [127:0] rq_acc_group_w;

assign rq_valid_i_w =
    job_active_q &&
    (
        (ping_ready_q && !ping_launched_q) ||
        (pong_ready_q && !pong_launched_q)
    );

assign rq_tag_i_w =
    (ping_ready_q && !ping_launched_q)
    ? 1'b0
    : 1'b1;

assign rq_acc_group_w =
    (rq_tag_i_w == 1'b0)
    ? ping_group_q
    : pong_group_q;

wire signed [31:0] rq_bias_w;
wire signed [15:0] rq_mult_w;
wire        [5:0]  rq_shift_w;
wire signed [15:0] rq_zp_w;

assign rq_bias_w =
    rq_tag_i_w ? bias_ch1_i : bias_ch0_i;

assign rq_mult_w =
    rq_tag_i_w ? mult_ch1_i : mult_ch0_i;

assign rq_shift_w =
    rq_tag_i_w ? shift_ch1_i : shift_ch0_i;

assign rq_zp_w =
    rq_tag_i_w ? zp_ch1_i : zp_ch0_i;

wire        rq_valid_o_w;
wire        rq_tag_o_w;
wire [31:0] rq_q_group_w;
wire [2:0]  rq_sat_count_w;

requantize_group4_parallel u_group4 (
    .clk(clk),
    .resetn(resetn),

    .valid_i(rq_valid_i_w),
    .tag_i(rq_tag_i_w),

    .acc_group_i(rq_acc_group_w),

    .bias_i(rq_bias_w),
    .multiplier_i(rq_mult_w),
    .shift_i(rq_shift_w),
    .zero_point_i(rq_zp_w),

    .valid_o(rq_valid_o_w),
    .tag_o(rq_tag_o_w),
    .q_group_o(rq_q_group_w),
    .saturation_count_o(rq_sat_count_w)
);

// Once all reads finish, a returned group can be written immediately.
wire result_write_w;

assign result_write_w =
    job_active_q &&
    reads_complete_q &&
    rq_valid_o_w;

// ------------------------------------------------------------
// Shared native BRAM port.
//
// Priority after reads complete:
// returned requant result write.
//
// While reads are active, only read requests use the port.
// ------------------------------------------------------------
always @(*) begin
    bram_en_o    = 1'b0;
    bram_we_o    = 4'b0000;
    bram_addr_o  = 12'h000;
    bram_wdata_o = 32'h0000_0000;

    if (result_write_w) begin
        bram_en_o    = 1'b1;
        bram_we_o    = 4'b1111;
        bram_addr_o  =
            rq_tag_o_w
            ? (output_base_i + 12'd4)
            : output_base_i;
        bram_wdata_o = rq_q_group_w;
    end else if (issue_read_w) begin
        bram_en_o    = 1'b1;
        bram_we_o    = 4'b0000;
        bram_addr_o  =
            input_base_i +
            {issue_index_q, 2'b00};
    end
end

// ------------------------------------------------------------
// Read-valid pipeline.
// ------------------------------------------------------------
always @(posedge clk) begin
    if (!resetn) begin
        read_valid_pipe_q <=
            {BRAM_READ_LATENCY{1'b0}};
    end else if (!job_active_q) begin
        read_valid_pipe_q <=
            {BRAM_READ_LATENCY{1'b0}};
    end else begin
        read_valid_pipe_q[0] <= issue_read_w;

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

assign busy_o = job_active_q;

// ------------------------------------------------------------
// Job / prefetch / compute / write control.
// ------------------------------------------------------------
always @(posedge clk) begin
    if (!resetn) begin
        job_active_q <= 1'b0;
        finish_pending_q <= 1'b0;

        issue_index_q <= 4'd0;
        capture_index_q <= 4'd0;
        issue_done_q <= 1'b0;
        reads_complete_q <= 1'b0;

        ping_group_q <= 128'd0;
        pong_group_q <= 128'd0;

        ping_ready_q <= 1'b0;
        pong_ready_q <= 1'b0;
        ping_launched_q <= 1'b0;
        pong_launched_q <= 1'b0;

        ch0_written_q <= 1'b0;
        ch1_written_q <= 1'b0;

        done_o <= 1'b0;
        error_o <= 1'b0;

        read_word_count_o <= 16'd0;
        write_word_count_o <= 16'd0;
    end else begin
        done_o <= 1'b0;

        if (finish_pending_q) begin
            done_o <= 1'b1;
            job_active_q <= 1'b0;
            finish_pending_q <= 1'b0;
        end

        if (!job_active_q) begin
            if (start_i) begin
                if (length_words_i != 16'd8) begin
                    error_o <= 1'b1;
                    done_o <= 1'b1;
                end else begin
                    job_active_q <= 1'b1;
                    error_o <= 1'b0;

                    issue_index_q <= 4'd0;
                    capture_index_q <= 4'd0;
                    issue_done_q <= 1'b0;
                    reads_complete_q <= 1'b0;

                    ping_group_q <= 128'd0;
                    pong_group_q <= 128'd0;

                    ping_ready_q <= 1'b0;
                    pong_ready_q <= 1'b0;
                    ping_launched_q <= 1'b0;
                    pong_launched_q <= 1'b0;

                    ch0_written_q <= 1'b0;
                    ch1_written_q <= 1'b0;

                    read_word_count_o <= 16'd0;
                    write_word_count_o <= 16'd0;
                end
            end
        end else begin
            // One read request per clock until address 7.
            if (issue_read_w) begin
                if (issue_index_q == 4'd7) begin
                    issue_done_q <= 1'b1;
                end else begin
                    issue_index_q <=
                        issue_index_q + 4'd1;
                end
            end

            // Capture synchronous BRAM return stream.
            if (capture_valid_w) begin
                read_word_count_o <=
                    read_word_count_o + 16'd1;

                case (capture_index_q)
                    4'd0: ping_group_q[31:0]   <= bram_rdata_i;
                    4'd1: ping_group_q[63:32]  <= bram_rdata_i;
                    4'd2: ping_group_q[95:64]  <= bram_rdata_i;
                    4'd3: begin
                        ping_group_q[127:96] <= bram_rdata_i;
                        ping_ready_q <= 1'b1;
                    end

                    4'd4: pong_group_q[31:0]   <= bram_rdata_i;
                    4'd5: pong_group_q[63:32]  <= bram_rdata_i;
                    4'd6: pong_group_q[95:64]  <= bram_rdata_i;

                    default: begin
                        pong_group_q[127:96] <= bram_rdata_i;
                        pong_ready_q <= 1'b1;
                        reads_complete_q <= 1'b1;
                    end
                endcase

                if (capture_index_q != 4'd7) begin
                    capture_index_q <=
                        capture_index_q + 4'd1;
                end
            end

            // A ready group enters the four-lane pipeline.
            if (rq_valid_i_w) begin
                if (!rq_tag_i_w) begin
                    ping_launched_q <= 1'b1;
                end else begin
                    pong_launched_q <= 1'b1;
                end
            end

            // Returned result is written through the shared BRAM port.
            if (result_write_w) begin
                write_word_count_o <=
                    write_word_count_o + 16'd1;

                if (!rq_tag_o_w) begin
                    ch0_written_q <= 1'b1;
                end else begin
                    ch1_written_q <= 1'b1;

                    // CH1 is the second/last group.
                    // CH0 must already have returned in program order.
                    finish_pending_q <= 1'b1;
                end
            end
        end
    end
end

endmodule
