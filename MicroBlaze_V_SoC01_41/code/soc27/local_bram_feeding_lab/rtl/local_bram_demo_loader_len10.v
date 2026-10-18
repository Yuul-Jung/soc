module local_bram_demo_loader_len10 (
    input  wire        clk,
    input  wire        resetn,

    output reg         act_wr_en_o,
    output reg  [7:0]  act_wr_addr_o,
    output reg  [31:0] act_wr_data_o,

    output reg         weight_wr_en_o,
    output reg  [7:0]  weight_wr_addr_o,
    output reg  [31:0] weight_wr_data_o,

    output reg         start_o,
    output wire [15:0] vector_length_o,

    input  wire        done_i
);

// Demo vector:
// A = [1,2,3,4,5,6,7,8,9,10]
// B = [1,1,1,1,1,1,1,1,1,1]
//
// Word 2 contains deliberate garbage in lane2/lane3.
// SoC26 tail masking must remove it.
//
// Expected raw result = 55 = 0x0037.

localparam [2:0] S_WRITE0 = 3'd0;
localparam [2:0] S_WRITE1 = 3'd1;
localparam [2:0] S_WRITE2 = 3'd2;
localparam [2:0] S_START  = 3'd3;
localparam [2:0] S_WAIT   = 3'd4;
localparam [2:0] S_DONE   = 3'd5;

reg [2:0] state_q;

assign vector_length_o = 16'd10;

always @(*) begin
    act_wr_en_o      = 1'b0;
    act_wr_addr_o    = 8'd0;
    act_wr_data_o    = 32'h0000_0000;

    weight_wr_en_o   = 1'b0;
    weight_wr_addr_o = 8'd0;
    weight_wr_data_o = 32'h0000_0000;

    start_o          = 1'b0;

    case (state_q)
        S_WRITE0: begin
            act_wr_en_o      = 1'b1;
            act_wr_addr_o    = 8'd0;
            act_wr_data_o    = {8'd4, 8'd3, 8'd2, 8'd1};

            weight_wr_en_o   = 1'b1;
            weight_wr_addr_o = 8'd0;
            weight_wr_data_o = {8'd1, 8'd1, 8'd1, 8'd1};
        end

        S_WRITE1: begin
            act_wr_en_o      = 1'b1;
            act_wr_addr_o    = 8'd1;
            act_wr_data_o    = {8'd8, 8'd7, 8'd6, 8'd5};

            weight_wr_en_o   = 1'b1;
            weight_wr_addr_o = 8'd1;
            weight_wr_data_o = {8'd1, 8'd1, 8'd1, 8'd1};
        end

        S_WRITE2: begin
            act_wr_en_o      = 1'b1;
            act_wr_addr_o    = 8'd2;
            act_wr_data_o    = {8'h7F, 8'h7F, 8'd10, 8'd9};

            weight_wr_en_o   = 1'b1;
            weight_wr_addr_o = 8'd2;
            weight_wr_data_o = {8'h7F, 8'h7F, 8'd1, 8'd1};
        end

        S_START: begin
            start_o = 1'b1;
        end

        default: begin
        end
    endcase
end

always @(posedge clk) begin
    if (!resetn) begin
        state_q <= S_WRITE0;
    end else begin
        case (state_q)
            S_WRITE0: state_q <= S_WRITE1;
            S_WRITE1: state_q <= S_WRITE2;
            S_WRITE2: state_q <= S_START;
            S_START:  state_q <= S_WAIT;

            S_WAIT: begin
                if (done_i) begin
                    state_q <= S_DONE;
                end
            end

            S_DONE: begin
                state_q <= S_DONE;
            end

            default: begin
                state_q <= S_WRITE0;
            end
        endcase
    end
end

endmodule
