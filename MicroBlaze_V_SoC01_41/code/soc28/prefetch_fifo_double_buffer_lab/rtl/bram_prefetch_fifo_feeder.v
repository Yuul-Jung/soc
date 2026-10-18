module bram_prefetch_fifo_feeder #(
    parameter integer ADDR_WIDTH = 8
) (
    input  wire                      clk,
    input  wire                      resetn,

    input  wire                      start_i,
    input  wire [15:0]               vector_length_i,

    input  wire                      downstream_ready_i,

    output wire                      act_rd_en_o,
    output wire [ADDR_WIDTH-1:0]     act_rd_addr_o,
    input  wire [31:0]               act_rd_data_i,
    input  wire                      act_rd_valid_i,

    output wire                      weight_rd_en_o,
    output wire [ADDR_WIDTH-1:0]     weight_rd_addr_o,
    input  wire [31:0]               weight_rd_data_i,
    input  wire                      weight_rd_valid_i,

    output wire                      vec_valid_o,
    output wire [31:0]               a_vec_o,
    output wire [31:0]               b_vec_o,

    output reg  [15:0]               requested_groups_o,
    output reg  [15:0]               received_groups_o,
    output reg  [15:0]               delivered_groups_o,

    output wire [2:0]                fifo_count_o,
    output reg  [2:0]                outstanding_reads_o,

    output reg                       response_mismatch_error_o,
    output reg                       fifo_overflow_error_o,
    output wire                      active_o
);

// Prefetch policy:
//
// buffered credits = FIFO entries + outstanding BRAM reads.
//
// A new BRAM read request is issued only if:
//   1. operation is active
//   2. more groups remain
//   3. FIFO + outstanding < FIFO depth
//
// This prevents a response from arriving after the FIFO has run out
// of capacity, even when the consumer deasserts READY.
//
// The implementation is intentionally conservative:
// it does not count a same-cycle FIFO pop as immediate new credit.
// This can delay a new read request by one cycle at the full boundary,
// but keeps the control logic simple and safe.

wire [16:0] length_plus3_w;
wire [15:0] total_groups_w;

assign length_plus3_w =
    {1'b0, vector_length_i} + 17'd3;

assign total_groups_w =
    length_plus3_w[16:2];

reg [15:0] total_groups_q;
reg        active_q;

assign active_o = active_q;

wire [3:0] buffered_credits_w;

assign buffered_credits_w =
    {1'b0, fifo_count_o} +
    {1'b0, outstanding_reads_o};

wire can_issue_w;

assign can_issue_w =
    active_q &&
    (requested_groups_o < total_groups_q) &&
    (buffered_credits_w < 4'd4);

assign act_rd_en_o =
    can_issue_w;

assign weight_rd_en_o =
    can_issue_w;

assign act_rd_addr_o =
    requested_groups_o[ADDR_WIDTH-1:0];

assign weight_rd_addr_o =
    requested_groups_o[ADDR_WIDTH-1:0];

wire paired_response_valid_w;

assign paired_response_valid_w =
    act_rd_valid_i &&
    weight_rd_valid_i;

wire [63:0] fifo_push_data_w;

assign fifo_push_data_w = {
    weight_rd_data_i,
    act_rd_data_i
};

wire fifo_push_ready_w;
wire fifo_pop_valid_w;
wire [63:0] fifo_pop_data_w;

stream_fifo_64x4 u_prefetch_fifo (
    .clk(clk),
    .resetn(resetn),
    .clear_i(start_i),

    .push_valid_i(paired_response_valid_w),
    .push_ready_o(fifo_push_ready_w),
    .push_data_i(fifo_push_data_w),

    .pop_valid_o(fifo_pop_valid_w),
    .pop_ready_i(downstream_ready_i),
    .pop_data_o(fifo_pop_data_w),

    .count_o(fifo_count_o)
);

assign vec_valid_o =
    fifo_pop_valid_w;

assign a_vec_o =
    fifo_pop_data_w[31:0];

assign b_vec_o =
    fifo_pop_data_w[63:32];

wire fifo_pop_w;

assign fifo_pop_w =
    fifo_pop_valid_w &&
    downstream_ready_i;

always @(posedge clk) begin
    if (!resetn) begin
        total_groups_q            <= 16'd0;
        active_q                  <= 1'b0;

        requested_groups_o        <= 16'd0;
        received_groups_o         <= 16'd0;
        delivered_groups_o        <= 16'd0;

        outstanding_reads_o       <= 3'd0;

        response_mismatch_error_o <= 1'b0;
        fifo_overflow_error_o     <= 1'b0;
    end else begin
        if (start_i) begin
            total_groups_q            <= total_groups_w;
            active_q                  <=
                (vector_length_i != 16'd0);

            requested_groups_o        <= 16'd0;
            received_groups_o         <= 16'd0;
            delivered_groups_o        <= 16'd0;
            outstanding_reads_o       <= 3'd0;

            response_mismatch_error_o <= 1'b0;
            fifo_overflow_error_o     <= 1'b0;
        end else begin
            if (
                act_rd_valid_i ^
                weight_rd_valid_i
            ) begin
                response_mismatch_error_o <= 1'b1;
            end

            if (
                paired_response_valid_w &&
                !fifo_push_ready_w
            ) begin
                fifo_overflow_error_o <= 1'b1;
            end

            if (can_issue_w) begin
                requested_groups_o <=
                    requested_groups_o + 16'd1;
            end

            if (paired_response_valid_w) begin
                received_groups_o <=
                    received_groups_o + 16'd1;
            end

            if (fifo_pop_w) begin
                delivered_groups_o <=
                    delivered_groups_o + 16'd1;

                if (
                    delivered_groups_o ==
                    (total_groups_q - 16'd1)
                ) begin
                    active_q <= 1'b0;
                end
            end

            case ({
                can_issue_w,
                paired_response_valid_w
            })
                2'b10:
                    outstanding_reads_o <=
                        outstanding_reads_o + 3'd1;

                2'b01:
                    outstanding_reads_o <=
                        outstanding_reads_o - 3'd1;

                default:
                    outstanding_reads_o <=
                        outstanding_reads_o;
            endcase
        end
    end
end

endmodule
