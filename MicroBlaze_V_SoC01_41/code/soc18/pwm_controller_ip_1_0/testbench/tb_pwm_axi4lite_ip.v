`timescale 1ns / 1ps

module tb_pwm_axi4lite_ip;

localparam integer ADDR_W = 32;

reg clk = 1'b0;
reg resetn = 1'b0;

always #5 clk = ~clk;

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

wire pwm_o;

integer errors = 0;
reg [31:0] rd;

pwm_axi4lite_ip #(
    .C_S_AXI_ADDR_WIDTH(ADDR_W)
) dut (
    .s_axi_aclk(clk),
    .s_axi_aresetn(resetn),

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

    .pwm_o(pwm_o)
);

task automatic axi_write;
    input [31:0] addr;
    input [31:0] data;
    begin
        @(negedge clk);
        awaddr = addr;
        awvalid = 1'b1;

        wait (awready === 1'b1);
        @(negedge clk);
        awvalid = 1'b0;

        @(negedge clk);
        wdata = data;
        wstrb = 4'b1111;
        wvalid = 1'b1;

        wait (wready === 1'b1);
        @(negedge clk);
        wvalid = 1'b0;

        bready = 1'b1;
        wait (bvalid === 1'b1);
        @(posedge clk);
        @(negedge clk);
        bready = 1'b0;
    end
endtask

task automatic axi_read;
    input [31:0] addr;
    output [31:0] data;
    begin
        @(negedge clk);
        araddr = addr;
        arvalid = 1'b1;

        wait (arready === 1'b1);
        @(negedge clk);
        arvalid = 1'b0;

        rready = 1'b1;
        wait (rvalid === 1'b1);
        data = rdata;

        @(posedge clk);
        @(negedge clk);
        rready = 1'b0;
    end
endtask

task automatic expect32;
    input [31:0] actual;
    input [31:0] expected;
    input [8*48-1:0] label;
    begin
        if (actual !== expected) begin
            $display("FAIL: %0s actual=%08h expected=%08h",
                     label, actual, expected);
            errors = errors + 1;
        end else begin
            $display("PASS: %0s = %08h", label, actual);
        end
    end
endtask

initial begin
    repeat (5) @(posedge clk);
    resetn = 1'b1;
    repeat (3) @(posedge clk);

    axi_read(32'h0000001C, rd);
    expect32(rd, 32'h50574D31, "PWM ID");

    // Shadow write only: active values must remain reset defaults.
    axi_write(32'h00000000, 32'h00000001);
    axi_write(32'h00000004, 32'd8);
    axi_write(32'h00000008, 32'd2);

    axi_read(32'h00000014, rd);
    expect32(rd, 32'd1000, "Active period before UPDATE");

    axi_read(32'h00000018, rd);
    expect32(rd, 32'd500, "Active duty before UPDATE");

    // Atomic apply.
    axi_write(32'h0000000C, 32'h00000001);

    axi_read(32'h00000014, rd);
    expect32(rd, 32'd8, "Active period after UPDATE");

    axi_read(32'h00000018, rd);
    expect32(rd, 32'd2, "Active duty after UPDATE");

    axi_read(32'h00000010, rd);
    if (!rd[0] || rd[1]) begin
        $display("FAIL: PWM active status");
        errors = errors + 1;
    end else begin
        $display("PASS: PWM active status");
    end

    // Invalid new shadow values: duty > period.
    axi_write(32'h00000004, 32'd4);
    axi_write(32'h00000008, 32'd5);
    axi_write(32'h0000000C, 32'h00000001);

    axi_read(32'h00000010, rd);
    if (!rd[1]) begin
        $display("FAIL: invalid PWM config should set ERROR");
        errors = errors + 1;
    end else begin
        $display("PASS: invalid PWM config ERROR");
    end

    // Active configuration must remain unchanged after rejected UPDATE.
    axi_read(32'h00000014, rd);
    expect32(rd, 32'd8, "Active period preserved");

    axi_read(32'h00000018, rd);
    expect32(rd, 32'd2, "Active duty preserved");

    // Clear only the error.
    axi_write(32'h0000000C, 32'h00000002);
    axi_read(32'h00000010, rd);

    if (rd[1]) begin
        $display("FAIL: PWM ERROR clear");
        errors = errors + 1;
    end else begin
        $display("PASS: PWM ERROR clear");
    end

    if (errors == 0) begin
        $display("SOC18 PWM AXI IP TEST: PASS");
    end else begin
        $display("SOC18 PWM AXI IP TEST: FAIL (%0d)", errors);
    end

    #40;
    $finish;
end

endmodule
