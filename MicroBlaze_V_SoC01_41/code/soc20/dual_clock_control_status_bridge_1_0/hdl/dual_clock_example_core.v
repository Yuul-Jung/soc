module dual_clock_example_core #(
    parameter integer PROCESS_CYCLES = 6
)(
    input  wire        clk,
    input  wire        resetn,

    // Coherent input packet: control + data
    input  wire [63:0] packet_i,
    input  wire        packet_valid_i,
    output wire        packet_ready_o,

    output reg  [31:0] result_o,
    output reg         result_valid_o,
    input  wire        result_ready_i,

    output wire        idle_o,
    output wire        busy_o
);

localparam [1:0] ST_IDLE = 2'd0;
localparam [1:0] ST_RUN  = 2'd1;
localparam [1:0] ST_OUT  = 2'd2;

reg [1:0] state;
reg [7:0] cycles_left;
reg [31:0] data_latched;
reg [1:0] mode_latched;

wire [31:0] control_word;
wire [31:0] input_word;

assign control_word = packet_i[63:32];
assign input_word   = packet_i[31:0];

assign packet_ready_o = (state == ST_IDLE);
assign idle_o = (state == ST_IDLE);
assign busy_o = (state == ST_RUN);

function [31:0] process_value;
    input [31:0] value;
    input [1:0] mode;
    begin
        case (mode)
            2'b00: process_value = value;
            2'b01: process_value = value + 32'd1;
            2'b10: process_value = value << 1;
            2'b11: process_value = ~value;
            default: process_value = value;
        endcase
    end
endfunction

always @(posedge clk) begin
    if (!resetn) begin
        state          <= ST_IDLE;
        cycles_left    <= 8'd0;
        data_latched   <= 32'h0000_0000;
        mode_latched   <= 2'b00;
        result_o       <= 32'h0000_0000;
        result_valid_o <= 1'b0;
    end else begin
        case (state)
            ST_IDLE: begin
                result_valid_o <= 1'b0;

                if (packet_valid_i && packet_ready_o) begin
                    data_latched <= input_word;
                    mode_latched <= control_word[1:0];

                    if (PROCESS_CYCLES <= 1) begin
                        cycles_left <= 8'd0;
                    end else begin
                        cycles_left <= PROCESS_CYCLES - 1;
                    end

                    state <= ST_RUN;
                end
            end

            ST_RUN: begin
                if (cycles_left != 0) begin
                    cycles_left <= cycles_left - 1'b1;
                end else begin
                    result_o <= process_value(
                        data_latched,
                        mode_latched
                    );
                    result_valid_o <= 1'b1;
                    state <= ST_OUT;
                end
            end

            ST_OUT: begin
                if (result_valid_o && result_ready_i) begin
                    result_valid_o <= 1'b0;
                    state <= ST_IDLE;
                end
            end

            default: begin
                state <= ST_IDLE;
                result_valid_o <= 1'b0;
            end
        endcase
    end
end

endmodule
