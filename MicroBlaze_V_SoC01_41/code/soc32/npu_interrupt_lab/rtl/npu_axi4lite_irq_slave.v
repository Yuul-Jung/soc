module npu_axi4lite_irq_slave #(
    parameter integer C_S_AXI_ADDR_WIDTH = 8,
    parameter integer C_S_AXI_DATA_WIDTH = 32
) (
    input  wire                            s_axi_aclk,
    input  wire                            s_axi_aresetn,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire                            s_axi_awvalid,
    output wire                            s_axi_awready,

    input  wire [C_S_AXI_DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire                            s_axi_wvalid,
    output wire                            s_axi_wready,

    output wire [1:0]                      s_axi_bresp,
    output reg                             s_axi_bvalid,
    input  wire                            s_axi_bready,

    input  wire [C_S_AXI_ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire                            s_axi_arvalid,
    output wire                            s_axi_arready,

    output reg  [C_S_AXI_DATA_WIDTH-1:0]   s_axi_rdata,
    output wire [1:0]                      s_axi_rresp,
    output reg                             s_axi_rvalid,
    input  wire                            s_axi_rready,

    output wire                            irq_o,

    output wire                            accel_busy_o,
    output wire                            accel_done_sticky_o,
    output wire                            accel_error_sticky_o,
    output wire [7:0]                      saturation_count_o
);

// AW and W are independent channels.
// The register write and BVALID generation occur on the same
// commit clock after both address and data have been captured.

reg                            aw_pending_q;
reg [C_S_AXI_ADDR_WIDTH-1:0]   awaddr_q;

reg                            w_pending_q;
reg [C_S_AXI_DATA_WIDTH-1:0]   wdata_q;
reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_q;

assign s_axi_awready =
    !aw_pending_q &&
    !s_axi_bvalid;

assign s_axi_wready =
    !w_pending_q &&
    !s_axi_bvalid;

assign s_axi_bresp = 2'b00;

wire aw_handshake_w;
wire w_handshake_w;

assign aw_handshake_w =
    s_axi_awvalid &&
    s_axi_awready;

assign w_handshake_w =
    s_axi_wvalid &&
    s_axi_wready;

wire register_write_fire_w;

assign register_write_fire_w =
    aw_pending_q &&
    w_pending_q &&
    !s_axi_bvalid;

wire [31:0] register_rd_data_w;

npu_register_bank_irq u_register_bank (
    .clk(s_axi_aclk),
    .resetn(s_axi_aresetn),

    .wr_en_i(register_write_fire_w),
    .wr_addr_i(awaddr_q[7:0]),
    .wr_data_i(wdata_q),
    .wr_strb_i(wstrb_q),

    .rd_addr_i(s_axi_araddr[7:0]),
    .rd_data_o(register_rd_data_w),

    .irq_o(irq_o),

    .accel_busy_o(accel_busy_o),
    .accel_done_sticky_o(accel_done_sticky_o),
    .accel_error_sticky_o(accel_error_sticky_o),
    .saturation_count_o(saturation_count_o)
);

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        aw_pending_q <= 1'b0;
        awaddr_q     <= {C_S_AXI_ADDR_WIDTH{1'b0}};

        w_pending_q <= 1'b0;
        wdata_q     <= {C_S_AXI_DATA_WIDTH{1'b0}};
        wstrb_q     <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};

        s_axi_bvalid <= 1'b0;
    end else begin
        if (aw_handshake_w) begin
            aw_pending_q <= 1'b1;
            awaddr_q     <= s_axi_awaddr;
        end

        if (w_handshake_w) begin
            w_pending_q <= 1'b1;
            wdata_q     <= s_axi_wdata;
            wstrb_q     <= s_axi_wstrb;
        end

        if (register_write_fire_w) begin
            aw_pending_q <= 1'b0;
            w_pending_q  <= 1'b0;
            s_axi_bvalid <= 1'b1;
        end

        if (
            s_axi_bvalid &&
            s_axi_bready
        ) begin
            s_axi_bvalid <= 1'b0;
        end
    end
end

assign s_axi_arready =
    !s_axi_rvalid;

assign s_axi_rresp = 2'b00;

wire ar_handshake_w;

assign ar_handshake_w =
    s_axi_arvalid &&
    s_axi_arready;

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        s_axi_rdata  <= {C_S_AXI_DATA_WIDTH{1'b0}};
        s_axi_rvalid <= 1'b0;
    end else begin
        if (ar_handshake_w) begin
            s_axi_rdata  <= register_rd_data_w;
            s_axi_rvalid <= 1'b1;
        end

        if (
            s_axi_rvalid &&
            s_axi_rready
        ) begin
            s_axi_rvalid <= 1'b0;
        end
    end
end

endmodule
