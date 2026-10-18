`timescale 1ns / 1ps

module tb_tensor_bram_data_plane;

logic clk = 1'b0;
logic resetn = 1'b0;
logic start_i = 1'b0;

logic cpu_en_i = 1'b0;
logic [3:0] cpu_we_i = 4'b0000;
logic [11:0] cpu_addr_i = 12'h000;
logic [31:0] cpu_wdata_i = 32'h0000_0000;
wire [31:0] cpu_rdata_o;

logic signed [31:0] bias_ch0_i = 32'sd0;
logic signed [31:0] bias_ch1_i = 32'sd4;

logic signed [15:0] mult_ch0_i = 16'sd1;
logic signed [15:0] mult_ch1_i = 16'sd3;

logic [5:0] shift_ch0_i = 6'd1;
logic [5:0] shift_ch1_i = 6'd1;

logic signed [15:0] zp_ch0_i = 16'sd0;
logic signed [15:0] zp_ch1_i = -16'sd3;

wire busy_o;
wire done_o;
wire error_o;

wire [15:0] read_word_count_o;
wire [15:0] write_word_count_o;

integer check_count = 0;
integer error_count = 0;

always #5 clk = ~clk;

tensor_bram_data_plane_demo_top dut (
    .clk(clk),
    .resetn(resetn),

    .start_i(start_i),

    .cpu_en_i(cpu_en_i),
    .cpu_we_i(cpu_we_i),
    .cpu_addr_i(cpu_addr_i),
    .cpu_wdata_i(cpu_wdata_i),
    .cpu_rdata_o(cpu_rdata_o),

    .bias_ch0_i(bias_ch0_i),
    .bias_ch1_i(bias_ch1_i),

    .mult_ch0_i(mult_ch0_i),
    .mult_ch1_i(mult_ch1_i),

    .shift_ch0_i(shift_ch0_i),
    .shift_ch1_i(shift_ch1_i),

    .zp_ch0_i(zp_ch0_i),
    .zp_ch1_i(zp_ch1_i),

    .busy_o(busy_o),
    .done_o(done_o),
    .error_o(error_o),

    .read_word_count_o(read_word_count_o),
    .write_word_count_o(write_word_count_o)
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

task automatic cpu_write32(
    input [11:0] address,
    input [31:0] data
);
    begin
        @(negedge clk);

        cpu_en_i = 1'b1;
        cpu_we_i = 4'b1111;
        cpu_addr_i = address;
        cpu_wdata_i = data;

        @(posedge clk);
        #1;

        @(negedge clk);

        cpu_en_i = 1'b0;
        cpu_we_i = 4'b0000;
        cpu_addr_i = 12'h000;
        cpu_wdata_i = 32'h0000_0000;
    end
endtask

task automatic cpu_read32(
    input [11:0] address,
    output [31:0] data
);
    begin
        @(negedge clk);

        cpu_en_i = 1'b1;
        cpu_we_i = 4'b0000;
        cpu_addr_i = address;

        // Synchronous BRAM read.
        @(posedge clk);
        #1;

        @(negedge clk);

        cpu_en_i = 1'b0;
        cpu_addr_i = 12'h000;

        // Capture the registered Port-A output.
        data = cpu_rdata_o;
    end
endtask

initial begin
    reg [31:0] rd;
    integer timeout;

    repeat (5) @(posedge clk);
    resetn = 1'b1;

    // --------------------------------------------------------
    // 1. CPU / Port-A writes the input tensor.
    // --------------------------------------------------------
    cpu_write32(12'h000, 32'd16);
    cpu_write32(12'h004, 32'd32);
    cpu_write32(12'h008, 32'd48);
    cpu_write32(12'h00C, 32'd64);

    cpu_write32(12'h010, 32'd32);
    cpu_write32(12'h014, 32'd64);
    cpu_write32(12'h018, 32'd96);
    cpu_write32(12'h01C, 32'd128);

    // Read back representative input locations before NPU ownership.
    cpu_read32(12'h000, rd);
    check_eq32("INPUT word0 readback", rd, 32'd16);

    cpu_read32(12'h01C, rd);
    check_eq32("INPUT word7 readback", rd, 32'd128);

    // --------------------------------------------------------
    // 2. Transfer buffer ownership to NPU and start.
    //    CPU Port A stays idle while BUSY.
    // --------------------------------------------------------
    @(negedge clk);
    start_i = 1'b1;

    @(negedge clk);
    start_i = 1'b0;

    timeout = 0;

    while (busy_o !== 1'b1) begin
        @(posedge clk);
        #1;

        timeout = timeout + 1;

        if (timeout > 20) begin
            $fatal(1, "BUSY did not assert");
        end
    end

    check_true(
        "CPU idle while NPU owns tensor buffer",
        cpu_en_i === 1'b0
    );

    timeout = 0;

    while (done_o !== 1'b1) begin
        @(posedge clk);
        #1;

        check_true(
            "CPU remains idle during NPU BUSY",
            cpu_en_i === 1'b0
        );

        timeout = timeout + 1;

        if (timeout > 200) begin
            $fatal(1, "NPU tensor engine timeout");
        end
    end

    check_true(
        "NPU error low",
        error_o === 1'b0
    );

    check_true(
        "NPU read count = 8",
        read_word_count_o == 16'd8
    );

    check_true(
        "NPU write count = 2",
        write_word_count_o == 16'd2
    );

    // Wait until engine has returned to IDLE before CPU reclaims buffer.
    @(posedge clk);
    #1;

    // --------------------------------------------------------
    // 3. CPU / Port-A reads output tensor.
    // --------------------------------------------------------
    cpu_read32(12'h100, rd);
    check_eq32(
        "OUTPUT CH0 packed int8",
        rd,
        32'h2018_1008
    );

    cpu_read32(12'h104, rd);
    check_eq32(
        "OUTPUT CH1 packed int8",
        rd,
        32'h7F7F_6333
    );

    // Input data must remain intact.
    cpu_read32(12'h000, rd);
    check_eq32(
        "INPUT word0 preserved",
        rd,
        32'd16
    );

    cpu_read32(12'h01C, rd);
    check_eq32(
        "INPUT word7 preserved",
        rd,
        32'd128
    );

    $display("");
    $display("SOC33 CHECK COUNT : %0d", check_count);
    $display("SOC33 ERROR COUNT : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC33 TENSOR BRAM DATA-PLANE TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC33 TENSOR BRAM DATA-PLANE TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
