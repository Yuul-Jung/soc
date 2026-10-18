(* use_dsp = "yes" *)
module mac_s8_acc32_basic (
    input  wire                    clk,
    input  wire                    resetn,
    input  wire                    clear_i,
    input  wire                    valid_i,

    input  wire signed [7:0]       a_i,
    input  wire signed [7:0]       b_i,

    output reg  signed [31:0]      acc_o,
    output reg                     valid_o
);

// Fixed-point interpretation used in this chapter:
// - a_i, b_i: signed 8-bit values with FRAC_BITS = 7
// - real value = raw signed integer / 2^7
// - product: 16-bit signed raw value with 14 fractional bits
// - accumulator keeps the same 14 fractional bits
//
// No rounding/truncation is needed before accumulation because the full
// 16-bit product is sign-extended into the 32-bit accumulator.

wire signed [15:0] product_w;
wire signed [31:0] product_ext_w;

assign product_w =
    $signed(a_i) * $signed(b_i);

assign product_ext_w =
    {{16{product_w[15]}}, product_w};

always @(posedge clk) begin
    if (!resetn) begin
        acc_o   <= 32'sd0;
        valid_o <= 1'b0;
    end else if (clear_i) begin
        acc_o   <= 32'sd0;
        valid_o <= 1'b0;
    end else begin
        valid_o <= valid_i;

        if (valid_i) begin
            acc_o <= acc_o + product_ext_w;
        end
    end
end

endmodule
