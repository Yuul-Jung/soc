module axi4lite_slave_adapter #(
    parameter integer C_S_AXI_ADDR_WIDTH = 32
)(
    input  wire                          s_axi_aclk,
    input  wire                          s_axi_aresetn,

    // AXI4-Lite Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire [2:0]                    s_axi_awprot,
    input  wire                          s_axi_awvalid,
    output wire                          s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [31:0]                   s_axi_wdata,
    input  wire [3:0]                    s_axi_wstrb,
    input  wire                          s_axi_wvalid,
    output wire                          s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]                    s_axi_bresp,
    output reg                           s_axi_bvalid,
    input  wire                          s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire [2:0]                    s_axi_arprot,
    input  wire                          s_axi_arvalid,
    output wire                          s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [31:0]                   s_axi_rdata,
    output reg  [1:0]                    s_axi_rresp,
    output reg                           s_axi_rvalid,
    input  wire                          s_axi_rready,

    // Bus-independent register access interface
    output wire                          wr_en,
    output wire [7:0]                    wr_offset,
    output wire [31:0]                   wr_data,
    output wire [3:0]                    wr_strb,

    output wire [7:0]                    rd_offset,
    input  wire [31:0]                   rd_data
);

// AXI response code used by this basic slave.
localparam [1:0] AXI_RESP_OKAY = 2'b00;

// Write Address and Write Data are independent AXI channels.
// Each channel is buffered separately until both are available.
reg                          aw_stored;
reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_stored;
reg                          w_stored;
reg [31:0]                   wdata_stored;
reg [3:0]                    wstrb_stored;

wire write_commit;

// Single-outstanding-write policy:
// Do not accept a new write while a response is pending.
assign s_axi_awready =
    s_axi_aresetn && !aw_stored && !s_axi_bvalid;

assign s_axi_wready =
    s_axi_aresetn && !w_stored && !s_axi_bvalid;

// Register-bank write occurs only after BOTH address and data
// channels have completed their independent handshakes.
assign write_commit =
    aw_stored && w_stored && !s_axi_bvalid;

assign wr_en     = write_commit;
assign wr_offset = awaddr_stored[7:0];
assign wr_data   = wdata_stored;
assign wr_strb   = wstrb_stored;

// Read side accepts one address only when no previous R response
// is waiting for the master.
assign s_axi_arready =
    s_axi_aresetn && !s_axi_rvalid;

// custom_register_bank read path is combinational.
// The address presented during AR handshake selects rd_data.
assign rd_offset = s_axi_araddr[7:0];

// AWPROT / ARPROT are not used by this educational register slave.
wire unused_prot;
assign unused_prot = ^{s_axi_awprot, s_axi_arprot};

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        aw_stored     <= 1'b0;
        awaddr_stored <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        w_stored      <= 1'b0;
        wdata_stored  <= 32'h0000_0000;
        wstrb_stored  <= 4'b0000;
        s_axi_bresp   <= AXI_RESP_OKAY;
        s_axi_bvalid  <= 1'b0;
    end else begin
        // Capture Write Address independently.
        if (s_axi_awready && s_axi_awvalid) begin
            aw_stored     <= 1'b1;
            awaddr_stored <= s_axi_awaddr;
        end

        // Capture Write Data independently.
        if (s_axi_wready && s_axi_wvalid) begin
            w_stored     <= 1'b1;
            wdata_stored <= s_axi_wdata;
            wstrb_stored <= s_axi_wstrb;
        end

        // Once both parts exist, pulse wr_en through write_commit
        // and create the AXI B response.
        if (write_commit) begin
            aw_stored    <= 1'b0;
            w_stored     <= 1'b0;
            s_axi_bresp  <= AXI_RESP_OKAY;
            s_axi_bvalid <= 1'b1;
        end else if (s_axi_bvalid && s_axi_bready) begin
            s_axi_bvalid <= 1'b0;
        end
    end
end

always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
        s_axi_rdata  <= 32'h0000_0000;
        s_axi_rresp  <= AXI_RESP_OKAY;
        s_axi_rvalid <= 1'b0;
    end else begin
        // Capture the selected register value at AR handshake.
        if (s_axi_arready && s_axi_arvalid) begin
            s_axi_rdata  <= rd_data;
            s_axi_rresp  <= AXI_RESP_OKAY;
            s_axi_rvalid <= 1'b1;
        end else if (s_axi_rvalid && s_axi_rready) begin
            s_axi_rvalid <= 1'b0;
        end
    end
end

endmodule
