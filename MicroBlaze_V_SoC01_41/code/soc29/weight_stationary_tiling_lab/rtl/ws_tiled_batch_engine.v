module ws_tiled_batch_engine (
    input  wire                clk,
    input  wire                resetn,

    input  wire                job_start_i,

    input  wire                tile_start_i,
    output wire                tile_ready_o,
    input  wire                tile_last_i,

    input  wire [31:0]         weight_ch0_vec_i,
    input  wire [31:0]         weight_ch1_vec_i,

    input  wire                act_valid_i,
    output wire                act_ready_o,
    input  wire [1:0]          act_sample_id_i,
    input  wire [31:0]         act_vec_i,

    output reg                 tile_done_o,
    output reg                 job_done_o,
    output reg                 result_valid_o,

    output reg [127:0]         result_ch0_batch_o,
    output reg [127:0]         result_ch1_batch_o,

    output reg [15:0]          weight_tile_loads_o,
    output reg [15:0]          activation_groups_o,
    output reg [15:0]          dot_results_o
);

// Mini tiled GEMM engine.
//
// Fixed teaching shape:
//   Batch B = 4
//   Output channels M = 2
//   K tile size = 4
//
// Each tile:
//   1. Load two 4-weight vectors once.
//   2. Feed four activation vectors, one per batch sample.
//   3. The same activation group is broadcast to both PE rows.
//   4. Accumulate two dot4 partial sums into per-sample psums.
//
// Across multiple K tiles, psums persist.
//
// Final packed result:
//   result_chX_batch_o[31:0]   = sample 0
//   result_chX_batch_o[63:32]  = sample 1
//   result_chX_batch_o[95:64]  = sample 2
//   result_chX_batch_o[127:96] = sample 3

localparam [2:0] ST_IDLE      = 3'd0;
localparam [2:0] ST_WAIT_TILE = 3'd1;
localparam [2:0] ST_FEED      = 3'd2;
localparam [2:0] ST_DRAIN     = 3'd3;
localparam [2:0] ST_FINALIZE  = 3'd4;

reg [2:0] state_q;

reg       tile_last_q;
reg [2:0] accepted_in_tile_q;
reg [2:0] completed_in_tile_q;

reg signed [31:0] psum0_q [0:3];
reg signed [31:0] psum1_q [0:3];

wire datapath_load_weights_w;

assign datapath_load_weights_w =
    tile_start_i &&
    tile_ready_o;

assign tile_ready_o =
    (state_q == ST_WAIT_TILE);

assign act_ready_o =
    (state_q == ST_FEED);

wire datapath_act_valid_w;

assign datapath_act_valid_w =
    act_valid_i &&
    act_ready_o;

wire              dot_valid_w;
wire [1:0]        dot_sample_id_w;
wire signed [17:0] dot_ch0_w;
wire signed [17:0] dot_ch1_w;
wire              weights_loaded_w;

ws_dual_pe4_datapath u_ws_datapath (
    .clk(clk),
    .resetn(resetn),

    .load_weights_i(datapath_load_weights_w),
    .weight_ch0_vec_i(weight_ch0_vec_i),
    .weight_ch1_vec_i(weight_ch1_vec_i),

    .act_valid_i(datapath_act_valid_w),
    .sample_id_i(act_sample_id_i),
    .act_vec_i(act_vec_i),

    .dot_valid_o(dot_valid_w),
    .sample_id_o(dot_sample_id_w),
    .dot_ch0_o(dot_ch0_w),
    .dot_ch1_o(dot_ch1_w),

    .weights_loaded_o(weights_loaded_w)
);

wire signed [31:0] dot_ch0_ext_w;
wire signed [31:0] dot_ch1_ext_w;

assign dot_ch0_ext_w =
    {{14{dot_ch0_w[17]}}, dot_ch0_w};

assign dot_ch1_ext_w =
    {{14{dot_ch1_w[17]}}, dot_ch1_w};

integer i;

