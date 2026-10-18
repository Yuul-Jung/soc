module uart_tx_axi4lite_ip #(
    parameter integer C_S_AXI_ADDR_WIDTH = 32,
    parameter integer CLKS_PER_BIT       = 868
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

    output wire                          uart_tx_o
);

wire        wr_en;
wire [7:0]  wr_offset;
wire [31:0] wr_data;
wire [3:0]  wr_strb;
// (삭제) 조합 읽기 어댑터에는 rd_en 포트가 없다.
wire [7:0]  rd_offset;
wire [31:0] rd_data;

wire        enable;
wire        send_pulse;
wire        clear_pulse;
wire [7:0]  tx_data;
wire [1:0]  irq_status;

wire        busy;
wire        done;
wire        error;
wire        irq_done_event;
wire        irq_error_event;

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

    // (삭제) rd_offset / rd_data만 사용하는 조합 읽기 연결.
    .rd_offset(rd_offset),
    .rd_data(rd_data)
);

uart_tx_register_bank #(
    .BAUD_DIV_VALUE(CLKS_PER_BIT)
) u_uart_tx_register_bank (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),

    .wr_en(wr_en),
    .wr_offset(wr_offset),
    .wr_data(wr_data),
    .wr_strb(wr_strb),

    .rd_offset(rd_offset),
    .rd_data(rd_data),

    .busy_i(busy),
    .done_i(done),
    .error_i(error),
    .irq_done_event_i(irq_done_event),
    .irq_error_event_i(irq_error_event),

    .enable_o(enable),
    .send_pulse_o(send_pulse),
    .clear_pulse_o(clear_pulse),
    .tx_data_o(tx_data),
    .irq_status_o(irq_status)
);

uart_tx_controller_adapter #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
) u_uart_tx_controller_adapter (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),

    .enable_i(enable),
    .send_pulse_i(send_pulse),
    .clear_pulse_i(clear_pulse),
    .tx_data_i(tx_data),

    .busy_o(busy),
    .done_o(done),
    .error_o(error),
    .irq_done_event_o(irq_done_event),
    .irq_error_event_o(irq_error_event),

    .uart_tx_o(uart_tx_o)
);

endmodule
