`timescale 1ns / 1ps

module tb_dual_clock_control_status_bridge_demo;

localparam integer ADDR_W = 32;

reg axi_clk = 1'b0;
reg func_clk = 1'b0;
reg global_resetn = 1'b0;

always #5 axi_clk = ~axi_clk;   // 100 MHz
always #7 func_clk = ~func_clk; // ~71.4 MHz

reg  [ADDR_W-1:0] awaddr = 0;
reg  [2:0]        awprot = 0;
reg               awvalid = 0;
wire              awready;

reg  [31:0]       wdata = 0;
reg  [3:0]        wstrb = 0;
reg               wvalid = 0;
wire              wready;

wire [1:0]        bresp;
wire              bvalid;
reg               bready = 0;

reg  [ADDR_W-1:0] araddr = 0;
reg  [2:0]        arprot = 0;
reg               arvalid = 0;
wire              arready;

wire [31:0]       rdata;
wire [1:0]        rresp;
wire              rvalid;
reg               rready = 0;

wire irq_o;

integer errors = 0;
integer k;
reg [31:0] rd;

dual_clock_control_status_bridge_demo #(
    .C_S_AXI_ADDR_WIDTH(ADDR_W),
    .PROCESS_CYCLES(6)
) dut (
    .s_axi_aclk(axi_clk),
    .func_clk(func_clk),
    .global_resetn(global_resetn),

    .s_axi_awaddr(awaddr),
    .s_axi_awprot(awprot),
    .s_axi_awvalid(awvalid),
    .s_axi_awready(awready),

    .s_axi_wdata(wdata),
    .s_axi_wstrb(wstrb),
    .s_axi_wvalid(wvalid),
    .s_axi_wready(wready),

    .s_axi_bresp(bresp),
    .s_axi_bvalid(bvalid),
    .s_axi_bready(bready),

    .s_axi_araddr(araddr),
    .s_axi_arprot(arprot),
    .s_axi_arvalid(arvalid),
    .s_axi_arready(arready),

    .s_axi_rdata(rdata),
    .s_axi_rresp(rresp),
    .s_axi_rvalid(rvalid),
    .s_axi_rready(rready),

    .irq_o(irq_o)
);

task automatic axi_write;
    input [31:0] addr;
    input [31:0] data;
    begin
        @(negedge axi_clk);
        awaddr = addr;
        awvalid = 1'b1;

        wait (awready === 1'b1);
        @(negedge axi_clk);
        awvalid = 1'b0;

        @(negedge axi_clk);
        wdata = data;
        wstrb = 4'b1111;
        wvalid = 1'b1;

        wait (wready === 1'b1);
        @(negedge axi_clk);
        wvalid = 1'b0;

        bready = 1'b1;
        wait (bvalid === 1'b1);
        @(posedge axi_clk);
        @(negedge axi_clk);
        bready = 1'b0;
    end
endtask

task automatic axi_read;
    input [31:0] addr;
    output [31:0] data;
    begin
        @(negedge axi_clk);
        araddr = addr;
        arvalid = 1'b1;

        wait (arready === 1'b1);
        @(negedge axi_clk);
        arvalid = 1'b0;

        rready = 1'b1;
        wait (rvalid === 1'b1);
        data = rdata;

        @(posedge axi_clk);
        @(negedge axi_clk);
        rready = 1'b0;
    end
endtask

task automatic wait_output;
    begin
        rd = 32'h0;

        for (k = 0; k < 200; k = k + 1) begin
            axi_read(32'h00000008, rd);

            if (rd[2]) begin
                k = 200;
            end
        end

        if (!rd[2]) begin
            $display("FAIL: timeout waiting for OUT_PENDING");
            errors = errors + 1;
        end
    end
endtask

initial begin
    #80;
    global_resetn = 1'b1;

    // Allow both domain reset synchronizers to release.
    repeat (12) @(posedge axi_clk);

    // Mode 1, input 9 => result 10.
    axi_write(32'h00000000, 32'h00000001);
    axi_write(32'h0000000C, 32'h00000009);
    axi_write(32'h00000010, 32'h00000001);

    wait_output();

    axi_read(32'h00000014, rd);

    if (rd !== 32'h0000000A) begin
        $display("FAIL: dual-clock result=%08h expected=0000000A", rd);
        errors = errors + 1;
    end else begin
        $display("PASS: dual-clock result 9 -> 10");
    end

    axi_write(32'h00000010, 32'h00000002);

    if (errors == 0) begin
        $display("SOC20 DUAL-CLOCK BRIDGE TEST: PASS");
    end else begin
        $display("SOC20 DUAL-CLOCK BRIDGE TEST: FAIL (%0d)", errors);
    end

    #100;
    $finish;
end

endmodule