always @(posedge clk) begin
    if (!resetn) begin
        state_q <= ST_IDLE;

        tile_last_q          <= 1'b0;
        accepted_in_tile_q   <= 3'd0;
        completed_in_tile_q  <= 3'd0;

        tile_done_o          <= 1'b0;
        job_done_o           <= 1'b0;
        result_valid_o       <= 1'b0;

        result_ch0_batch_o   <= 128'd0;
        result_ch1_batch_o   <= 128'd0;

        weight_tile_loads_o  <= 16'd0;
        activation_groups_o  <= 16'd0;
        dot_results_o        <= 16'd0;

        for (i = 0; i < 4; i = i + 1) begin
            psum0_q[i] <= 32'sd0;
            psum1_q[i] <= 32'sd0;
        end
    end else begin
        tile_done_o    <= 1'b0;
        job_done_o     <= 1'b0;
        result_valid_o <= 1'b0;

        // Datapath completion is independent of input feed timing.
        if (
            dot_valid_w &&
            (
                (state_q == ST_FEED) ||
                (state_q == ST_DRAIN)
            )
        ) begin
            psum0_q[dot_sample_id_w] <=
                psum0_q[dot_sample_id_w] +
                dot_ch0_ext_w;

            psum1_q[dot_sample_id_w] <=
                psum1_q[dot_sample_id_w] +
                dot_ch1_ext_w;

            dot_results_o <=
                dot_results_o + 16'd2;

            completed_in_tile_q <=
                completed_in_tile_q + 3'd1;
        end

        case (state_q)
            ST_IDLE: begin
                if (job_start_i) begin
                    accepted_in_tile_q  <= 3'd0;
                    completed_in_tile_q <= 3'd0;

                    weight_tile_loads_o <= 16'd0;
                    activation_groups_o <= 16'd0;
                    dot_results_o       <= 16'd0;

                    for (i = 0; i < 4; i = i + 1) begin
                        psum0_q[i] <= 32'sd0;
                        psum1_q[i] <= 32'sd0;
                    end

                    state_q <= ST_WAIT_TILE;
                end
            end

            ST_WAIT_TILE: begin
                if (datapath_load_weights_w) begin
                    tile_last_q         <= tile_last_i;
                    accepted_in_tile_q  <= 3'd0;
                    completed_in_tile_q <= 3'd0;

                    weight_tile_loads_o <=
                        weight_tile_loads_o + 16'd1;

                    state_q <= ST_FEED;
                end
            end

            ST_FEED: begin
                if (datapath_act_valid_w) begin
                    accepted_in_tile_q <=
                        accepted_in_tile_q + 3'd1;

                    activation_groups_o <=
                        activation_groups_o + 16'd1;

                    if (accepted_in_tile_q == 3'd3) begin
                        state_q <= ST_DRAIN;
                    end
                end
            end

            ST_DRAIN: begin
                if (
                    dot_valid_w &&
                    (completed_in_tile_q == 3'd3)
                ) begin
                    tile_done_o <= 1'b1;

                    if (tile_last_q) begin
                        state_q <= ST_FINALIZE;
                    end else begin
                        state_q <= ST_WAIT_TILE;
                    end
                end
            end

            ST_FINALIZE: begin
                result_ch0_batch_o[31:0] <=
                    psum0_q[0];

                result_ch0_batch_o[63:32] <=
                    psum0_q[1];

                result_ch0_batch_o[95:64] <=
                    psum0_q[2];

                result_ch0_batch_o[127:96] <=
                    psum0_q[3];

                result_ch1_batch_o[31:0] <=
                    psum1_q[0];

                result_ch1_batch_o[63:32] <=
                    psum1_q[1];

                result_ch1_batch_o[95:64] <=
                    psum1_q[2];

                result_ch1_batch_o[127:96] <=
                    psum1_q[3];

                result_valid_o <= 1'b1;
                job_done_o     <= 1'b1;

                state_q <= ST_IDLE;
            end

            default: begin
                state_q <= ST_IDLE;
            end
        endcase
    end
end

endmodule
