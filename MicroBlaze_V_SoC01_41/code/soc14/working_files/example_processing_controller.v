module example_processing_controller #(
    parameter integer PROCESS_CYCLES = 4
)(
    input  wire        clk,
    input  wire        resetn,

    // Register-bank control inputs
    input  wire        enable_i,
    input  wire [1:0]  mode_i,
    input  wire        start_pulse_i,
    input  wire        clear_pulse_i,
    input  wire [31:0] data_in_i,

    // Register-bank status / event outputs
    output reg         busy_o,
    output reg         done_o,
    output reg         error_o,
    output reg         irq_done_event_o,
    output reg         irq_error_event_o,
    output reg  [31:0] data_out_o
);

localparam STATE_IDLE = 1'b0;
localparam STATE_RUN  = 1'b1;

reg        state;
reg [7:0]  cycles_left;
reg [1:0]  mode_latched;
reg [31:0] data_latched;

function [31:0] process_value;
    input [31:0] value;
    input [1:0]  mode;
    begin
        case (mode)
            2'b00: process_value = value;          // Pass-through
            2'b01: process_value = value + 32'd1; // Add 1
            2'b10: process_value = value << 1;     // Shift left 1
            2'b11: process_value = ~value;         // Bitwise NOT
            default: process_value = value;
        endcase
    end
endfunction

always @(posedge clk) begin
    if (!resetn) begin
        state             <= STATE_IDLE;
        cycles_left       <= 8'd0;
        mode_latched      <= 2'b00;
        data_latched      <= 32'h0000_0000;

        busy_o            <= 1'b0;
        done_o            <= 1'b0;
        error_o           <= 1'b0;
        irq_done_event_o  <= 1'b0;
        irq_error_event_o <= 1'b0;
        data_out_o        <= 32'h0000_0000;
    end else begin
        // Event outputs are one-clock pulses by default.
        irq_done_event_o  <= 1'b0;
        irq_error_event_o <= 1'b0;

        // Software CLEAR removes retained status only.
        // A new hardware event later in this clock may set status again.
        if (clear_pulse_i) begin
            done_o  <= 1'b0;
            error_o <= 1'b0;
        end

        case (state)
            STATE_IDLE: begin
                busy_o <= 1'b0;

                if (start_pulse_i) begin
                    done_o <= 1'b0;

                    if (!enable_i) begin
                        // Start requested while the controller is disabled.
                        error_o           <= 1'b1;
                        irq_error_event_o <= 1'b1;
                    end else begin
                        // Capture software-controlled values only at START.
                        mode_latched <= mode_i;
                        data_latched <= data_in_i;

                        busy_o  <= 1'b1;
                        error_o <= 1'b0;

                        if (PROCESS_CYCLES <= 1) begin
                            cycles_left <= 8'd0;
                        end else begin
                            cycles_left <= PROCESS_CYCLES - 1;
                        end

                        state <= STATE_RUN;
                    end
                end
            end

            STATE_RUN: begin
                busy_o <= 1'b1;

                // A second START while busy is an error event.
                // The original operation continues.
                if (start_pulse_i) begin
                    error_o           <= 1'b1;
                    irq_error_event_o <= 1'b1;
                end

                if (cycles_left != 0) begin
                    cycles_left <= cycles_left - 1'b1;
                end else begin
                    data_out_o       <= process_value(data_latched, mode_latched);
                    busy_o           <= 1'b0;
                    done_o           <= 1'b1;
                    irq_done_event_o <= 1'b1;
                    state            <= STATE_IDLE;
                end
            end

            default: begin
                state  <= STATE_IDLE;
                busy_o <= 1'b0;
            end
        endcase
    end
end

endmodule
