`timescale 1ns / 1ps

module tb_custom_register_bank;

reg clk = 1'b0;
reg resetn = 1'b0;
reg wr_en = 1'b0;
reg [7:0] wr_offset = 8'h00;
reg [31:0] wr_data = 32'h0000_0000;
reg [3:0] wr_strb = 4'b0000;
reg [7:0] rd_offset = 8'h00;
wire [31:0] rd_data;

reg busy_i = 1'b0;
reg done_i = 1'b0;
reg error_i = 1'b0;
reg irq_done_event_i = 1'b0;
reg irq_error_event_i = 1'b0;
reg [31:0] data_out_i = 32'h1234_5678;

wire enable_o;
wire [1:0] mode_o;
wire start_pulse_o;
wire clear_pulse_o;
wire [31:0] data_in_o;
wire [1:0] irq_status_o;

custom_register_bank dut (
    .clk(clk), .resetn(resetn),
    .wr_en(wr_en), .wr_offset(wr_offset),
    .wr_data(wr_data), .wr_strb(wr_strb),
    .rd_offset(rd_offset), .rd_data(rd_data),
    .busy_i(busy_i), .done_i(done_i), .error_i(error_i),
    .irq_done_event_i(irq_done_event_i),
    .irq_error_event_i(irq_error_event_i),
    .data_out_i(data_out_i),
    .enable_o(enable_o), .mode_o(mode_o),
    .start_pulse_o(start_pulse_o), .clear_pulse_o(clear_pulse_o),
    .data_in_o(data_in_o), .irq_status_o(irq_status_o)
);

always #5 clk = ~clk;

task write_reg;
    input [7:0] offset;
    input [31:0] data;
    input [3:0] strb;
    begin
        @(negedge clk);
        wr_en = 1'b1;
        wr_offset = offset;
        wr_data = data;
        wr_strb = strb;
        @(negedge clk);
        wr_en = 1'b0;
        wr_strb = 4'b0000;
    end
endtask

initial begin
    repeat (2) @(negedge clk);
    resetn = 1'b1;

    // RW CONTROL: enable=1, mode=2'b10
    write_reg(8'h00, 32'h0000_0005, 4'b0001);

    // RW DATA_IN full write then low-byte-only update
    write_reg(8'h10, 32'h1122_3344, 4'b1111);
    write_reg(8'h10, 32'h0000_00AA, 4'b0001);

    // W1P COMMAND: start pulse
    write_reg(8'h08, 32'h0000_0001, 4'b0001);

    // Hardware event sets IRQ status
    @(negedge clk);
    irq_done_event_i = 1'b1;
    @(negedge clk);
    irq_done_event_i = 1'b0;

    // W1C clears DONE IRQ
    write_reg(8'h0C, 32'h0000_0001, 4'b0001);

    // Read examples
    rd_offset = 8'h00;
    #1;
    rd_offset = 8'h10;
    #1;
    rd_offset = 8'h14;
    #1;
    rd_offset = 8'h18;
    #1;
    rd_offset = 8'h1C;
    #1;

    $finish;
end

endmodule
