module npu_full_accelerator_sim_top (
    input  wire        clk,
    input  wire        resetn,

    // AXI4-Lite control-plane master stimulus.
    input  wire [7:0]  s_axi_awaddr,
    input  wire        s_axi_awvalid,
    output wire        s_axi_awready,

    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output wire        s_axi_wready,

    output wire [1:0]  s_axi_bresp,
    output wire        s_axi_bvalid,
    input  wire        s_axi_bready,

    input  wire [7:0]  s_axi_araddr,
    input  wire        s_axi_arvalid,
    output wire        s_axi_arready,

    output wire [31:0] s_axi_rdata,
    output wire [1:0]  s_axi_rresp,
    output wire        s_axi_rvalid,
    input  wire        s_axi_rready,

    // CPU-side Tensor BRAM Port-A model access.
    input  wire        cpu_mem_en_i,
    input  wire [3:0]  cpu_mem_we_i,
    input  wire [11:0] cpu_mem_addr_i,
    input  wire [31:0] cpu_mem_wdata_i,
    output wire [31:0] cpu_mem_rdata_o,

    output wire        irq_o
);

// Simulation Shell / Wrapper.
// Port A models MicroBlaze V + AXI BRAM Controller.
// Port B is driven by npu_full_accelerator_ip.

wire        bram_clk;
wire        bram_rst;
wire        bram_en;
wire [3:0]  bram_we;
wire [11:0] bram_addr;
wire [31:0] bram_wdata;
wire [31:0] bram_rdata;

npu_full_accelerator_ip u_npu (
    .s_axi_aclk(clk),
    .s_axi_aresetn(resetn),

    .s_axi_awaddr(s_axi_awaddr),
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
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),

    .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp),
    .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready),

    .bram_clk_o(bram_clk),
    .bram_rst_o(bram_rst),
    .bram_en_o(bram_en),
    .bram_we_o(bram_we),
    .bram_addr_o(bram_addr),
    .bram_wdata_o(bram_wdata),
    .bram_rdata_i(bram_rdata),

    .irq(irq_o)
);

tensor_bram_tdp_4k_model u_tensor_bram (
    .clk(clk),

    .a_en_i(cpu_mem_en_i),
    .a_we_i(cpu_mem_we_i),
    .a_addr_i(cpu_mem_addr_i),
    .a_wdata_i(cpu_mem_wdata_i),
    .a_rdata_o(cpu_mem_rdata_o),

    .b_en_i(bram_en),
    .b_we_i(bram_we),
    .b_addr_i(bram_addr),
    .b_wdata_i(bram_wdata),
    .b_rdata_o(bram_rdata)
);

endmodule
