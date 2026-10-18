module pwm_axi4lite_ip #(
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

    output wire                          pwm_o
);

wire        wr_en;
wire [7:0]  wr_offset;
wire [31:0] wr_data;
wire [3:0]  wr_strb;
// (삭제) 조합 읽기 어댑터에는 rd_en 포트가 없다.
wire [7:0]  rd_offset;
wire [31:0] rd_data;

wire        enable;
wire        invert;
wire [31:0] period_shadow;
wire [31:0] duty_shadow;
wire        update_pulse;
wire        clear_error_pulse;

wire        active;
wire        error;
wire [31:0] active_period;
wire [31:0] active_duty;

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

pwm_register_bank u_pwm_register_bank (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),

    .wr_en(wr_en),
    .wr_offset(wr_offset),
    .wr_data(wr_data),
    .wr_strb(wr_strb),

    .rd_offset(rd_offset),
    .rd_data(rd_data),

    .active_i(active),
    .error_i(error),
    .active_period_i(active_period),
    .active_duty_i(active_duty),

    .enable_o(enable),
    .invert_o(invert),
    .period_shadow_o(period_shadow),
    .duty_shadow_o(duty_shadow),
    .update_pulse_o(update_pulse),
    .clear_error_pulse_o(clear_error_pulse)
);

pwm_controller_adapter u_pwm_controller_adapter (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),

    .enable_i(enable),
    .invert_i(invert),
    .period_shadow_i(period_shadow),
    .duty_shadow_i(duty_shadow),
    .update_pulse_i(update_pulse),
    .clear_error_pulse_i(clear_error_pulse),

    .active_o(active),
    .error_o(error),
    .active_period_o(active_period),
    .active_duty_o(active_duty),

    .pwm_o(pwm_o)
);

endmodule
