module soc29_result_demo_source (
    input  wire                 clk,
    input  wire                 resetn,

    output reg                  start_o,

    output wire [127:0]         acc_ch0_batch_o,
    output wire [127:0]         acc_ch1_batch_o,

    output wire signed [31:0]   bias_ch0_o,
    output wire signed [31:0]   bias_ch1_o,

    output wire signed [15:0]   mult_ch0_o,
    output wire signed [15:0]   mult_ch1_o,

    output wire        [5:0]    shift_ch0_o,
    output wire        [5:0]    shift_ch1_o,

    output wire signed [15:0]   zp_ch0_o,
    output wire signed [15:0]   zp_ch1_o,

    input  wire                 done_i
);

// SoC 29 board-demo result replay.
//
// CH0 int32 = [16, 32, 48, 64]
// CH1 int32 = [32, 64, 96, 128]
//
// SoC 30 parameters:
//
// CH0:
//   q = round_away_from_zero(x / 2)
//   -> [8, 16, 24, 32]
//
// CH1:
//   q = round_away_from_zero((x + 4) * 3 / 2) - 3
//   -> [51, 99, 127, 127]
//
// CH1 sample2/sample3 saturate positive.

localparam [1:0] ST_START = 2'd0;
localparam [1:0] ST_WAIT  = 2'd1;
localparam [1:0] ST_DONE  = 2'd2;

reg [1:0] state_q;

assign acc_ch0_batch_o = {
    32'sd64,
    32'sd48,
    32'sd32,
    32'sd16
};

assign acc_ch1_batch_o = {
    32'sd128,
    32'sd96,
    32'sd64,
    32'sd32
};

assign bias_ch0_o = 32'sd0;
assign bias_ch1_o = 32'sd4;

assign mult_ch0_o = 16'sd1;
assign mult_ch1_o = 16'sd3;

assign shift_ch0_o = 6'd1;
assign shift_ch1_o = 6'd1;

assign zp_ch0_o = 16'sd0;
assign zp_ch1_o = -16'sd3;

always @(*) begin
    start_o = 1'b0;

    if (state_q == ST_START) begin
        start_o = 1'b1;
    end
end

always @(posedge clk) begin
    if (!resetn) begin
        state_q <= ST_START;
    end else begin
        case (state_q)
            ST_START: begin
                state_q <= ST_WAIT;
            end

            ST_WAIT: begin
                if (done_i) begin
                    state_q <= ST_DONE;
                end
            end

            ST_DONE: begin
                state_q <= ST_DONE;
            end

            default: begin
                state_q <= ST_START;
            end
        endcase
    end
end

endmodule
