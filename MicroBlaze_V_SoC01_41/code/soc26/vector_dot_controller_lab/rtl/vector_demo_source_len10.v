module vector_demo_source_len10 (
    input  wire        clk,
    input  wire        resetn,

    output reg         start_o,
    output wire [15:0] vector_length_o,

    output reg         vec_valid_o,
    input  wire        vec_ready_i,
    output reg  [31:0] a_vec_o,
    output reg  [31:0] b_vec_o,

    input  wire        done_i
);

// One-shot demonstration:
// vector length = 10 scalar elements
// group count   = ceil(10 / 4) = 3
//
// The final group intentionally places non-zero garbage in lanes 2/3.
// The controller must zero-mask those two tail lanes.

localparam [2:0] S_START = 3'd0;
localparam [2:0] S_WAIT  = 3'd1;
localparam [2:0] S_SEND0 = 3'd2;
localparam [2:0] S_SEND1 = 3'd3;
localparam [2:0] S_SEND2 = 3'd4;
localparam [2:0] S_DONE  = 3'd5;

reg [2:0] state_q;

assign vector_length_o = 16'd10;

always @(*) begin
    start_o     = 1'b0;
    vec_valid_o = 1'b0;
    a_vec_o     = 32'h0000_0000;
    b_vec_o     = 32'h0000_0000;

    case (state_q)
        S_START: begin
            start_o = 1'b1;
        end

        S_SEND0: begin
            vec_valid_o = 1'b1;

            // Lane order in each 32-bit word:
            // {lane3, lane2, lane1, lane0}
            a_vec_o = {
                8'd4,
                8'd3,
                8'd2,
                8'd1
            };

            b_vec_o = {
                8'd1,
                8'd1,
                8'd1,
                8'd1
            };
        end

        S_SEND1: begin
            vec_valid_o = 1'b1;

            a_vec_o = {
                8'd8,
                8'd7,
                8'd6,
                8'd5
            };

            b_vec_o = {
                8'd1,
                8'd1,
                8'd1,
                8'd1
            };
        end

        S_SEND2: begin
            vec_valid_o = 1'b1;

            // Only lane0/lane1 belong to vector length 10.
            // lane2/lane3 are intentional garbage.
            a_vec_o = {
                8'h7F,
                8'h7F,
                8'd10,
                8'd9
            };

            b_vec_o = {
                8'h7F,
                8'h7F,
                8'd1,
                8'd1
            };
        end

        default: begin
        end
    endcase
end

always @(posedge clk) begin
    if (!resetn) begin
        state_q <= S_START;
    end else begin
        case (state_q)
            S_START: begin
                state_q <= S_WAIT;
            end

            S_WAIT: begin
                if (vec_ready_i) begin
                    state_q <= S_SEND0;
                end
            end

            S_SEND0: begin
                if (vec_ready_i) begin
                    state_q <= S_SEND1;
                end
            end

            S_SEND1: begin
                if (vec_ready_i) begin
                    state_q <= S_SEND2;
                end
            end

            S_SEND2: begin
                if (vec_ready_i) begin
                    state_q <= S_DONE;
                end
            end

            S_DONE: begin
                // Hold until controller reports completion.
                if (done_i) begin
                    state_q <= S_DONE;
                end
            end

            default: begin
                state_q <= S_START;
            end
        endcase
    end
end

endmodule
