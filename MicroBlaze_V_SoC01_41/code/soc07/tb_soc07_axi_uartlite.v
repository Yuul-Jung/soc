`timescale 1ns / 1ps

// SoC 07: Verilog-2001 self-checking AXI UART Lite IP testbench.
// Reference: AMD PG142 Figure 5-1 (example) and Figure 6-1 (test bench).
// (변경) VHDL exdes 대신 AXI-Lite BFM으로 실제 Xilinx UART Lite IP 직접 구동.
// (추가) 공식 TX 'A'(0x41) 검사 외에 RX 'B'(0x42)와 Echo를 검증.
// DUT: independent Vivado IP Catalog "axi_uartlite_0" (100 MHz, 115200 8N1).
// Not a complete MicroBlaze V software / Basys3 hardware simulation.

module tb_soc07_axi_uartlite;
  localparam integer CLOCK_NS = 10;
  localparam integer BAUD = 115200;
  localparam integer BIT_NS = (1000000000 + BAUD/2) / BAUD;
  reg clk = 0;
  always #(CLOCK_NS/2) clk = ~clk;
  reg resetn = 0;
  reg rx = 1;
  wire tx, interrupt;

  reg [3:0] awaddr = 0, araddr = 0;
  reg [31:0] wdata = 0;
  reg [3:0] wstrb = 4'hF;
  reg awvalid = 0, wvalid = 0, bready = 0;
  reg arvalid = 0, rready = 0;
  wire awready, wready, bvalid, arready, rvalid;
  wire [1:0] bresp, rresp;
  wire [31:0] rdata;

  // Generate Output Products for this IP in Vivado before simulation.
  axi_uartlite_0 dut (
    .s_axi_aclk(clk), .s_axi_aresetn(resetn),
    .s_axi_awaddr(awaddr), .s_axi_awvalid(awvalid), .s_axi_awready(awready),
    .s_axi_wdata(wdata), .s_axi_wstrb(wstrb),
    .s_axi_wvalid(wvalid), .s_axi_wready(wready),
    .s_axi_bresp(bresp), .s_axi_bvalid(bvalid), .s_axi_bready(bready),
    .s_axi_araddr(araddr), .s_axi_arvalid(arvalid), .s_axi_arready(arready),
    .s_axi_rdata(rdata), .s_axi_rresp(rresp),
    .s_axi_rvalid(rvalid), .s_axi_rready(rready),
    .rx(rx), .tx(tx), .interrupt(interrupt)
  );

  // AXI4-Lite write: AW and W VALID asserted simultaneously.
  // VALID is held until each channel's READY handshake.
  task axi_write;
    input [3:0] address;
    input [31:0] value;
    reg got_aw, got_w;
    begin
      @(negedge clk);
      awaddr=address; wdata=value;
      awvalid=1; wvalid=1; bready=0;
      got_aw=0; got_w=0;
      while (!got_aw || !got_w) begin
        @(posedge clk);
        if (awvalid && awready) got_aw=1;
        if (wvalid && wready) got_w=1;
        @(negedge clk);
        if (got_aw) awvalid=0;
        if (got_w) wvalid=0;
      end
      wait(bvalid === 1'b1);
      if (bresp !== 2'b00) begin
        $display("TEST FAILED AXI WRITE address=%h bresp=%b", address,bresp);
        $stop;
      end
      @(negedge clk); bready=1;
      @(posedge clk);
      @(negedge clk); bready=0;
    end
  endtask

  task axi_read;
    input [3:0] address;
    output [31:0] value;
    begin
      @(negedge clk);
      araddr=address; arvalid=1; rready=0;
      begin : await_ar
        forever begin
          @(posedge clk);
          if (arvalid && arready) disable await_ar;
        end
      end
      @(negedge clk); arvalid=0;
      wait(rvalid === 1'b1);
      if (rresp !== 2'b00) begin
        $display("TEST FAILED AXI READ address=%h rresp=%b",address,rresp);
        $stop;
      end
      value=rdata;
      @(negedge clk); rready=1;
      @(posedge clk);
      @(negedge clk); rready=0;
    end
  endtask

  // Send a PC-originated 8N1 frame into the UART Lite RX pin.
  task uart_send;
    input [7:0] value;
    integer k;
    begin
      @(negedge clk); rx=0; #(BIT_NS);
      for (k=0;k<8;k=k+1) begin rx=value[k]; #(BIT_NS); end
      rx=1; #(BIT_NS);
    end
  endtask

  // Sample DUT TX at each data-bit center: LSB first, then stop bit.
  task uart_expect;
    input [7:0] expected;
    reg [7:0] actual;
    integer k;
    begin
      @(negedge tx);
      #(BIT_NS + BIT_NS/2);
      for (k=0;k<8;k=k+1) begin
        actual[k]=tx; #(BIT_NS);
      end
      if (tx !== 1'b1 || actual !== expected) begin
        $display("TEST FAILED UART expected=%h actual=%h stop=%b",
                 expected,actual,tx);
        $stop;
      end
      $display("PASS UART TX = %h",actual);
    end
  endtask

  reg [31:0] status, data;
  reg rx_valid;
  integer i;
  initial begin
    $display("SoC07 AXI UART Lite Verilog testbench start");
    repeat(20) @(posedge clk);
    @(negedge clk); resetn=1;
    repeat(20) @(posedge clk);

    // CTRL_REG (+0x0C): reset RX FIFO and TX FIFO, interrupts disabled.
    axi_write(4'hC,32'h00000003);

    // PG142 Figure 6-1's ASCII 'A' UART TX objective.
    fork
      axi_write(4'h4,32'h00000041);
      uart_expect(8'h41);
    join

    // Extension: receive a serial 'B' and check RX FIFO through AXI.
    uart_send(8'h42);
    rx_valid=0;
    begin : poll_rx
      for (i=0;i<100;i=i+1) begin
        axi_read(4'h8,status);  // STATUS bit0: RX FIFO valid
        if (status[0] === 1'b1) begin
          rx_valid=1;
          disable poll_rx;
        end
      end
    end
    if (!rx_valid) begin
      $display("TEST FAILED RX FIFO timeout");
      $stop;
    end
    axi_read(4'h0,data);
    if (data[7:0] !== 8'h42) begin
      $display("TEST FAILED RX FIFO data=%h",data[7:0]);
      $stop;
    end
    $display("PASS UART RX = %h",data[7:0]);

    // Software-equivalent Echo by writing received byte into TX FIFO.
    fork
      axi_write(4'h4,data);
      uart_expect(8'h42);
    join
    $display("SOC07 VERILOG UARTLITE SELF-CHECK PASS");
    $finish;
  end

  initial begin
    #2000000;
    $display("TEST FAILED GLOBAL TIMEOUT");
    $stop;
  end
endmodule