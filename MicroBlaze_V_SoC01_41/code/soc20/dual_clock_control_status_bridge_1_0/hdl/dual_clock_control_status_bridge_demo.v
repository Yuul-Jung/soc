module dual_clock_control_status_bridge_demo #(
    parameter integer C_S_AXI_ADDR_WIDTH = 32,
    parameter integer PROCESS_CYCLES     = 6
)(
    input  wire                          s_axi_aclk,
    input  wire                          func_clk,
    input  wire                          global_resetn,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire [2:0]                    s_axi_awprot,
    input  wire                          s_axi_awvalid,
    output wire                          s_axi_awready,

    input  wire [31:0]                   s_axi_wdata,
    input  wire [3:0]                    s_axi_wstrb,
    input  wire                          s_axi_wvalid,
    output wire                          s_axi_wready,

    output wire [1:0]                    s_axi_bresp,
    output wire                          s_axi_bvalid,
    input  wire                          s_axi_bready,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [2:0]                    s_axi_arprot,
    input  wire                          s_axi_arvalid,
    output wire                          s_axi_arready,

    output wire [31:0]                   s_axi_rdata,
    output wire [1:0]                    s_axi_rresp,
    output wire                          s_axi_rvalid,
    input  wire                          s_axi_rready,

    output wire                          irq_o
);

// Pure Shell / Wrapper:
// - reset synchronization is delegated
// - CDC policy is delegated
// - functional processing is delegated
// - AXI/Register behavior is delegated

wire axi_resetn;
wire func_resetn;

wire [31:0] control_axi;
wire [31:0] status_axi;

wire [31:0] in_data_axi;
wire        in_valid_axi;
wire        in_ready_axi;

wire [31:0] out_data_axi;
wire        out_valid_axi;
wire        out_ready_axi;

wire [63:0] packet_func;
wire        packet_valid_func;
wire        packet_ready_func;

wire [31:0] result_func;
wire        result_valid_func;
wire        result_ready_func;

wire func_idle;
wire func_busy;

xpm_reset_sync_active_low u_axi_reset_sync (
    .dest_clk(s_axi_aclk),
    .global_resetn_i(global_resetn),
    .dest_resetn_o(axi_resetn)
);

xpm_reset_sync_active_low u_func_reset_sync (
    .dest_clk(func_clk),
    .global_resetn_i(global_resetn),
    .dest_resetn_o(func_resetn)
);

axi_control_status_bridge_ip #(
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) u_axi_control_status_bridge_ip (
    .s_axi_aclk(s_axi_aclk),
    .s_axi_aresetn(axi_resetn),

    .s_axi_awaddr(s_axi_awaddr),
    .s_axi_awprot(s_axi_awprot),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),

    .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb),
    .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready),

    .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid),
    .s_axi_bready(s_axi_bready),

    .s_axi_araddr(s_axi_araddr),
    .s_axi_arprot(s_axi_arprot),
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),

    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),

    .control_o(control_axi),
    .status_i(status_axi),

    .in_data_o(in_data_axi),
    .in_valid_o(in_valid_axi),
    .in_ready_i(in_ready_axi),

    .out_data_i(out_data_axi),
    .out_valid_i(out_valid_axi),
    .out_ready_o(out_ready_axi),

    .irq_o(irq_o)
);

dual_clock_bridge_cdc_adapter u_dual_clock_bridge_cdc_adapter (
    .axi_clk(s_axi_aclk),
    .axi_resetn(axi_resetn),

    .control_axi_i(control_axi),
    .in_data_axi_i(in_data_axi),
    .in_valid_axi_i(in_valid_axi),
    .in_ready_axi_o(in_ready_axi),

    .out_data_axi_o(out_data_axi),
    .out_valid_axi_o(out_valid_axi),
    .out_ready_axi_i(out_ready_axi),

    .status_axi_o(status_axi),

    .func_clk(func_clk),
    .func_resetn(func_resetn),

    .packet_func_o(packet_func),
    .packet_valid_func_o(packet_valid_func),
    .packet_ready_func_i(packet_ready_func),

    .result_func_i(result_func),
    .result_valid_func_i(result_valid_func),
    .result_ready_func_o(result_ready_func),

    .func_idle_i(func_idle),
    .func_busy_i(func_busy)
);

dual_clock_example_core #(
    .PROCESS_CYCLES(PROCESS_CYCLES)
) u_dual_clock_example_core (
    .clk(func_clk),
    .resetn(func_resetn),

    .packet_i(packet_func),
    .packet_valid_i(packet_valid_func),
    .packet_ready_o(packet_ready_func),

    .result_o(result_func),
    .result_valid_o(result_valid_func),
    .result_ready_i(result_ready_func),

    .idle_o(func_idle),
    .busy_o(func_busy)
);

endmodule
