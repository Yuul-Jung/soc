(* use_dsp = "yes" *)
module mac_s8_acc32_pipelined (
    input  wire                    clk,
    input  wire                    resetn,
    input  wire                    clear_i,
    input  wire                    valid_i,

    input  wire signed [7:0]       a_i,
    input  wire signed [7:0]       b_i,

    output reg  signed [31:0]      acc_o,
    output reg                     valid_o
);

// Pipeline structure:
// Stage 1: signed multiply and product register
// Stage 2: sign extension + accumulation
//
// The binary point does not move during accumulation.
// a/b use 7 fractional bits, so product/accumulator use 14 fractional bits.

wire signed [15:0] product_w;

reg signed [15:0] product_q;
reg               product_valid_q;

wire signed [31:0] product_ext_w;

assign product_w =
    $signed(a_i) * $signed(b_i);

assign product_ext_w =
    {{16{product_q[15]}}, product_q};

always @(posedge clk) begin
    if (!resetn) begin
        product_q       <= 16'sd0;
        product_valid_q <= 1'b0;

        acc_o           <= 32'sd0;
        valid_o         <= 1'b0;
    end else if (clear_i) begin
        product_q       <= 16'sd0;
        product_valid_q <= 1'b0;

        acc_o           <= 32'sd0;
        valid_o         <= 1'b0;
    end else begin
        // Stage 1
        product_valid_q <= valid_i;

        if (valid_i) begin
            product_q <= product_w;
        end

        // Stage 2
        valid_o <= product_valid_q;

        if (product_valid_q) begin
            acc_o <= acc_o + product_ext_w;
        end
    end
end

endmodule
