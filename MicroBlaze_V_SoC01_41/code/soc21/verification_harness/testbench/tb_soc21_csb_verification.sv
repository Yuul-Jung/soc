`timescale 1ns / 1ps

module tb_soc21_csb_verification;

localparam int ADDR_W = 32;

localparam logic [31:0] REG_CONTROL       = 32'h0000_0000;
localparam logic [31:0] REG_CORE_STATUS   = 32'h0000_0004;
localparam logic [31:0] REG_BRIDGE_STATUS = 32'h0000_0008;
localparam logic [31:0] REG_IN_DATA       = 32'h0000_000C;
localparam logic [31:0] REG_COMMAND       = 32'h0000_0010;
localparam logic [31:0] REG_OUT_DATA      = 32'h0000_0014;
localparam logic [31:0] REG_EVENT_STATUS  = 32'h0000_0018;
localparam logic [31:0] REG_VERSION       = 32'h0000_001C;
localparam logic [31:0] REG_ID            = 32'h0000_0020;

localparam logic [31:0] CMD_SUBMIT      = 32'h0000_0001;
localparam logic [31:0] CMD_POP         = 32'h0000_0002;
localparam logic [31:0] CMD_CLEAR_ERROR = 32'h0000_0004;

localparam logic [31:0] EVENT_ALL = 32'h0000_0007;

logic clk = 1'b0;
logic resetn = 1'b0;

always #5 clk = ~clk;

logic [ADDR_W-1:0] awaddr = '0;
logic [2:0]        awprot = '0;
logic              awvalid = 1'b0;
wire               awready;

logic [31:0]       wdata = '0;
logic [3:0]        wstrb = '0;
logic              wvalid = 1'b0;
wire               wready;

wire [1:0]         bresp;
wire               bvalid;
logic              bready = 1'b0;

logic [ADDR_W-1:0] araddr = '0;
logic [2:0]        arprot = '0;
logic              arvalid = 1'b0;
wire               arready;

wire [31:0]        rdata;
wire [1:0]         rresp;
wire               rvalid;
logic              rready = 1'b0;

wire irq_o;

int error_count = 0;
int check_count = 0;

typedef enum int {
    SC_NORMAL        = 0,
    SC_SUBMIT_PENDING = 1,
    SC_EMPTY_POP     = 2,
    SC_CLEAR         = 3
} scenario_t;

logic [1:0] cov_mode;
scenario_t cov_scenario;

covergroup cg_transactions;
    option.per_instance = 1;

    cp_mode: coverpoint cov_mode {
        bins mode0 = {0};
        bins mode1 = {1};
        bins mode2 = {2};
        bins mode3 = {3};
    }

    cp_scenario: coverpoint cov_scenario {
        bins normal         = {SC_NORMAL};
        bins submit_pending = {SC_SUBMIT_PENDING};
        bins empty_pop      = {SC_EMPTY_POP};
        bins clear_case     = {SC_CLEAR};
    }

    mode_x_scenario: cross cp_mode, cp_scenario;
endgroup

cg_transactions coverage = new();

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

function automatic logic [31:0] reference_model(
    input logic [1:0] mode,
    input logic [31:0] value
);
    case (mode)
        2'd0: reference_model = value;
        2'd1: reference_model = value + 32'd1;
        2'd2: reference_model = value << 1;
        2'd3: reference_model = ~value;
        default: reference_model = value;
    endcase
endfunction

task automatic check_eq32(
    input string name,
    input logic [31:0] actual,
    input logic [31:0] expected
);
    check_count++;

    if (actual !== expected) begin
        error_count++;
        $error(
            "CHECK FAIL: %s actual=%08h expected=%08h",
            name,
            actual,
            expected
        );
    end else begin
        $display(
            "CHECK PASS: %s = %08h",
            name,
            actual
        );
    end
endtask

task automatic check_true(
    input string name,
    input bit condition
);
    check_count++;

    if (!condition) begin
        error_count++;
        $error("CHECK FAIL: %s", name);
    end else begin
        $display("CHECK PASS: %s", name);
    end
endtask

task automatic axi_write(
    input logic [31:0] addr,
    input logic [31:0] data
);
    @(negedge clk);
    awaddr  = addr;
    awvalid = 1'b1;

    wait (awready === 1'b1);
    @(negedge clk);
    awvalid = 1'b0;

    @(negedge clk);
    wdata  = data;
    wstrb  = 4'b1111;
    wvalid = 1'b1;

    wait (wready === 1'b1);
    @(negedge clk);
    wvalid = 1'b0;

    bready = 1'b1;
    wait (bvalid === 1'b1);
    @(posedge clk);
    @(negedge clk);
    bready = 1'b0;

    check_true("AXI BRESP OKAY", bresp == 2'b00);
endtask

task automatic axi_read(
    input  logic [31:0] addr,
    output logic [31:0] data
);
    @(negedge clk);
    araddr  = addr;
    arvalid = 1'b1;

    wait (arready === 1'b1);
    @(negedge clk);
    arvalid = 1'b0;

    rready = 1'b1;
    wait (rvalid === 1'b1);

    data = rdata;
    check_true("AXI RRESP OKAY", rresp == 2'b00);

    @(posedge clk);
    @(negedge clk);
    rready = 1'b0;
endtask

task automatic clear_bridge;
    begin
        axi_write(REG_COMMAND, CMD_CLEAR_ERROR);
        axi_write(REG_EVENT_STATUS, EVENT_ALL);
        cov_scenario = SC_CLEAR;
        coverage.sample();
    end
endtask

task automatic wait_output_pending(
    output logic [31:0] bridge_status
);
    int k;
    begin
        bridge_status = '0;

        for (k = 0; k < 200; k++) begin
            axi_read(REG_BRIDGE_STATUS, bridge_status);

            if (bridge_status[2]) begin
                return;
            end
        end

        error_count++;
        $error("TIMEOUT: OUT_PENDING did not assert");
    end
endtask

task automatic run_normal_case(
    input logic [1:0] mode,
    input logic [31:0] input_value
);
    logic [31:0] status;
    logic [31:0] result;
    logic [31:0] events;
    logic [31:0] expected;
    begin
        expected = reference_model(mode, input_value);

        clear_bridge();
        axi_write(REG_CONTROL, {30'h0, mode});
        axi_write(REG_IN_DATA, input_value);
        axi_write(REG_COMMAND, CMD_SUBMIT);

        wait_output_pending(status);

        axi_read(REG_OUT_DATA, result);
        check_eq32("scoreboard result", result, expected);

        axi_read(REG_EVENT_STATUS, events);
        check_true(
            "IN_ACCEPTED event",
            (events & 32'h1) != 0
        );
        check_true(
            "OUT_CAPTURED event",
            (events & 32'h2) != 0
        );
        check_true("IRQ asserted", irq_o == 1'b1);

        cov_mode = mode;
        cov_scenario = SC_NORMAL;
        coverage.sample();

        axi_write(REG_COMMAND, CMD_POP);
    end
endtask

task automatic run_submit_pending_error;
    logic [31:0] status;
    logic [31:0] result;
    begin
        clear_bridge();

        // Hold the functional result in the output buffer.
        axi_write(REG_CONTROL, 32'h1);
        axi_write(REG_IN_DATA, 32'h10);
        axi_write(REG_COMMAND, CMD_SUBMIT);
        wait_output_pending(status);

        // 두 번째 입력은 Core가 수락하고 첫 출력의 POP을 기다린다.
        axi_write(REG_IN_DATA, 32'h20);
        axi_write(REG_COMMAND, CMD_SUBMIT);

        // (변경) Core 출력과 Bridge 출력이 찬 뒤 세 번째 요청을 대기시킨다.
        repeat (12) @(negedge clk);
        axi_write(REG_IN_DATA, 32'h30);
        axi_write(REG_COMMAND, CMD_SUBMIT);

        // (추가) IN_PENDING이 실제로 1인 상태의 네 번째 요청을 거부한다.
        axi_write(REG_IN_DATA, 32'h40);
        axi_write(REG_COMMAND, CMD_SUBMIT);

        axi_read(REG_BRIDGE_STATUS, status);
        check_true(
            "submit while pending sets ERROR",
            status[3] == 1'b1
        );

        cov_mode = 2'd1;
        cov_scenario = SC_SUBMIT_PENDING;
        coverage.sample();

        // (변경) 수락된 결과 세 개를 모두 회수한 뒤 다음 Scenario로 넘어간다.
        axi_write(REG_COMMAND, CMD_POP);
        wait_output_pending(status);
        axi_read(REG_OUT_DATA, result);
        check_eq32("second queued output", result, 32'h21);
        axi_write(REG_COMMAND, CMD_POP);
        wait_output_pending(status);
        axi_read(REG_OUT_DATA, result);
        check_eq32("third queued output", result, 32'h31);
        axi_write(REG_COMMAND, CMD_POP);
        clear_bridge();
    end
endtask

task automatic run_empty_pop_error;
    logic [31:0] status;
    begin
        clear_bridge();

        axi_write(REG_COMMAND, CMD_POP);
        axi_read(REG_BRIDGE_STATUS, status);

        check_true(
            "empty POP sets ERROR",
            status[3] == 1'b1
        );

        cov_mode = 2'd0;
        cov_scenario = SC_EMPTY_POP;
        coverage.sample();

        clear_bridge();
    end
endtask

task automatic run_random_regression(
    input int count
);
    int i;
    logic [1:0] mode;
    logic [31:0] value;
    begin
        for (i = 0; i < count; i++) begin
            mode  = $urandom_range(0, 3);
            value = $urandom();

            run_normal_case(mode, value);
        end
    end
endtask

initial begin
    cov_mode = 2'd0;
    cov_scenario = SC_CLEAR;

    repeat (5) @(posedge clk);
    resetn = 1'b1;
    repeat (3) @(posedge clk);

    // Basic identification.
    begin
        logic [31:0] rd;

        axi_read(REG_ID, rd);
        check_eq32("ID", rd, 32'h43534231);

        axi_read(REG_VERSION, rd);
        check_eq32("VERSION", rd, 32'h00010000);
    end

    // Directed tests for all modes.
    run_normal_case(2'd0, 32'h12345678);
    run_normal_case(2'd1, 32'h00000009);
    run_normal_case(2'd2, 32'h80000001);
    run_normal_case(2'd3, 32'hA5A55A5A);

    // Corner cases.
    run_submit_pending_error();
    run_empty_pop_error();

    // Small randomized regression.
    run_random_regression(20);

    $display("");
    $display("SOC21 CHECK COUNT  : %0d", check_count);
    $display("SOC21 ERROR COUNT  : %0d", error_count);
    $display("SOC21 COVERAGE     : %0.2f %%", coverage.get_inst_coverage());

    if (error_count == 0) begin
        $display("SOC21 SELF-CHECKING VERIFICATION: PASS");
    end else begin
        $fatal(
            1,
            "SOC21 SELF-CHECKING VERIFICATION: FAIL (%0d errors)",
            error_count
        );
    end

    #50;
    $finish;
end

endmodule
