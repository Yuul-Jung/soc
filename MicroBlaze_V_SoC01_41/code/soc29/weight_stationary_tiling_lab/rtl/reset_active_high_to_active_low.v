module reset_active_high_to_active_low (
    input  wire reset_i,
    output wire resetn_o
);

// Basys3 center push button btnC is active high.

assign resetn_o = ~reset_i;

endmodule
