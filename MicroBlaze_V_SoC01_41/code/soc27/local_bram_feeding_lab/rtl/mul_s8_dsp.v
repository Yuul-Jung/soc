(* use_dsp = "yes" *)
module mul_s8_dsp (
    input  wire signed [7:0]  a_i,
    input  wire signed [7:0]  b_i,
    output wire signed [15:0] p_o
);

// Dedicated 8x8 signed multiplier building block.
// USE_DSP requests DSP implementation, but the final mapping
// must still be verified with Vivado synthesis reports.

assign p_o =
    $signed(a_i) * $signed(b_i);

endmodule
