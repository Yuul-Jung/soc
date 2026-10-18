module axi_control_status_bridge_demo_top #(
    parameter integer C_S_AXI_ADDR_WIDTH = 32,
    parameter integer PROCESS_CYCLES     = 4
)(
    input  wire                          s_axi_aclk,
    input  wire                          s_axi_aresetn,

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

// Demo wrapper only connects the reusable bridge to a functional core.

wire [31:0] control;
wire [31:0] status;

wire [31:0] in_data;
wire        in_valid;
wire        in_ready;

wire [31:0] out_data;
wire        out_valid;
wire        out_ready;

axi_control_status_bridge_ip #(
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) u_axi_control_status_bridge_ip (
    .s_axi_aclk(s_axi_aclk),
    .s_axi_aresetn(s_axi_aresetn),

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

    .control_o(control),
    .status_i(status),

    .in_data_o(in_data),
    .in_valid_o(in_valid),
    .in_ready_i(in_ready),

    .out_data_i(out_data),
    .out_valid_i(out_valid),
    .out_ready_o(out_ready),

    .irq_o(irq_o)
);

example_ready_valid_core #(
    .PROCESS_CYCLES(PROCESS_CYCLES)
) u_example_ready_valid_core (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),

    .control_i(control),
    .status_o(status),

    .in_data_i(in_data),
    .in_valid_i(in_valid),
    .in_ready_o(in_ready),

    .out_data_o(out_data),
    .out_valid_o(out_valid),
    .out_ready_i(out_ready)
);

endmodule
