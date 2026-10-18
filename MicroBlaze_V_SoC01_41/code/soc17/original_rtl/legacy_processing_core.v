module legacy_processing_core #(
    parameter integer LATENCY_CYCLES = 4
)(
    input  wire        clk,
    input  wire        rst_n,

    // Legacy functional interface
    input  wire        launch_i,
    input  wire [1:0]  opcode_i,
    input  wire [31:0] operand_i,

    output reg         active_o,
    output reg         done_pulse_o,
    output reg  [31:0] result_o
);

reg [1:0]  opcode_latched;
reg [31:0] operand_latched;
reg [7:0]  cycles_left;

function [31:0] calculate_result;
    input [31:0] value;
    input [1:0]  opcode;
    begin
        case (opcode)
            2'b00: calculate_result = value;
            2'b01: calculate_result = value + 32'd1;
            2'b10: calculate_result = value << 1;
            2'b11: calculate_result = ~value;
            default: calculate_result = value;
        endcase
    end
endfunction

always @(posedge clk) begin
    if (!rst_n) begin
        opcode_latched  <= 2'b00;
        operand_latched <= 32'h0000_0000;
        cycles_left     <= 8'd0;

        active_o        <= 1'b0;
        done_pulse_o    <= 1'b0;
        result_o        <= 32'h0000_0000;
    end else begin
        // Legacy core reports completion as a one-clock pulse.
        done_pulse_o <= 1'b0;

        if (!active_o) begin
            if (launch_i) begin
                opcode_latched  <= opcode_i;
                operand_latched <= operand_i;
                active_o        <= 1'b1;

                if (LATENCY_CYCLES <= 1) begin
                    cycles_left <= 8'd0;
                end else begin
                    cycles_left <= LATENCY_CYCLES - 1;
                end
            end
        end else begin
            if (cycles_left != 0) begin
                cycles_left <= cycles_left - 1'b1;
            end else begin
                result_o <= calculate_result(
                    operand_latched,
                    opcode_latched
                );

                active_o     <= 1'b0;
                done_pulse_o <= 1'b1;
            end
        end
    end
end

endmodule
