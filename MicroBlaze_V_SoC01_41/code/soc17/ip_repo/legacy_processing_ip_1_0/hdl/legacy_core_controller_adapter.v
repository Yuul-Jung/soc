module legacy_core_controller_adapter #(
    parameter integer LEGACY_LATENCY_CYCLES = 4
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
    output wire        busy_o,
    output reg         done_o,
    output reg         error_o,
    output reg         irq_done_event_o,
    output reg         irq_error_event_o,
    output wire [31:0] data_out_o
);

wire        legacy_busy;
wire        legacy_done_pulse;
wire [31:0] legacy_result;
wire        legacy_launch;

/*
 * The existing RTL is not modified.
 * This adapter translates the register/controller contract into
 * the legacy core's launch/opcode/operand interface.
 */
assign legacy_launch =
    start_pulse_i &&
    enable_i &&
    !legacy_busy;

assign busy_o     = legacy_busy;
assign data_out_o = legacy_result;

legacy_processing_core #(
    .LATENCY_CYCLES(LEGACY_LATENCY_CYCLES)
) u_legacy_processing_core (
    .clk(clk),
    .rst_n(resetn),

    .launch_i(legacy_launch),
    .opcode_i(mode_i),
    .operand_i(data_in_i),

    .active_o(legacy_busy),
    .done_pulse_o(legacy_done_pulse),
    .result_o(legacy_result)
);

always @(posedge clk) begin
    if (!resetn) begin
        done_o              <= 1'b0;
        error_o             <= 1'b0;
        irq_done_event_o    <= 1'b0;
        irq_error_event_o   <= 1'b0;
    end else begin
        // Event outputs are one-clock pulses.
        irq_done_event_o  <= 1'b0;
        irq_error_event_o <= 1'b0;

        // Software CLEAR only clears retained software-visible status.
        if (clear_pulse_i) begin
            done_o  <= 1'b0;
            error_o <= 1'b0;
        end

        if (start_pulse_i) begin
            done_o <= 1'b0;

            if (!enable_i) begin
                error_o           <= 1'b1;
                irq_error_event_o <= 1'b1;
            end else if (legacy_busy) begin
                error_o           <= 1'b1;
                irq_error_event_o <= 1'b1;
            end else begin
                // Legal start. The legacy core receives legacy_launch.
                error_o <= 1'b0;
            end
        end

        if (legacy_done_pulse) begin
            done_o           <= 1'b1;
            irq_done_event_o <= 1'b1;
        end
    end
end

endmodule
