module double_buffer_demo_controller (
    input  wire        clk,
    input  wire        resetn,

    output reg         load_bank_o,
    output reg         load_active_o,

    output reg         act_wr_en_o,
    output reg  [7:0]  act_wr_addr_o,
    output reg  [31:0] act_wr_data_o,

    output reg         weight_wr_en_o,
    output reg  [7:0]  weight_wr_addr_o,
    output reg  [31:0] weight_wr_data_o,

    output reg         compute_bank_o,
    output reg         start_o,
    output wire [15:0] vector_length_o,

    input  wire        busy_i,
    input  wire        done_i,
    input  wire        result_valid_i,
    input  wire signed [31:0] result_i,

    output reg  signed [31:0] first_result_o,
    output reg  signed [31:0] second_result_o,
    output reg         demo_done_o
);

// Ping-pong board demonstration:
//
// Bank 0:
//   A = 1..10
//   B = 1
//   expected result = 55
//
// While Bank 0 computes, load Bank 1:
//
// Bank 1:
//   A = 2,4,6,...,20
//   B = 1
//   expected result = 110
//
// Then compute Bank 1.
//
// Final LED result = 110 = 0x006E.

localparam [3:0] S_LOAD0_0 = 4'd0;
localparam [3:0] S_LOAD0_1 = 4'd1;
localparam [3:0] S_LOAD0_2 = 4'd2;
localparam [3:0] S_START0  = 4'd3;
localparam [3:0] S_LOAD1_0 = 4'd4;
localparam [3:0] S_LOAD1_1 = 4'd5;
localparam [3:0] S_LOAD1_2 = 4'd6;
localparam [3:0] S_WAIT0   = 4'd7;
localparam [3:0] S_START1  = 4'd8;
localparam [3:0] S_WAIT1   = 4'd9;
localparam [3:0] S_DONE    = 4'd10;

reg [3:0] state_q;

assign vector_length_o =
    16'd10;

always @(*) begin
    load_bank_o       = 1'b0;
    load_active_o     = 1'b0;

    act_wr_en_o       = 1'b0;
    act_wr_addr_o     = 8'd0;
    act_wr_data_o     = 32'h0000_0000;

    weight_wr_en_o    = 1'b0;
    weight_wr_addr_o  = 8'd0;
    weight_wr_data_o  = 32'h0000_0000;

    compute_bank_o    = 1'b0;
    start_o           = 1'b0;

    case (state_q)
        S_LOAD0_0: begin
            load_bank_o      = 1'b0;
            load_active_o    = 1'b1;
            act_wr_en_o      = 1'b1;
            act_wr_addr_o    = 8'd0;
            act_wr_data_o    = {8'd4, 8'd3, 8'd2, 8'd1};
            weight_wr_en_o   = 1'b1;
            weight_wr_addr_o = 8'd0;
            weight_wr_data_o = {8'd1, 8'd1, 8'd1, 8'd1};
        end

        S_LOAD0_1: begin
            load_bank_o      = 1'b0;
            load_active_o    = 1'b1;
            act_wr_en_o      = 1'b1;
            act_wr_addr_o    = 8'd1;
            act_wr_data_o    = {8'd8, 8'd7, 8'd6, 8'd5};
            weight_wr_en_o   = 1'b1;
            weight_wr_addr_o = 8'd1;
            weight_wr_data_o = {8'd1, 8'd1, 8'd1, 8'd1};
        end

        S_LOAD0_2: begin
            load_bank_o      = 1'b0;
            load_active_o    = 1'b1;
            act_wr_en_o      = 1'b1;
            act_wr_addr_o    = 8'd2;
            act_wr_data_o    = {8'h7F, 8'h7F, 8'd10, 8'd9};
            weight_wr_en_o   = 1'b1;
            weight_wr_addr_o = 8'd2;
            weight_wr_data_o = {8'h7F, 8'h7F, 8'd1, 8'd1};
        end

        S_START0: begin
            compute_bank_o = 1'b0;
            start_o        = 1'b1;
        end

        S_LOAD1_0: begin
            compute_bank_o   = 1'b0;
            load_bank_o      = 1'b1;
            load_active_o    = 1'b1;
            act_wr_en_o      = 1'b1;
            act_wr_addr_o    = 8'd0;
            act_wr_data_o    = {8'd8, 8'd6, 8'd4, 8'd2};
            weight_wr_en_o   = 1'b1;
            weight_wr_addr_o = 8'd0;
            weight_wr_data_o = {8'd1, 8'd1, 8'd1, 8'd1};
        end

        S_LOAD1_1: begin
            compute_bank_o   = 1'b0;
            load_bank_o      = 1'b1;
            load_active_o    = 1'b1;
            act_wr_en_o      = 1'b1;
            act_wr_addr_o    = 8'd1;
            act_wr_data_o    = {8'd16, 8'd14, 8'd12, 8'd10};
            weight_wr_en_o   = 1'b1;
            weight_wr_addr_o = 8'd1;
            weight_wr_data_o = {8'd1, 8'd1, 8'd1, 8'd1};
        end

        S_LOAD1_2: begin
            compute_bank_o   = 1'b0;
            load_bank_o      = 1'b1;
            load_active_o    = 1'b1;
            act_wr_en_o      = 1'b1;
            act_wr_addr_o    = 8'd2;
            act_wr_data_o    = {8'h7F, 8'h7F, 8'd20, 8'd18};
            weight_wr_en_o   = 1'b1;
            weight_wr_addr_o = 8'd2;
            weight_wr_data_o = {8'h7F, 8'h7F, 8'd1, 8'd1};
        end

        S_WAIT0: begin
            compute_bank_o = 1'b0;
        end

        S_START1: begin
            compute_bank_o = 1'b1;
            start_o        = 1'b1;
        end

        S_WAIT1,
        S_DONE: begin
            compute_bank_o = 1'b1;
        end

        default: begin
        end
    endcase
end

always @(posedge clk) begin
    if (!resetn) begin
        state_q        <= S_LOAD0_0;
        first_result_o <= 32'sd0;
        second_result_o<= 32'sd0;
        demo_done_o    <= 1'b0;
    end else begin
        demo_done_o <= 1'b0;

        if (result_valid_i) begin
            if (state_q == S_WAIT0) begin
                first_result_o <= result_i;
            end

            if (state_q == S_WAIT1) begin
                second_result_o <= result_i;
            end
        end

        case (state_q)
            S_LOAD0_0: state_q <= S_LOAD0_1;
            S_LOAD0_1: state_q <= S_LOAD0_2;
            S_LOAD0_2: state_q <= S_START0;
            S_START0:  state_q <= S_LOAD1_0;
            S_LOAD1_0: state_q <= S_LOAD1_1;
            S_LOAD1_1: state_q <= S_LOAD1_2;
            S_LOAD1_2: state_q <= S_WAIT0;

            S_WAIT0: begin
                if (done_i) begin
                    state_q <= S_START1;
                end
            end

            S_START1: begin
                state_q <= S_WAIT1;
            end

            S_WAIT1: begin
                if (done_i) begin
                    state_q <= S_DONE;
                end
            end

            S_DONE: begin
                demo_done_o <= 1'b1;
                state_q <= S_DONE;
            end

            default: begin
                state_q <= S_LOAD0_0;
            end
        endcase
    end
end

endmodule
