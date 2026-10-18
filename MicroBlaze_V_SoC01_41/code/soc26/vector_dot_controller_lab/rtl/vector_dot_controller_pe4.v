module vector_dot_controller_pe4 (
    input  wire               clk,
    input  wire               resetn,

    input  wire               start_i,
    input  wire [15:0]        vector_length_i,

    input  wire               vec_valid_i,
    output wire               vec_ready_o,
    input  wire [31:0]        a_vec_i,
    input  wire [31:0]        b_vec_i,

    output wire               busy_o,
    output reg                done_o,
    output reg                result_valid_o,
    output reg signed [31:0]  result_o,

    output reg  [15:0]        accepted_groups_o,
    output reg  [15:0]        completed_groups_o
);

// Controller policy:
// - 4 signed 8-bit lanes per accepted input group
// - vector_length_i is the number of scalar elements, not the number of groups
// - ceil(vector_length / 4) groups are consumed
// - unused tail lanes are forced to zero
// - the PE pipeline latency is NOT hard-coded
// - completion is counted from pe_valid_o
//
// State flow:
// IDLE -> CLEAR -> FEED -> DRAIN -> FINALIZE -> IDLE

localparam [2:0] ST_IDLE     = 3'd0;
localparam [2:0] ST_CLEAR    = 3'd1;
localparam [2:0] ST_FEED     = 3'd2;
localparam [2:0] ST_DRAIN    = 3'd3;
localparam [2:0] ST_FINALIZE = 3'd4;

reg [2:0] state_q;

reg [15:0] total_groups_q;
reg [2:0]  tail_lanes_q;

wire [16:0] length_plus3_w;
wire [15:0] groups_from_length_w;

assign length_plus3_w =
    {1'b0, vector_length_i} + 17'd3;

assign groups_from_length_w =
    length_plus3_w[16:2];

// Remainder 0 means the final group uses all four lanes.
wire [2:0] tail_from_length_w;

assign tail_from_length_w =
    (vector_length_i[1:0] == 2'd0)
    ? 3'd4
    : {1'b0, vector_length_i[1:0]};

assign busy_o =
    (state_q != ST_IDLE);

assign vec_ready_o =
    (state_q == ST_FEED);

// The current FEED transfer is the final input group when the accepted
// group counter points to total_groups_q - 1.
wire current_group_is_last_w;

assign current_group_is_last_w =
    (state_q == ST_FEED) &&
    (total_groups_q != 16'd0) &&
    (accepted_groups_o == (total_groups_q - 16'd1));

function [31:0] mask_tail_lanes;
    input [31:0] vec;
    input [2:0]  valid_lanes;

    begin
        case (valid_lanes)
            3'd1: mask_tail_lanes = {
                24'h000000,
                vec[7:0]
            };

            3'd2: mask_tail_lanes = {
                16'h0000,
                vec[15:0]
            };

            3'd3: mask_tail_lanes = {
                8'h00,
                vec[23:0]
            };

            default: mask_tail_lanes = vec;
        endcase
    end
endfunction

wire [31:0] masked_a_vec_w;
wire [31:0] masked_b_vec_w;

assign masked_a_vec_w =
    current_group_is_last_w
    ? mask_tail_lanes(a_vec_i, tail_lanes_q)
    : a_vec_i;

assign masked_b_vec_w =
    current_group_is_last_w
    ? mask_tail_lanes(b_vec_i, tail_lanes_q)
    : b_vec_i;

wire pe_valid_i;
wire pe_clear_i;

assign pe_valid_i =
    vec_valid_i &&
    vec_ready_o;

assign pe_clear_i =
    (state_q == ST_CLEAR);

wire signed [31:0] pe_acc_w;
wire               pe_valid_o;

pe4_dot_accum_pipelined u_pe4 (
    .clk(clk),
    .resetn(resetn),
    .clear_i(pe_clear_i),
    .valid_i(pe_valid_i),

    .a_vec_i(masked_a_vec_w),
    .b_vec_i(masked_b_vec_w),

    .acc_o(pe_acc_w),
    .valid_o(pe_valid_o)
);

always @(posedge clk) begin
    if (!resetn) begin
        state_q             <= ST_IDLE;
        total_groups_q      <= 16'd0;
        tail_lanes_q        <= 3'd4;

        done_o              <= 1'b0;
        result_valid_o      <= 1'b0;
        result_o            <= 32'sd0;

        accepted_groups_o   <= 16'd0;
        completed_groups_o  <= 16'd0;
    end else begin
        // One-cycle output pulses by default.
        done_o         <= 1'b0;
        result_valid_o <= 1'b0;

        // Count actual PE completions independently of input feeding.
        if (
            pe_valid_o &&
            ((state_q == ST_FEED) || (state_q == ST_DRAIN))
        ) begin
            completed_groups_o <=
                completed_groups_o + 16'd1;
        end

        case (state_q)
            ST_IDLE: begin
                if (start_i) begin
                    result_o           <= 32'sd0;
                    accepted_groups_o  <= 16'd0;
                    completed_groups_o <= 16'd0;

                    if (vector_length_i == 16'd0) begin
                        // Defined zero-length behavior:
                        // result = 0, immediate one-cycle completion pulse.
                        total_groups_q <= 16'd0;
                        tail_lanes_q   <= 3'd4;

                        result_o       <= 32'sd0;
                        done_o         <= 1'b1;
                        result_valid_o <= 1'b1;
                    end else begin
                        total_groups_q <= groups_from_length_w;
                        tail_lanes_q   <= tail_from_length_w;

                        state_q <= ST_CLEAR;
                    end
                end
            end

            ST_CLEAR: begin
                // pe_clear_i is asserted for this full clock state.
                // Move to FEED only after the PE has observed the clear.
                state_q <= ST_FEED;
            end

            ST_FEED: begin
                if (pe_valid_i) begin
                    accepted_groups_o <=
                        accepted_groups_o + 16'd1;

                    if (current_group_is_last_w) begin
                        state_q <= ST_DRAIN;
                    end
                end
            end

            ST_DRAIN: begin
                // Count the final registered PE completion first.
                // FINALIZE isolates the final result capture and done pulse
                // from the pipeline-drain bookkeeping, without hard-coding
                // the PE latency.
                if (
                    pe_valid_o &&
                    (completed_groups_o == (total_groups_q - 16'd1))
                ) begin
                    state_q <= ST_FINALIZE;
                end
            end

            ST_FINALIZE: begin
                result_o       <= pe_acc_w;
                done_o         <= 1'b1;
                result_valid_o <= 1'b1;

                state_q <= ST_IDLE;
            end

            default: begin
                state_q <= ST_IDLE;
            end
        endcase
    end
end

endmodule
