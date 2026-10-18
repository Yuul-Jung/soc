module custom_axi4lite_controller_ip #(
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
    input  wire                          s_axi_rready
);

// Shell / Wrapper principle:
// - AXI/Register behavior stays in custom_axi4lite_ip.
// - Functional processing stays in example_processing_controller.
// - This module contains only wires and module connections.

wire        enable;
wire [1:0]  mode;
wire        start_pulse;
wire        clear_pulse;
wire [31:0] data_in;
wire [1:0]  irq_status;

wire        busy;
wire        done;
wire        error;
wire        irq_done_event;
wire        irq_error_event;
wire [31:0] data_out;

custom_axi4lite_ip #(
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) u_custom_axi4lite_ip (
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

    .busy_i(busy),
    .done_i(done),
    .error_i(error),
    .irq_done_event_i(irq_done_event),
    .irq_error_event_i(irq_error_event),
    .data_out_i(data_out),

    .enable_o(enable),
    .mode_o(mode),
    .start_pulse_o(start_pulse),
    .clear_pulse_o(clear_pulse),
    .data_in_o(data_in),
    .irq_status_o(irq_status)
);

example_processing_controller #(
    .PROCESS_CYCLES(PROCESS_CYCLES)
) u_example_processing_controller (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),

    .enable_i(enable),
    .mode_i(mode),
    .start_pulse_i(start_pulse),
    .clear_pulse_i(clear_pulse),
    .data_in_i(data_in),

    .busy_o(busy),
    .done_o(done),
    .error_o(error),
    .irq_done_event_o(irq_done_event),
    .irq_error_event_o(irq_error_event),
    .data_out_o(data_out)
);

endmodule
