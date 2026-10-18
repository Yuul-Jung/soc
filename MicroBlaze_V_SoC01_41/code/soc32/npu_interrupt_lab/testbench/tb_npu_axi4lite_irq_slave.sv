`timescale 1ns / 1ps

module tb_npu_axi4lite_irq_slave;

logic clk = 1'b0;
logic resetn = 1'b0;

logic [7:0]  awaddr = 8'h00;
logic        awvalid = 1'b0;
wire         awready;

logic [31:0] wdata = 32'h0000_0000;
logic [3:0]  wstrb = 4'h0;
logic        wvalid = 1'b0;
wire         wready;

wire [1:0]   bresp;
wire         bvalid;
logic        bready = 1'b1;

logic [7:0]  araddr = 8'h00;
logic        arvalid = 1'b0;
wire         arready;

wire [31:0]  rdata;
wire [1:0]   rresp;
wire         rvalid;
logic        rready = 1'b1;

wire accel_busy;
wire accel_done_sticky;
wire accel_error_sticky;
wire [7:0] saturation_count;
wire irq;

integer error_count = 0;
integer check_count = 0;

always #5 clk = ~clk;

npu_axi4lite_irq_slave dut (
    .s_axi_aclk(clk),
    .s_axi_aresetn(resetn),

    .s_axi_awaddr(awaddr),
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
    .s_axi_arvalid(arvalid),
    .s_axi_arready(arready),

    .s_axi_rdata(rdata),
    .s_axi_rresp(rresp),
    .s_axi_rvalid(rvalid),
    .s_axi_rready(rready),

    .irq_o(irq),

    .accel_busy_o(accel_busy),
    .accel_done_sticky_o(accel_done_sticky),
    .accel_error_sticky_o(accel_error_sticky),
    .saturation_count_o(saturation_count)
);

task automatic check_true(
    input string name,
    input bit condition
);
    begin
        check_count = check_count + 1;

        if (!condition) begin
            error_count = error_count + 1;
            $error("CHECK FAIL: %s", name);
        end else begin
            $display("CHECK PASS: %s", name);
        end
    end
endtask

task automatic check_eq32(
    input string name,
    input logic [31:0] actual,
    input logic [31:0] expected
);
    begin
        check_count = check_count + 1;

        if (actual !== expected) begin
            error_count = error_count + 1;

            $error(
                "CHECK FAIL: %s actual=0x%08h expected=0x%08h",
                name,
                actual,
                expected
            );
        end else begin
            $display(
                "CHECK PASS: %s = 0x%08h",
                name,
                actual
            );
        end
    end
endtask

// order:
//   0 = AW and W together
//   1 = AW first, W later
//   2 = W first, AW later
task automatic axi_write(
    input [7:0] address,
    input [31:0] data,
    input [3:0] strobe,
    input integer order
);
    bit aw_done;
    bit w_done;
    integer timeout;

    begin
        aw_done = 0;
        w_done = 0;

        @(negedge clk);

        awaddr = address;
        wdata = data;
        wstrb = strobe;

        case (order)
            0: begin
                awvalid = 1'b1;
                wvalid = 1'b1;
            end

            1: begin
                awvalid = 1'b1;
                wvalid = 1'b0;
            end

            default: begin
                awvalid = 1'b0;
                wvalid = 1'b1;
            end
        endcase

        timeout = 0;

        while (!(aw_done && w_done)) begin
            @(posedge clk);
            // (변경) READY가 갱신되기 전 상승 에지의 handshake를 관측한다.

            if (
                awvalid &&
                awready
            ) begin
                aw_done = 1;
            end

            if (
                wvalid &&
                wready
            ) begin
                w_done = 1;
            end

            @(negedge clk);

            if (aw_done) begin
                awvalid = 1'b0;
            end

            if (w_done) begin
                wvalid = 1'b0;
            end

            if (
                (order == 1) &&
                aw_done &&
                !w_done
            ) begin
                wvalid = 1'b1;
            end

            if (
                (order == 2) &&
                w_done &&
                !aw_done
            ) begin
                awvalid = 1'b1;
            end

            timeout = timeout + 1;

            if (timeout > 30) begin
                $fatal(1, "AXI write handshake timeout");
            end
        end

        timeout = 0;

        while (!bvalid) begin
            @(posedge clk);
            #1;

            timeout = timeout + 1;

            if (timeout > 30) begin
                $fatal(1, "AXI BVALID timeout");
            end
        end

        check_true(
            "AXI BRESP OKAY",
            bresp == 2'b00
        );

        // One extra clock ensures the B-channel handshake is complete.
        @(posedge clk);
        #1;
    end
endtask

task automatic axi_read(
    input [7:0] address,
    output [31:0] data
);
    integer timeout;

    begin
        @(negedge clk);

        araddr = address;
        arvalid = 1'b1;

        timeout = 0;

        while (!arready) begin
            @(posedge clk);
            #1;

            timeout = timeout + 1;

            if (timeout > 30) begin
                $fatal(1, "AXI ARREADY timeout");
            end
        end

        @(posedge clk);
        #1;

        if (!rvalid) begin
            timeout = 0;

            while (!rvalid) begin
                @(posedge clk);
                #1;

                timeout = timeout + 1;

                if (timeout > 30) begin
                    $fatal(1, "AXI RVALID timeout");
                end
            end
        end

        data = rdata;

        check_true(
            "AXI RRESP OKAY",
            rresp == 2'b00
        );

        @(negedge clk);
        arvalid = 1'b0;

        @(posedge clk);
        #1;
    end
endtask

task automatic wait_busy;
    reg [31:0] status;
    integer timeout;

    begin
        timeout = 0;
        status = 32'd0;

        while ((status & 32'h1) == 0) begin
            axi_read(8'h04, status);

            timeout = timeout + 1;

            if (timeout > 20) begin
                $fatal(1, "BUSY did not assert");
            end
        end
    end
endtask

task automatic wait_done;
    reg [31:0] status;
    integer timeout;

    begin
        timeout = 0;
        status = 32'd0;

        while ((status & 32'h2) == 0) begin
            axi_read(8'h04, status);

            timeout = timeout + 1;

            if (timeout > 50) begin
                $fatal(1, "DONE did not assert");
            end
        end
    end
endtask

task automatic wait_irq_high;
    integer timeout;

    begin
        timeout = 0;

        while (irq !== 1'b1) begin
            @(posedge clk);
            #1;

            timeout = timeout + 1;

            if (timeout > 80) begin
                $fatal(1, "IRQ did not assert");
            end
        end
    end
endtask

initial begin
    reg [31:0] rd;

    repeat (5) @(posedge clk);
    resetn = 1'b1;

    // --------------------------------------------------------
    // 1. SoC31 protocol/register regression.
    // --------------------------------------------------------
    axi_read(8'h08, rd);
    check_eq32(
        "VERSION",
        rd,
        32'h0001_0000
    );

    // WSTRB regression.
    axi_write(
        8'h10,
        32'h1122_3344,
        4'b1111,
        0
    );

    axi_write(
        8'h10,
        32'h0000_AA00,
        4'b0010,
        1
    );

    axi_read(8'h10, rd);
    check_eq32(
        "WSTRB partial BIAS_CH0",
        rd,
        32'h1122_AA44
    );

    // Demo parameters.
    axi_write(8'h10, 32'd0,         4'hF, 0);
    axi_write(8'h14, 32'd4,         4'hF, 1);
    axi_write(8'h18, 32'h0001_0001, 4'hF, 2);
    axi_write(8'h1C, 32'h0001_0003, 4'hF, 0);
    axi_write(8'h20, 32'hFFFD_0000, 4'hF, 1);

    // Demo inputs.
    axi_write(8'h40, 32'd16,  4'hF, 0);
    axi_write(8'h44, 32'd32,  4'hF, 1);
    axi_write(8'h48, 32'd48,  4'hF, 2);
    axi_write(8'h4C, 32'd64,  4'hF, 0);

    axi_write(8'h50, 32'd32,  4'hF, 1);
    axi_write(8'h54, 32'd64,  4'hF, 2);
    axi_write(8'h58, 32'd96,  4'hF, 0);
    axi_write(8'h5C, 32'd128, 4'hF, 1);

    // --------------------------------------------------------
    // 2. IRQ disabled:
    //    DONE event is latched, but irq output stays low.
    // --------------------------------------------------------
    axi_write(8'h6C, 32'h0000_0000, 4'hF, 0);
    axi_write(8'h70, 32'h0000_0003, 4'b0001, 1);
    axi_write(8'h00, 32'h0000_0006, 4'b0001, 2);

    check_true(
        "IRQ low before start",
        irq === 1'b0
    );

    axi_write(
        8'h00,
        32'h0000_0001,
        4'b0001,
        0
    );

    wait_done();

    check_true(
        "IRQ remains low when disabled",
        irq === 1'b0
    );

    axi_read(8'h70, rd);
    check_true(
        "DONE pending latched while disabled",
        (rd & 32'h1) != 0
    );

    // Enabling an already-pending source must assert level IRQ.
    axi_write(8'h6C, 32'h0000_0001, 4'hF, 1);

    repeat (2) @(posedge clk);
    #1;

    check_true(
        "pending DONE asserts IRQ after enable",
        irq === 1'b1
    );

    // W1C clear drops IRQ, STATUS.DONE remains independently sticky.
    axi_write(8'h70, 32'h0000_0001, 4'b0001, 2);

    repeat (2) @(posedge clk);
    #1;

    check_true(
        "DONE IRQ clear drops level",
        irq === 1'b0
    );

    axi_read(8'h04, rd);
    check_true(
        "STATUS DONE independent from IRQ_STATUS",
        (rd & 32'h2) != 0
    );

    // --------------------------------------------------------
    // 3. Normal interrupt-driven DONE run.
    // --------------------------------------------------------
    axi_write(8'h00, 32'h0000_0002, 4'b0001, 0);
    axi_write(8'h70, 32'h0000_0003, 4'b0001, 1);
    axi_write(8'h6C, 32'h0000_0001, 4'hF, 2);

    axi_write(
        8'h00,
        32'h0000_0001,
        4'b0001,
        0
    );

    wait_busy();
    wait_irq_high();

    axi_read(8'h70, rd);

    check_true(
        "IRQ_STATUS DONE pending",
        (rd & 32'h1) != 0
    );

    check_true(
        "IRQ_STATUS ERROR clear",
        (rd & 32'h2) == 0
    );

    axi_read(8'h60, rd);
    check_eq32(
        "OUT_CH0",
        rd,
        32'h2018_1008
    );

    axi_read(8'h64, rd);
    check_eq32(
        "OUT_CH1",
        rd,
        32'h7F7F_6333
    );

    axi_read(8'h0C, rd);
    check_eq32(
        "SAT_COUNT",
        rd,
        32'd2
    );

    axi_write(8'h70, 32'h0000_0001, 4'b0001, 1);

    repeat (2) @(posedge clk);
    #1;

    check_true(
        "DONE W1C deasserts IRQ",
        irq === 1'b0
    );

    // --------------------------------------------------------
    // 4. ERROR interrupt:
    //    enable ERROR only, then START while BUSY.
    // --------------------------------------------------------
    axi_write(8'h70, 32'h0000_0003, 4'b0001, 0);
    axi_write(8'h00, 32'h0000_0006, 4'b0001, 1);
    axi_write(8'h6C, 32'h0000_0002, 4'hF, 2);

    axi_write(8'h00, 32'h0000_0001, 4'b0001, 0);
    wait_busy();

    axi_write(8'h00, 32'h0000_0001, 4'b0001, 1);

    repeat (2) @(posedge clk);
    #1;

    check_true(
        "ERROR source asserts IRQ",
        irq === 1'b1
    );

    axi_read(8'h70, rd);
    check_true(
        "IRQ_STATUS ERROR pending",
        (rd & 32'h2) != 0
    );

    axi_read(8'h04, rd);
    check_true(
        "STATUS ERROR sticky",
        (rd & 32'h4) != 0
    );

    axi_write(8'h70, 32'h0000_0002, 4'b0001, 2);

    repeat (2) @(posedge clk);
    #1;

    check_true(
        "ERROR W1C deasserts IRQ",
        irq === 1'b0
    );

    // DONE remains disabled in IRQ_ENABLE.
    wait_done();

    check_true(
        "DONE disabled so IRQ stays low",
        irq === 1'b0
    );

    // --------------------------------------------------------
    // 5. Final clear.
    // --------------------------------------------------------
    axi_write(8'h6C, 32'h0000_0000, 4'hF, 0);
    axi_write(8'h70, 32'h0000_0003, 4'b0001, 1);
    axi_write(8'h00, 32'h0000_0006, 4'b0001, 2);

    axi_read(8'h70, rd);
    check_eq32(
        "IRQ_STATUS final clear",
        rd,
        32'h0000_0000
    );

    $display("");
    $display("SOC32 CHECK COUNT : %0d", check_count);
    $display("SOC32 ERROR COUNT : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC32 NPU INTERRUPT TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC32 NPU INTERRUPT TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
