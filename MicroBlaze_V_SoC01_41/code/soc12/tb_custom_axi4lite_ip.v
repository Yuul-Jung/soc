`timescale 1ns / 1ps

module tb_custom_axi4lite_ip;

reg clk = 1'b0;
reg resetn = 1'b0;

reg  [31:0] s_axi_awaddr = 32'h0;
reg  [2:0]  s_axi_awprot = 3'b000;
reg         s_axi_awvalid = 1'b0;
wire        s_axi_awready;

reg  [31:0] s_axi_wdata = 32'h0;
reg  [3:0]  s_axi_wstrb = 4'b0000;
reg         s_axi_wvalid = 1'b0;
wire        s_axi_wready;

wire [1:0]  s_axi_bresp;
wire        s_axi_bvalid;
reg         s_axi_bready = 1'b0;

reg  [31:0] s_axi_araddr = 32'h0;
reg  [2:0]  s_axi_arprot = 3'b000;
reg         s_axi_arvalid = 1'b0;
wire        s_axi_arready;

wire [31:0] s_axi_rdata;
wire [1:0]  s_axi_rresp;
wire        s_axi_rvalid;
reg         s_axi_rready = 1'b0;

reg         busy_i = 1'b0;
reg         done_i = 1'b0;
reg         error_i = 1'b0;
reg         irq_done_event_i = 1'b0;
reg         irq_error_event_i = 1'b0;
reg  [31:0] data_out_i = 32'h1234_5678;

wire        enable_o;
wire [1:0]  mode_o;
wire        start_pulse_o;
wire        clear_pulse_o;
wire [31:0] data_in_o;
wire [1:0]  irq_status_o;

integer errors = 0;
integer start_pulse_count = 0;
reg [31:0] read_value;
reg [31:0] held_rdata;

custom_axi4lite_ip dut (
    .s_axi_aclk(clk),
    .s_axi_aresetn(resetn),

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

always #5 clk = ~clk;

always @(posedge clk) begin
    if (start_pulse_o) begin
        start_pulse_count = start_pulse_count + 1;
    end
end

task check32;
    input [31:0] actual;
    input [31:0] expected;
    input [8*48-1:0] name;
    begin
        if (actual !== expected) begin
            $display("FAIL: %0s actual=%08X expected=%08X", name, actual, expected);
            errors = errors + 1;
        end else begin
            $display("PASS: %0s = %08X", name, actual);
        end
    end
endtask

task send_aw;
    input [31:0] addr;
    begin
        @(negedge clk);
        s_axi_awaddr  = addr;
        s_axi_awvalid = 1'b1;

        while (s_axi_awready !== 1'b1) begin
            @(negedge clk);
        end

        @(posedge clk);
        @(negedge clk);
        s_axi_awvalid = 1'b0;
    end
endtask

task send_w;
    input [31:0] data;
    input [3:0] strb;
    begin
        @(negedge clk);
        s_axi_wdata  = data;
        s_axi_wstrb  = strb;
        s_axi_wvalid = 1'b1;

        while (s_axi_wready !== 1'b1) begin
            @(negedge clk);
        end

        @(posedge clk);
        @(negedge clk);
        s_axi_wvalid = 1'b0;
        s_axi_wstrb  = 4'b0000;
    end
endtask

task wait_bresp;
    input integer hold_cycles;
    integer i;
    begin
        s_axi_bready = 1'b0;

        while (s_axi_bvalid !== 1'b1) begin
            @(negedge clk);
        end

        if (s_axi_bresp !== 2'b00) begin
            $display("FAIL: BRESP is not OKAY");
            errors = errors + 1;
        end

        // BVALID must remain asserted while BREADY is low.
        for (i = 0; i < hold_cycles; i = i + 1) begin
            @(negedge clk);
            if (s_axi_bvalid !== 1'b1) begin
                $display("FAIL: BVALID dropped before BREADY");
                errors = errors + 1;
            end
            if ((s_axi_awready !== 1'b0) || (s_axi_wready !== 1'b0)) begin
                $display("FAIL: New write accepted while B response pending");
                errors = errors + 1;
            end
        end

        s_axi_bready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        s_axi_bready = 1'b0;

        if (s_axi_bvalid !== 1'b0) begin
            $display("FAIL: BVALID did not clear after handshake");
            errors = errors + 1;
        end
    end
endtask

task axi_write_aw_first;
    input [31:0] addr;
    input [31:0] data;
    input [3:0] strb;
    begin
        send_aw(addr);
        repeat (2) @(negedge clk);
        send_w(data, strb);
        wait_bresp(2);
    end
endtask

task axi_write_w_first;
    input [31:0] addr;
    input [31:0] data;
    input [3:0] strb;
    begin
        send_w(data, strb);
        repeat (2) @(negedge clk);
        send_aw(addr);
        wait_bresp(1);
    end
endtask

task axi_write_same_cycle;
    input [31:0] addr;
    input [31:0] data;
    input [3:0] strb;
    begin
        @(negedge clk);
        s_axi_awaddr  = addr;
        s_axi_awvalid = 1'b1;
        s_axi_wdata   = data;
        s_axi_wstrb   = strb;
        s_axi_wvalid  = 1'b1;

        while ((s_axi_awready !== 1'b1) || (s_axi_wready !== 1'b1)) begin
            @(negedge clk);
        end

        @(posedge clk);
        @(negedge clk);
        s_axi_awvalid = 1'b0;
        s_axi_wvalid  = 1'b0;
        s_axi_wstrb   = 4'b0000;

        wait_bresp(0);
    end
endtask

task axi_read;
    input [31:0] addr;
    input integer hold_cycles;
    output [31:0] data;
    integer i;
    begin
        @(negedge clk);
        s_axi_araddr  = addr;
        s_axi_arvalid = 1'b1;
        s_axi_rready  = 1'b0;

        while (s_axi_arready !== 1'b1) begin
            @(negedge clk);
        end

        @(posedge clk);
        @(negedge clk);
        s_axi_arvalid = 1'b0;

        while (s_axi_rvalid !== 1'b1) begin
            @(negedge clk);
        end

        held_rdata = s_axi_rdata;
        data = s_axi_rdata;

        if (s_axi_rresp !== 2'b00) begin
            $display("FAIL: RRESP is not OKAY");
            errors = errors + 1;
        end

        // RVALID and RDATA must remain stable while RREADY is low.
        for (i = 0; i < hold_cycles; i = i + 1) begin
            @(negedge clk);
            if (s_axi_rvalid !== 1'b1) begin
                $display("FAIL: RVALID dropped before RREADY");
                errors = errors + 1;
            end
            if (s_axi_rdata !== held_rdata) begin
                $display("FAIL: RDATA changed while waiting for RREADY");
                errors = errors + 1;
            end
            if (s_axi_arready !== 1'b0) begin
                $display("FAIL: New read accepted while R response pending");
                errors = errors + 1;
            end
        end

        s_axi_rready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        s_axi_rready = 1'b0;

        if (s_axi_rvalid !== 1'b0) begin
            $display("FAIL: RVALID did not clear after handshake");
            errors = errors + 1;
        end
    end
endtask

initial begin
    $display("=== SoC 12 AXI4-Lite self-checking test start ===");

    repeat (3) @(negedge clk);
    resetn = 1'b1;
    repeat (2) @(negedge clk);

    // Reset / fixed-value reads.
    axi_read(32'h0000_0000, 2, read_value);
    check32(read_value, 32'h0000_0000, "CONTROL reset");

    axi_read(32'h0000_0018, 0, read_value);
    check32(read_value, 32'h0001_0000, "VERSION");

    axi_read(32'h0000_001C, 0, read_value);
    check32(read_value, 32'h524D_4150, "ID");

    // AW arrives first: CONTROL = enable 1, mode 2'b10 -> 0x5.
    axi_write_aw_first(32'h0000_0000, 32'h0000_0005, 4'b0001);
    axi_read(32'h0000_0000, 1, read_value);
    check32(read_value, 32'h0000_0005, "AW-first CONTROL write");

    // W arrives first: full DATA_IN write.
    axi_write_w_first(32'h0000_0010, 32'h1122_3344, 4'b1111);
    axi_read(32'h0000_0010, 0, read_value);
    check32(read_value, 32'h1122_3344, "W-first DATA_IN write");

    // Partial-byte write proves WSTRB reaches the existing register bank.
    axi_write_same_cycle(32'h0000_0010, 32'h0000_00AA, 4'b0001);
    axi_read(32'h0000_0010, 0, read_value);
    check32(read_value, 32'h1122_33AA, "WSTRB low-byte update");

    // W1P command: exactly one start pulse.
    start_pulse_count = 0;
    axi_write_same_cycle(32'h0000_0008, 32'h0000_0001, 4'b0001);
    repeat (3) @(negedge clk);
    check32(start_pulse_count, 32'h0000_0001, "COMMAND start pulse count");

    // Hardware status read.
    busy_i  = 1'b1;
    done_i  = 1'b0;
    error_i = 1'b1;
    axi_read(32'h0000_0004, 0, read_value);
    check32(read_value, 32'h0000_0005, "STATUS read");

    // Hardware event sets IRQ_STATUS bit0.
    @(negedge clk);
    irq_done_event_i = 1'b1;
    @(negedge clk);
    irq_done_event_i = 1'b0;
    axi_read(32'h0000_000C, 0, read_value);
    check32(read_value, 32'h0000_0001, "IRQ event set");

    // W1C clears IRQ_STATUS bit0.
    axi_write_same_cycle(32'h0000_000C, 32'h0000_0001, 4'b0001);
    axi_read(32'h0000_000C, 0, read_value);
    check32(read_value, 32'h0000_0000, "IRQ W1C clear");

    // Read-only hardware data.
    axi_read(32'h0000_0014, 2, read_value);
    check32(read_value, 32'h1234_5678, "DATA_OUT read");

    if (errors == 0) begin
        $display("=== PASS: SoC 12 AXI4-Lite self-checking test ===");
    end else begin
        $display("=== FAIL: %0d error(s) ===", errors);
    end

    $finish;
end

endmodule
