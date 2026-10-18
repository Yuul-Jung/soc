`timescale 1ns / 1ps

module tb_npu_job_descriptor;

logic clk = 1'b0;
logic resetn = 1'b0;

logic reg_wr_en_i = 1'b0;
logic [7:0] reg_wr_addr_i = 8'h00;
logic [31:0] reg_wr_data_i = 32'h0000_0000;
logic [3:0] reg_wr_strb_i = 4'h0;

logic [7:0] reg_rd_addr_i = 8'h00;
wire [31:0] reg_rd_data_o;

logic mem_en_i = 1'b0;
logic [3:0] mem_we_i = 4'b0000;
logic [11:0] mem_addr_i = 12'h000;
logic [31:0] mem_wdata_i = 32'h0000_0000;
wire [31:0] mem_rdata_o;

wire busy_o;
wire done_sticky_o;
wire error_sticky_o;
wire [7:0] error_code_o;
wire [31:0] job_id_o;

integer check_count = 0;
integer error_count = 0;

always #5 clk = ~clk;

npu_job_descriptor_demo_top dut (
    .clk(clk),
    .resetn(resetn),

    .reg_wr_en_i(reg_wr_en_i),
    .reg_wr_addr_i(reg_wr_addr_i),
    .reg_wr_data_i(reg_wr_data_i),
    .reg_wr_strb_i(reg_wr_strb_i),

    .reg_rd_addr_i(reg_rd_addr_i),
    .reg_rd_data_o(reg_rd_data_o),

    .mem_en_i(mem_en_i),
    .mem_we_i(mem_we_i),
    .mem_addr_i(mem_addr_i),
    .mem_wdata_i(mem_wdata_i),
    .mem_rdata_o(mem_rdata_o),

    .busy_o(busy_o),
    .done_sticky_o(done_sticky_o),
    .error_sticky_o(error_sticky_o),
    .error_code_o(error_code_o),
    .job_id_o(job_id_o)
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

task automatic reg_write(
    input [7:0] address,
    input [31:0] data
);
    begin
        @(negedge clk);

        reg_wr_en_i = 1'b1;
        reg_wr_addr_i = address;
        reg_wr_data_i = data;
        reg_wr_strb_i = 4'hF;

        @(posedge clk);
        #1;

        @(negedge clk);

        reg_wr_en_i = 1'b0;
        reg_wr_addr_i = 8'h00;
        reg_wr_data_i = 32'h0000_0000;
        reg_wr_strb_i = 4'h0;
    end
endtask

task automatic reg_read(
    input [7:0] address,
    output [31:0] data
);
    begin
        reg_rd_addr_i = address;
        #1;
        data = reg_rd_data_o;
    end
endtask

task automatic mem_write32(
    input [11:0] address,
    input [31:0] data
);
    begin
        @(negedge clk);

        mem_en_i = 1'b1;
        mem_we_i = 4'hF;
        mem_addr_i = address;
        mem_wdata_i = data;

        @(posedge clk);
        #1;

        @(negedge clk);

        mem_en_i = 1'b0;
        mem_we_i = 4'h0;
        mem_addr_i = 12'h000;
        mem_wdata_i = 32'h0000_0000;
    end
endtask

task automatic mem_read32(
    input [11:0] address,
    output [31:0] data
);
    begin
        @(negedge clk);

        mem_en_i = 1'b1;
        mem_we_i = 4'h0;
        mem_addr_i = address;

        @(posedge clk);
        #1;

        @(negedge clk);

        mem_en_i = 1'b0;
        mem_addr_i = 12'h000;

        data = mem_rdata_o;
    end
endtask

task automatic wait_busy;
    integer timeout;
    begin
        timeout = 0;

        while (busy_o !== 1'b1) begin
            @(posedge clk);
            #1;

            timeout = timeout + 1;

            if (timeout > 30) begin
                $fatal(1, "BUSY did not assert");
            end
        end
    end
endtask

task automatic wait_done;
    integer timeout;
    begin
        timeout = 0;

        while (done_sticky_o !== 1'b1) begin
            @(posedge clk);
            #1;

            timeout = timeout + 1;

            if (timeout > 250) begin
                $fatal(1, "DONE did not assert");
            end
        end
    end
endtask

initial begin
    reg [31:0] rd;
    reg [31:0] job_id_before;

    repeat (5) @(posedge clk);
    resetn = 1'b1;

    // --------------------------------------------------------
    // 1. Prepare input tensor at programmable INPUT_BASE=0x200.
    // --------------------------------------------------------
    mem_write32(12'h200, 32'd16);
    mem_write32(12'h204, 32'd32);
    mem_write32(12'h208, 32'd48);
    mem_write32(12'h20C, 32'd64);

    mem_write32(12'h210, 32'd32);
    mem_write32(12'h214, 32'd64);
    mem_write32(12'h218, 32'd96);
    mem_write32(12'h21C, 32'd128);

    // Shadow descriptor.
    reg_write(8'h10, 32'h0000_0200);
    reg_write(8'h14, 32'h0000_0300);
    reg_write(8'h18, 32'd8);

    reg_read(8'h04, rd);
    check_true(
        "descriptor valid before START",
        (rd & 32'h8) != 0
    );

    // --------------------------------------------------------
    // 2. START -> active snapshot.
    // --------------------------------------------------------
    reg_write(8'h00, 32'h0000_0001);
    wait_busy();

    reg_read(8'h0C, rd);
    check_eq32(
        "JOB_ID first accepted job",
        rd,
        32'd1
    );

    reg_read(8'h34, rd);
    check_eq32(
        "ACTIVE_INPUT snapshot",
        rd,
        32'h0000_0200
    );

    reg_read(8'h38, rd);
    check_eq32(
        "ACTIVE_OUTPUT snapshot",
        rd,
        32'h0000_0300
    );

    // Change shadow while current job is running.
    // Current active addresses must remain unchanged.
    reg_write(8'h10, 32'h0000_0400);
    reg_write(8'h14, 32'h0000_0500);

    reg_read(8'h34, rd);
    check_eq32(
        "ACTIVE_INPUT stable while shadow changes",
        rd,
        32'h0000_0200
    );

    reg_read(8'h38, rd);
    check_eq32(
        "ACTIVE_OUTPUT stable while shadow changes",
        rd,
        32'h0000_0300
    );

    wait_done();

    check_true(
        "first job no error",
        error_sticky_o === 1'b0
    );

    reg_read(8'h40, rd);
    check_eq32(
        "READ_WORD_COUNT",
        rd,
        32'd8
    );

    reg_read(8'h44, rd);
    check_eq32(
        "WRITE_WORD_COUNT",
        rd,
        32'd2
    );

    mem_read32(12'h300, rd);
    check_eq32(
        "descriptor output CH0",
        rd,
        32'h2018_1008
    );

    mem_read32(12'h304, rd);
    check_eq32(
        "descriptor output CH1",
        rd,
        32'h7F7F_6333
    );

    // --------------------------------------------------------
    // 3. Invalid descriptor: unaligned INPUT_BASE.
    // --------------------------------------------------------
    reg_write(8'h00, 32'h0000_0006);

    reg_read(8'h0C, job_id_before);

    reg_write(8'h10, 32'h0000_0202);
    reg_write(8'h14, 32'h0000_0600);
    reg_write(8'h18, 32'd8);

    reg_write(8'h00, 32'h0000_0001);

    repeat (2) @(posedge clk);
    #1;

    check_true(
        "unaligned descriptor rejected",
        error_sticky_o === 1'b1
    );

    check_true(
        "unaligned error code = 2",
        error_code_o == 8'd2
    );

    check_eq32(
        "rejected job does not increment JOB_ID",
        job_id_o,
        job_id_before
    );

    // --------------------------------------------------------
    // 4. Invalid descriptor: unsupported length.
    // --------------------------------------------------------
    reg_write(8'h00, 32'h0000_0004);

    reg_write(8'h10, 32'h0000_0200);
    reg_write(8'h14, 32'h0000_0600);
    reg_write(8'h18, 32'd7);

    reg_write(8'h00, 32'h0000_0001);

    repeat (2) @(posedge clk);
    #1;

    check_true(
        "length 7 rejected",
        error_sticky_o === 1'b1
    );

    check_true(
        "length error code = 4",
        error_code_o == 8'd4
    );

    // --------------------------------------------------------
    // 5. Invalid descriptor: input/output overlap.
    // --------------------------------------------------------
    reg_write(8'h00, 32'h0000_0004);

    reg_write(8'h10, 32'h0000_0200);
    reg_write(8'h14, 32'h0000_0210);
    reg_write(8'h18, 32'd8);

    reg_write(8'h00, 32'h0000_0001);

    repeat (2) @(posedge clk);
    #1;

    check_true(
        "overlap descriptor rejected",
        error_sticky_o === 1'b1
    );

    check_true(
        "overlap error code = 7",
        error_code_o == 8'd7
    );

    // --------------------------------------------------------
    // 6. Invalid descriptor: input out of 4KB range.
    // --------------------------------------------------------
    reg_write(8'h00, 32'h0000_0004);

    reg_write(8'h10, 32'h0000_0FF0);
    reg_write(8'h14, 32'h0000_0100);
    reg_write(8'h18, 32'd8);

    reg_write(8'h00, 32'h0000_0001);

    repeat (2) @(posedge clk);
    #1;

    check_true(
        "input range descriptor rejected",
        error_sticky_o === 1'b1
    );

    check_true(
        "input range error code = 5",
        error_code_o == 8'd5
    );

    $display("");
    $display("SOC34 CHECK COUNT : %0d", check_count);
    $display("SOC34 ERROR COUNT : %0d", error_count);

    if (error_count == 0) begin
        $display("SOC34 JOB DESCRIPTOR TEST: PASS");
    end else begin
        $fatal(
            1,
            "SOC34 JOB DESCRIPTOR TEST: FAIL (%0d errors)",
            error_count
        );
    end

    #20;
    $finish;
end

endmodule
