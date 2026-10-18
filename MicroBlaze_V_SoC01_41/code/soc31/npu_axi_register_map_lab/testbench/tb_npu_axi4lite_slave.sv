`timescale 1ns / 1ps

module tb_npu_axi4lite_slave;

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

integer error_count = 0;
integer check_count = 0;

always #5 clk = ~clk;

npu_axi4lite_slave dut (
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

            if ((order == 1) && aw_done && !w_done) begin
                wvalid = 1'b1;
            end

            if ((order == 2) && w_done && !aw_done) begin
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

        // Allow response handshake and register-side effect to settle.
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

        // The read data may be returned immediately after this edge.
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

initial begin
    reg [31:0] rd;

    repeat (5) @(posedge clk);
    resetn = 1'b1;

    // --------------------------------------------------------
    // 1. Basic RO map.
    // --------------------------------------------------------
    axi_read(8'h08, rd);
    check_eq32(
        "VERSION",
        rd,
        32'h0001_0000
    );

    // --------------------------------------------------------
    // 2. WSTRB partial-write test.
    //    Full write, then update only byte lane 1.
    // --------------------------------------------------------
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

    // --------------------------------------------------------
    // 3. Demo parameters.
    //    Exercise simultaneous, AW-first, W-first ordering.
    // --------------------------------------------------------
    axi_write(8'h10, 32'd0,         4'hF, 0);
    axi_write(8'h14, 32'd4,         4'hF, 1);
    axi_write(8'h18, 32'h0001_0001, 4'hF, 2);
    axi_write(8'h1C, 32'h0001_0003, 4'hF, 0);
    axi_write(8'h20, 32'hFFFD_0000, 4'hF, 1);

    axi_read(8'h18, rd);
    check_eq32("SCALE_CH0", rd, 32'h0001_0001);

    axi_read(8'h1C, rd);
    check_eq32("SCALE_CH1", rd, 32'h0001_0003);

    axi_read(8'h20, rd);
    check_eq32("ZERO_POINT", rd, 32'hFFFD_0000);

    // --------------------------------------------------------
    // 4. SoC29 int32 input registers.
    // --------------------------------------------------------
    axi_write(8'h40, 32'd16,  4'hF, 0);
    axi_write(8'h44, 32'd32,  4'hF, 1);
    axi_write(8'h48, 32'd48,  4'hF, 2);
    axi_write(8'h4C, 32'd64,  4'hF, 0);

    axi_write(8'h50, 32'd32,  4'hF, 1);
    axi_write(8'h54, 32'd64,  4'hF, 2);
    axi_write(8'h58, 32'd96,  4'hF, 0);
    axi_write(8'h5C, 32'd128, 4'hF, 1);

    // Clear sticky flags before run.
    axi_write(
        8'h00,
        32'h0000_0006,
        4'b0001,
        0
    );

    // --------------------------------------------------------
    // 5. START and BUSY.
    // --------------------------------------------------------
    axi_write(
        8'h00,
        32'h0000_0001,
        4'b0001,
        2
    );

    wait_busy();

    check_true(
        "debug BUSY output",
        accel_busy === 1'b1
    );

    // START while BUSY must be rejected and set ERROR sticky.
    axi_write(
        8'h00,
        32'h0000_0001,
        4'b0001,
        0
    );

    wait_done();

    // --------------------------------------------------------
    // 6. Status and result.
    // --------------------------------------------------------
    axi_read(8'h04, rd);

    check_true(
        "DONE sticky set",
        (rd & 32'h2) != 0
    );

    check_true(
        "ERROR sticky set by START while BUSY",
        (rd & 32'h4) != 0
    );

    check_true(
        "SATURATED_ANY set",
        (rd & 32'h8) != 0
    );

    axi_read(8'h0C, rd);
    check_eq32(
        "SAT_COUNT",
        rd,
        32'd2
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

    axi_read(8'h68, rd);
    check_true(
        "CYCLE_COUNT non-zero",
        rd != 32'd0
    );

    // --------------------------------------------------------
    // 7. Clear sticky flags.
    // --------------------------------------------------------
    axi_write(
        8'h00,
        32'h0000_0006,
        4'b0001,
        1
    );

    axi_read(8'h04, rd);

    check_true(
        "DONE sticky cleared",
        (rd & 32'h2) == 0
    );

    check_true(
        "ERROR sticky cleared",
        (rd & 32'h4) == 0
    );

    $display("");
    $display("SOC31 CHECK COUNT : %0d", check_count);
    $display("SOC31 ERROR COUNT : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC31 AXI4-LITE NPU REGISTER TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC31 AXI4-LITE NPU REGISTER TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
