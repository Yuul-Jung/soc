`timescale 1ns / 1ps

module tb_axi_control_status_bridge_demo_top;

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

wire irq_o;

integer errors = 0;
integer k;
reg [31:0] rd;

axi_control_status_bridge_demo_top #(
    .C_S_AXI_ADDR_WIDTH(ADDR_W),
    .PROCESS_CYCLES(6)
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

    .irq_o(irq_o)
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
    input [8*64-1:0] label;
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

task automatic wait_out_pending;
    begin
        rd = 0;

        for (k = 0; k < 100; k = k + 1) begin
            axi_read(32'h00000008, rd);

            if (rd[2]) begin
                k = 100;
            end
        end

        if (!rd[2]) begin
            $display("FAIL: timeout waiting for OUT_PENDING");
            errors = errors + 1;
        end
    end
endtask

initial begin
    repeat (5) @(posedge clk);
    resetn = 1'b1;
    repeat (3) @(posedge clk);

    // Identification
    axi_read(32'h00000020, rd);
    expect32(rd, 32'h43534231, "CSB ID");

    axi_read(32'h0000001C, rd);
    expect32(rd, 32'h00010000, "CSB VERSION");

    // Mode 1: add 1
    axi_write(32'h00000000, 32'h00000001);
    axi_write(32'h0000000C, 32'h00000009);
    axi_write(32'h00000010, 32'h00000001);

    wait_out_pending();

    axi_read(32'h00000014, rd);
    expect32(rd, 32'h0000000A, "First output");

    axi_read(32'h00000018, rd);
    if ((rd & 32'h00000003) != 32'h00000003) begin
        $display("FAIL: IN_ACCEPTED and OUT_CAPTURED events expected");
        errors = errors + 1;
    end else begin
        $display("PASS: input/output events latched");
    end

    if (!irq_o) begin
        $display("FAIL: irq_o should be high while events are pending");
        errors = errors + 1;
    end

    // Queue a second input while first output is still pending.
    axi_write(32'h0000000C, 32'h00000003);
    axi_write(32'h00000010, 32'h00000001);

    // (변경) Core가 두 번째 입력을 수락한 뒤 출력에서 정지할 때까지 기다린다.
    // 첫 결과는 Bridge 출력 버퍼, 두 번째 결과는 Core에 보관된다.
    repeat (12) @(negedge clk);

    // (추가) 세 번째 입력을 Bridge 입력 버퍼에 대기시킨다.
    axi_write(32'h0000000C, 32'h00000007);
    axi_write(32'h00000010, 32'h00000001);

    // (변경) 네 번째 SUBMIT은 이미 대기 중인 세 번째 입력 때문에 거부된다.
    axi_write(32'h0000000C, 32'h00000007);
    axi_write(32'h00000010, 32'h00000001);

    axi_read(32'h00000008, rd);
    if (!rd[3]) begin
        $display("FAIL: bridge error expected after submit while pending");
        errors = errors + 1;
    end else begin
        $display("PASS: submit while pending sets bridge error");
    end

    // Release first output.
    axi_write(32'h00000010, 32'h00000002);

    // Clear bridge error/event, then allow queued second request to complete.
    axi_write(32'h00000010, 32'h00000004);
    axi_write(32'h00000018, 32'h00000007);

    wait_out_pending();

    axi_read(32'h00000014, rd);
    expect32(rd, 32'h00000004, "Queued second output");

    // POP second result.
    axi_write(32'h00000010, 32'h00000002);
    // (추가) 세 번째 요청도 보관되므로 마지막 결과를 먼저 회수한다.
    wait_out_pending();
    axi_read(32'h00000014, rd);
    expect32(rd, 32'h00000008, "Queued third output");
    axi_write(32'h00000010, 32'h00000002);

    // (변경) 모든 수락된 결과를 POP한 뒤 Empty를 검사한다.
    axi_read(32'h00000008, rd);

    if (rd[2]) begin
        $display("FAIL: OUT_PENDING should clear after POP");
        errors = errors + 1;
    end else begin
        $display("PASS: OUT_PENDING cleared");
    end

    // POP on empty output buffer must set ERROR.
    axi_write(32'h00000010, 32'h00000002);
    axi_read(32'h00000008, rd);

    if (!rd[3]) begin
        $display("FAIL: POP on empty buffer should set ERROR");
        errors = errors + 1;
    end else begin
        $display("PASS: empty POP sets ERROR");
    end

    if (errors == 0) begin
        $display("SOC19 AXI CONTROL/STATUS BRIDGE TEST: PASS");
    end else begin
        $display("SOC19 AXI CONTROL/STATUS BRIDGE TEST: FAIL (%0d)",
                 errors);
    end

    #50;
    $finish;
end

endmodule
