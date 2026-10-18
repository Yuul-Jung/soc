module custom_axi4lite_ip #(
    parameter integer C_S_AXI_ADDR_WIDTH = 32
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

    // Hardware-side status / events
    input  wire                          busy_i,
    input  wire                          done_i,
    input  wire                          error_i,
    input  wire                          irq_done_event_i,
    input  wire                          irq_error_event_i,
    input  wire [31:0]                   data_out_i,

    // Hardware-side controls
    output wire                          enable_o,
    output wire [1:0]                    mode_o,
    output wire                          start_pulse_o,
    output wire                          clear_pulse_o,
    output wire [31:0]                   data_in_o,
    output wire [1:0]                    irq_status_o
);

// Wrapper principle:
// This module only connects the AXI adapter and the register bank.
// No functional policy, arithmetic or register behavior is added here.
wire        wr_en;
wire [7:0]  wr_offset;
wire [31:0] wr_data;
wire [3:0]  wr_strb;
wire [7:0]  rd_offset;
wire [31:0] rd_data;

axi4lite_slave_adapter #(
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
) u_axi4lite_slave_adapter (
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

    .wr_en(wr_en),
    .wr_offset(wr_offset),
    .wr_data(wr_data),
    .wr_strb(wr_strb),
    .rd_offset(rd_offset),
    .rd_data(rd_data)
);

custom_register_bank u_custom_register_bank (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),

    .wr_en(wr_en),
    .wr_offset(wr_offset),
    .wr_data(wr_data),
    .wr_strb(wr_strb),

    .rd_offset(rd_offset),
    .rd_data(rd_data),

    .busy_i(busy_i),
    .done_i(done_i),
    .error_i(error_i),
    .irq_done_event_i(irq_done_event_i),
    .irq_error_event_i(irq_error_event_i),
    .data_out_i(data_out_i),

    .enable_o(enable_o),
    .mode_o(mode_o),
    .start_pulse_o(start_pulse_o),
    .clear_pulse_o(clear_pulse_o),
    .data_in_o(data_in_o),
    .irq_status_o(irq_status_o)
);

endmodule
