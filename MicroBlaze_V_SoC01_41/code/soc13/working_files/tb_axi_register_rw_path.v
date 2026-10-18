`timescale 1ns / 1ps

module tb_axi_register_rw_path;

localparam integer ADDR_W = 32;

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

reg               busy_i;
reg               done_i;
reg               error_i;
reg               irq_done_event_i;
reg               irq_error_event_i;
reg  [31:0]       data_out_i;

wire              enable_o;
wire [1:0]        mode_o;
wire              start_pulse_o;
wire              clear_pulse_o;
wire [31:0]       data_in_o;
wire [1:0]        irq_status_o;

integer error_count = 0;

custom_axi4lite_ip #(
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

        /* W channel intentionally arrives later than AW. */
        repeat (2) @(negedge clk);

        wdata  = data;
        wstrb  = strb;
        wvalid = 1'b1;

        wait (wready === 1'b1);
        @(negedge clk);
        wvalid = 1'b0;

        /* Hold BREADY low to prove BVALID remains asserted. */
        bready = 1'b0;
        wait (bvalid === 1'b1);
        repeat (2) @(posedge clk);

        if (bvalid !== 1'b1) begin
            $display("FAIL: BVALID did not hold during backpressure");
            error_count = error_count + 1;
        end

        @(negedge clk);
        bready = 1'b1;
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

        rready = 1'b0;
        wait (rvalid === 1'b1);

        /* RDATA must remain stable while RREADY is low. */
        data = rdata;
        repeat (2) @(posedge clk);

        if (rdata !== data) begin
            $display("FAIL: RDATA changed while RREADY=0");
            error_count = error_count + 1;
        end

        @(negedge clk);
        rready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        rready = 1'b0;
    end
endtask

reg [31:0] rd;

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

    busy_i = 0;
    done_i = 0;
    error_i = 0;
    irq_done_event_i = 0;
    irq_error_event_i = 0;
    data_out_i = 32'h00000000;

    repeat (4) @(posedge clk);
    resetn = 1'b1;
    repeat (2) @(posedge clk);

    $display("---- WRITE PATH: CONTROL ----");
    axi_write(32'h00000000, 32'h00000005, 4'b1111);
    expect32({29'h0, mode_o, enable_o}, 32'h00000005,
             "CONTROL hardware output");

    $display("---- READ PATH: CONTROL ----");
    axi_read(32'h00000000, rd);
    expect32(rd, 32'h00000005, "CONTROL readback");

    $display("---- WRITE/READ PATH: DATA_IN ----");
    axi_write(32'h00000010, 32'h12345678, 4'b1111);
    expect32(data_in_o, 32'h12345678, "DATA_IN hardware output");

    axi_read(32'h00000010, rd);
    expect32(rd, 32'h12345678, "DATA_IN readback");

    $display("---- READ PATH: STATUS ----");
    busy_i  = 1'b1;
    done_i  = 1'b1;
    error_i = 1'b0;

    axi_read(32'h00000004, rd);
    expect32(rd, 32'h00000003, "STATUS read");

    $display("---- READ PATH: DATA_OUT ----");
    data_out_i = 32'hCAFE1234;
    axi_read(32'h00000014, rd);
    expect32(rd, 32'hCAFE1234, "DATA_OUT read");

    $display("---- WRITE PATH: COMMAND W1P ----");
    fork
        begin
            axi_write(32'h00000008, 32'h00000001, 4'b0001);
        end
        begin
            wait (start_pulse_o === 1'b1);
            @(posedge clk);
            // (추가) 비차단 대입이 반영된 뒤 펄스 해제를 확인한다.
            #1;
            if (start_pulse_o !== 1'b0) begin
                $display("FAIL: start_pulse_o wider than one clock");
                error_count = error_count + 1;
            end else begin
                $display("PASS: start_pulse_o one clock");
            end
        end
    join

    $display("---- W1C PATH: IRQ_STATUS ----");
    @(negedge clk);
    irq_done_event_i = 1'b1;
    @(posedge clk);
    @(negedge clk);
    irq_done_event_i = 1'b0;

    axi_read(32'h0000000C, rd);
    expect32(rd, 32'h00000001, "IRQ_STATUS set");

    axi_write(32'h0000000C, 32'h00000001, 4'b0001);
    axi_read(32'h0000000C, rd);
    expect32(rd, 32'h00000000, "IRQ_STATUS cleared");

    $display("---- FIXED RO REGISTERS ----");
    axi_read(32'h00000018, rd);
    expect32(rd, 32'h00010000, "VERSION");

    axi_read(32'h0000001C, rd);
    expect32(rd, 32'h524D4150, "ID");

    if (error_count == 0) begin
        $display("SOC13 REGISTER R/W PATH TEST: PASS");
    end else begin
        $display("SOC13 REGISTER R/W PATH TEST: FAIL (%0d errors)",
                 error_count);
    end

    #50;
    $finish;
end

endmodule
