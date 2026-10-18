module reset_active_high_to_active_low (
    input  wire reset_i,
    output wire resetn_o
);

// Basys3 center push button is active high.
// The timing-lab cores use active-low reset.

assign resetn_o = ~reset_i;

endmodule
