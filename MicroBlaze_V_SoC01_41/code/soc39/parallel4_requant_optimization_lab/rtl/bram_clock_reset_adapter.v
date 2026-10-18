module bram_clock_reset_adapter (
    input  wire clk_i,
    input  wire resetn_i,

    output wire bram_clk_o,
    output wire bram_rst_o
);

assign bram_clk_o = clk_i;
assign bram_rst_o = ~resetn_i;

endmodule
