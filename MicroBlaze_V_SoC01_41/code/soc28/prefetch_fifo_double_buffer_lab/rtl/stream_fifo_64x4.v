module stream_fifo_64x4 (
    input  wire         clk,
    input  wire         resetn,
    input  wire         clear_i,

    input  wire         push_valid_i,
    output wire         push_ready_o,
    input  wire [63:0]  push_data_i,

    output wire         pop_valid_o,
    input  wire         pop_ready_i,
    output wire [63:0]  pop_data_o,

    output reg  [2:0]   count_o
);

// Small elastic FIFO for BRAM prefetch responses.
//
// Depth = 4 entries.
// Width = 64 bits = {weight[31:0], activation[31:0]}.
//
// A tiny FIFO is intentionally kept separate from the local BRAM arrays.
// It absorbs consumer backpressure without changing the BRAM contents.

reg [63:0] mem [0:3];

reg [1:0] wr_ptr_q;
reg [1:0] rd_ptr_q;

wire push_w;
wire pop_w;

assign pop_valid_o =
    (count_o != 3'd0);

assign pop_data_o =
    mem[rd_ptr_q];

// Allow replacement in the same cycle when full and one item pops.
assign push_ready_o =
    (count_o < 3'd4) ||
    (
        (count_o == 3'd4) &&
        pop_valid_o &&
        pop_ready_i
    );

assign push_w =
    push_valid_i &&
    push_ready_o;

assign pop_w =
    pop_valid_o &&
    pop_ready_i;

always @(posedge clk) begin
    if (!resetn || clear_i) begin
        wr_ptr_q <= 2'd0;
        rd_ptr_q <= 2'd0;
        count_o  <= 3'd0;
    end else begin
        if (push_w) begin
            mem[wr_ptr_q] <= push_data_i;
            wr_ptr_q <= wr_ptr_q + 2'd1;
        end

        if (pop_w) begin
            rd_ptr_q <= rd_ptr_q + 2'd1;
        end

        case ({push_w, pop_w})
            2'b10: count_o <= count_o + 3'd1;
            2'b01: count_o <= count_o - 3'd1;
            default: count_o <= count_o;
        endcase
    end
end

endmodule
