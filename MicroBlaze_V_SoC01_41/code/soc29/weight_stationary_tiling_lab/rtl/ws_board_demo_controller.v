module ws_board_demo_controller (
    input  wire        clk,
    input  wire        resetn,

    output reg         job_start_o,

    output reg         tile_start_o,
    input  wire        tile_ready_i,
    output reg         tile_last_o,

    output reg  [31:0] weight_ch0_vec_o,
    output reg  [31:0] weight_ch1_vec_o,

    output reg         act_valid_o,
    input  wire        act_ready_i,
    output reg  [1:0]  act_sample_id_o,
    output reg  [31:0] act_vec_o,

    input  wire        tile_done_i,
    input  wire        job_done_i,
    input  wire        result_valid_i,

    output reg         demo_done_o
);

// Fixed board demonstration:
//
// B = 4, M = 2, K = 16, TILE_K = 4.
//
// CH0 weights = all 1.
// CH1 weights = all 2.
//
// Sample 0 activations = all 1.
// Sample 1 activations = all 2.
// Sample 2 activations = all 3.
// Sample 3 activations = all 4.
//
// Expected:
//   CH0 = [16, 32, 48, 64]
//   CH1 = [32, 64, 96, 128]
//
// Selected LED result later:
//   CH1 sample3 = 128 = 0x0080.

localparam [3:0] ST_JOB_START  = 4'd0;
localparam [3:0] ST_WAIT_TILE  = 4'd1;
localparam [3:0] ST_TILE_START = 4'd2;
localparam [3:0] ST_FEED       = 4'd3;
localparam [3:0] ST_WAIT_DONE  = 4'd4;
localparam [3:0] ST_FINAL      = 4'd5;

reg [3:0] state_q;
reg [2:0] tile_index_q;
reg [2:0] sample_index_q;

wire [7:0] sample_value_w;

assign sample_value_w =
    {5'd0, sample_index_q} + 8'd1;

function [31:0] repeat_byte4;
    input [7:0] value;

    begin
        repeat_byte4 = {
            value,
            value,
            value,
            value
        };
    end
endfunction

always @(*) begin
    job_start_o = 1'b0;

    tile_start_o = 1'b0;
    tile_last_o = 1'b0;

    weight_ch0_vec_o = repeat_byte4(8'd1);
    weight_ch1_vec_o = repeat_byte4(8'd2);

    act_valid_o = 1'b0;
    act_sample_id_o = sample_index_q[1:0];
    act_vec_o = repeat_byte4(sample_value_w);

    demo_done_o = 1'b0;

    case (state_q)
        ST_JOB_START: begin
            job_start_o = 1'b1;
        end

        ST_TILE_START: begin
            tile_start_o = 1'b1;
            tile_last_o = (tile_index_q == 3);
        end

        ST_FEED: begin
            act_valid_o = 1'b1;
        end

        ST_FINAL: begin
            demo_done_o = 1'b1;
        end

        default: begin
        end
    endcase
end

always @(posedge clk) begin
    if (!resetn) begin
        state_q <= ST_JOB_START;
        tile_index_q <= 3'd0;
        sample_index_q <= 3'd0;
    end else begin
        case (state_q)
            ST_JOB_START: begin
                state_q <= ST_WAIT_TILE;
            end

            ST_WAIT_TILE: begin
                if (tile_ready_i) begin
                    state_q <= ST_TILE_START;
                end
            end

            ST_TILE_START: begin
                sample_index_q <= 3'd0;
                state_q <= ST_FEED;
            end

            ST_FEED: begin
                if (act_ready_i) begin
                    if (sample_index_q == 3) begin
                        state_q <= ST_WAIT_DONE;
                    end else begin
                        sample_index_q <=
                            sample_index_q + 3'd1;
                    end
                end
            end

            ST_WAIT_DONE: begin
                if (tile_done_i) begin
                    if (tile_index_q == 3) begin
                        state_q <= ST_FINAL;
                    end else begin
                        tile_index_q <=
                            tile_index_q + 3'd1;

                        state_q <= ST_WAIT_TILE;
                    end
                end
            end

            ST_FINAL: begin
                state_q <= ST_FINAL;
            end

            default: begin
                state_q <= ST_JOB_START;
            end
        endcase
    end
end

endmodule
