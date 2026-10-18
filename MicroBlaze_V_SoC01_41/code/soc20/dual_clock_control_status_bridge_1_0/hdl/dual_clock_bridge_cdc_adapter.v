module dual_clock_bridge_cdc_adapter (
    // AXI/register clock domain
    input  wire        axi_clk,
    input  wire        axi_resetn,

    input  wire [31:0] control_axi_i,
    input  wire [31:0] in_data_axi_i,
    input  wire        in_valid_axi_i,
    output wire        in_ready_axi_o,

    output wire [31:0] out_data_axi_o,
    output wire        out_valid_axi_o,
    input  wire        out_ready_axi_i,

    output wire [31:0] status_axi_o,

    // Functional clock domain
    input  wire        func_clk,
    input  wire        func_resetn,

    output wire [63:0] packet_func_o,
    output wire        packet_valid_func_o,
    input  wire        packet_ready_func_i,

    input  wire [31:0] result_func_i,
    input  wire        result_valid_func_i,
    output wire        result_ready_func_o,

    input  wire        func_idle_i,
    input  wire        func_busy_i
);

// This module owns all CDC policy between the AXI and functional domains.
// Related CONTROL + IN_DATA values are packed and transferred coherently.

wire [63:0] packet_axi;

assign packet_axi = {
    control_axi_i,
    in_data_axi_i
};

xpm_ready_valid_bus_bridge #(
    .WIDTH(64)
) u_input_packet_cdc (
    .src_clk(axi_clk),
    .src_resetn(axi_resetn),
    .src_data_i(packet_axi),
    .src_valid_i(in_valid_axi_i),
    .src_ready_o(in_ready_axi_o),

    .dest_clk(func_clk),
    .dest_resetn(func_resetn),
    .dest_data_o(packet_func_o),
    .dest_valid_o(packet_valid_func_o),
    .dest_ready_i(packet_ready_func_i)
);

xpm_ready_valid_bus_bridge #(
    .WIDTH(32)
) u_output_result_cdc (
    .src_clk(func_clk),
    .src_resetn(func_resetn),
    .src_data_i(result_func_i),
    .src_valid_i(result_valid_func_i),
    .src_ready_o(result_ready_func_o),

    .dest_clk(axi_clk),
    .dest_resetn(axi_resetn),
    .dest_data_o(out_data_axi_o),
    .dest_valid_o(out_valid_axi_o),
    .dest_ready_i(out_ready_axi_i)
);

// These are independent one-bit status flags.
// They are intentionally not treated as a coherent binary bus.
wire func_idle_axi;
wire func_busy_axi;

xpm_single_bit_sync u_idle_status_cdc (
    .src_clk(func_clk),
    .src_level_i(func_idle_i),
    .dest_clk(axi_clk),
    .dest_level_o(func_idle_axi)
);

xpm_single_bit_sync u_busy_status_cdc (
    .src_clk(func_clk),
    .src_level_i(func_busy_i),
    .dest_clk(axi_clk),
    .dest_level_o(func_busy_axi)
);

assign status_axi_o = {
    30'h0,
    func_busy_axi,
    func_idle_axi
};

endmodule
