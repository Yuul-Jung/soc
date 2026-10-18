`timescale 1ns / 1ps

module tb_custom_axi4lite_controller_ip;

localparam integer ADDR_W = 32;
localparam integer PROCESS_CYCLES_TB = 12;

reg clk = 1'b0;
reg resetn = 1'b0;

always #5 clk = ~clk;

reg  [ADDR_W-1:0] awaddr;
reg  [2:0]        awprot;
reg               awvalid;
wire              awready;

reg  [31:0]       wdata;
reg  [3:0]        wstrb;
reg               wvalid;
wire              wready;

wire [1:0]        bresp;
wire              bvalid;
reg               bready;

reg  [ADDR_W-1:0] araddr;
reg  [2:0]        arprot;
reg               arvalid;
wire              arready;

wire [31:0]       rdata;
wire [1:0]        rresp;
wire              rvalid;
reg               rready;

integer error_count = 0;
reg [31:0] rd;

custom_axi4lite_controller_ip #(
    .C_S_AXI_ADDR_WIDTH(ADDR_W),
    .PROCESS_CYCLES(PROCESS_CYCLES_TB)
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
    .s_axi_rready(rready)
);

task automatic expect32;
    input [31:0] actual;
    input [31:0] expected;
    input [8*48-1:0] label;
    begin
        if (actual !== expected) begin
            $display("FAIL: %0s actual=%08h expected=%08h",
                     label, actual, expected);
            error_count = error_count + 1;
        end else begin
            $display("PASS: %0s = %08h", label, actual);
        end
    end
endtask

task automatic axi_write;
    input [31:0] addr;
    input [31:0] data;
    input [3:0]  strb;
    begin
        @(negedge clk);
        awaddr  = addr;
        awvalid = 1'b1;

        wait (awready === 1'b1);
        @(negedge clk);
        awvalid = 1'b0;

        @(negedge clk);
        wdata  = data;
        wstrb  = strb;
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
    input  [31:0] addr;
    output [31:0] data;
    begin
        @(negedge clk);
        araddr  = addr;
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

task automatic clear_status_and_irq;
    begin
        axi_write(32'h00000008, 32'h00000002, 4'b0001);
        axi_write(32'h0000000C, 32'h00000003, 4'b0001);
    end
endtask

task automatic wait_done;
    output [31:0] status_value;
    integer k;
    reg found;
    begin
        status_value = 32'h0;
        found = 1'b0;

        for (k = 0; k < 100; k = k + 1) begin
            axi_read(32'h00000004, status_value);

            if (status_value[1]) begin
                found = 1'b1;
                k = 100;
            end
        end

        if (!found) begin
            $display("FAIL: timeout waiting for DONE");
            error_count = error_count + 1;
        end
    end
endtask

task automatic run_mode_test;
    input [1:0]  mode;
    input [31:0] input_value;
    input [31:0] expected_value;
    reg [31:0] status_value;
    reg [31:0] control_value;
    begin
        clear_status_and_irq();

        control_value = 32'h00000001 | ({30'h0, mode} << 1);
        axi_write(32'h00000000, control_value, 4'b1111);
        axi_write(32'h00000010, input_value, 4'b1111);
        axi_write(32'h00000008, 32'h00000001, 4'b0001);

        wait_done(status_value);

        if (!status_value[1] || status_value[0]) begin
            $display("FAIL: final STATUS expected DONE=1 BUSY=0");
            error_count = error_count + 1;
        end

        axi_read(32'h00000014, rd);
        expect32(rd, expected_value, "DATA_OUT result");

        axi_read(32'h0000000C, rd);
        if ((rd & 32'h00000001) == 0) begin
            $display("FAIL: DONE IRQ status not latched");
            error_count = error_count + 1;
        end else begin
            $display("PASS: DONE IRQ status latched");
        end
    end
endtask

initial begin
    awaddr = 0;
    awprot = 0;
    awvalid = 0;
    wdata = 0;
    wstrb = 0;
    wvalid = 0;
    bready = 0;

    araddr = 0;
    arprot = 0;
    arvalid = 0;
    rready = 0;

    repeat (5) @(posedge clk);
    resetn = 1'b1;
    repeat (3) @(posedge clk);

    $display("---- FIXED REGISTERS ----");
    axi_read(32'h00000018, rd);
    expect32(rd, 32'h00010000, "VERSION");

    axi_read(32'h0000001C, rd);
    expect32(rd, 32'h524D4150, "ID");

    $display("---- DISABLED START -> ERROR ----");
    axi_write(32'h00000008, 32'h00000001, 4'b0001);
    repeat (3) @(posedge clk);

    axi_read(32'h00000004, rd);
    if ((rd & 32'h00000004) == 0) begin
        $display("FAIL: STATUS.ERROR not set");
        error_count = error_count + 1;
    end else begin
        $display("PASS: STATUS.ERROR set");
    end

    axi_read(32'h0000000C, rd);
    if ((rd & 32'h00000002) == 0) begin
        $display("FAIL: IRQ_STATUS.ERROR not set");
        error_count = error_count + 1;
    end else begin
        $display("PASS: IRQ_STATUS.ERROR set");
    end

    $display("---- CLEAR STATUS ONLY ----");
    axi_write(32'h00000008, 32'h00000002, 4'b0001);
    axi_read(32'h00000004, rd);
    expect32(rd, 32'h00000000, "STATUS after COMMAND.CLEAR");

    axi_read(32'h0000000C, rd);
    expect32(rd, 32'h00000002, "IRQ_STATUS remains latched");

    axi_write(32'h0000000C, 32'h00000002, 4'b0001);
    axi_read(32'h0000000C, rd);
    expect32(rd, 32'h00000000, "IRQ_STATUS W1C clear");

    $display("---- MODE 0 PASS-THROUGH ----");
    run_mode_test(2'b00, 32'h12345678, 32'h12345678);

    $display("---- MODE 1 ADD 1 ----");
    run_mode_test(2'b01, 32'hFFFFFFFF, 32'h00000000);

    $display("---- MODE 2 SHIFT LEFT ----");
    run_mode_test(2'b10, 32'h80000001, 32'h00000002);

    $display("---- MODE 3 BITWISE NOT ----");
    run_mode_test(2'b11, 32'hA5A55A5A, 32'h5A5AA5A5);

    $display("---- START WHILE BUSY -> ERROR ----");
    clear_status_and_irq();

    // Enable, mode 0, data input.
    axi_write(32'h00000000, 32'h00000001, 4'b1111);
    axi_write(32'h00000010, 32'hCAFEBABE, 4'b1111);

    // First START launches the operation.
    axi_write(32'h00000008, 32'h00000001, 4'b0001);

    // Second START arrives before PROCESS_CYCLES_TB expires.
    axi_write(32'h00000008, 32'h00000001, 4'b0001);

    wait_done(rd);

    axi_read(32'h00000004, rd);
    if ((rd & 32'h00000004) == 0) begin
        $display("FAIL: busy restart ERROR not retained");
        error_count = error_count + 1;
    end else begin
        $display("PASS: busy restart ERROR retained");
    end

    axi_read(32'h00000014, rd);
    expect32(rd, 32'hCAFEBABE, "original operation still completed");

    axi_read(32'h0000000C, rd);
    if ((rd & 32'h00000003) != 32'h00000003) begin
        $display("FAIL: DONE+ERROR IRQ status expected");
        error_count = error_count + 1;
    end else begin
        $display("PASS: DONE+ERROR IRQ status latched");
    end

    if (error_count == 0) begin
        $display("SOC14 REGISTER BANK + CONTROLLER TEST: PASS");
    end else begin
        $display("SOC14 REGISTER BANK + CONTROLLER TEST: FAIL (%0d errors)",
                 error_count);
    end

    #50;
    $finish;
end

endmodule
