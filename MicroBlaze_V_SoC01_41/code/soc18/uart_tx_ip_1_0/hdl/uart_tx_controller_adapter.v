module uart_tx_controller_adapter #(
    parameter integer CLKS_PER_BIT = 868
)(
    input  wire       clk,
    input  wire       resetn,

    input  wire       enable_i,
    input  wire       send_pulse_i,
    input  wire       clear_pulse_i,
    input  wire [7:0] tx_data_i,

    output wire       busy_o,
    output reg        done_o,
    output reg        error_o,
    output reg        irq_done_event_o,
    output reg        irq_error_event_o,

    output wire       uart_tx_o
);

wire legacy_busy;
wire legacy_done_pulse;
wire legacy_start;

assign legacy_start =
    send_pulse_i &&
    enable_i &&
    !legacy_busy;

assign busy_o = legacy_busy;

legacy_uart_tx_core #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
) u_legacy_uart_tx_core (
    .clk(clk),
    .resetn(resetn),

    .tx_start_i(legacy_start),
    .tx_data_i(tx_data_i),

    .tx_o(uart_tx_o),
    .busy_o(legacy_busy),
    .done_pulse_o(legacy_done_pulse)
);

always @(posedge clk) begin
    if (!resetn) begin
        done_o              <= 1'b0;
        error_o             <= 1'b0;
        irq_done_event_o    <= 1'b0;
        irq_error_event_o   <= 1'b0;
    end else begin
        irq_done_event_o  <= 1'b0;
        irq_error_event_o <= 1'b0;

        if (clear_pulse_i) begin
            done_o  <= 1'b0;
            error_o <= 1'b0;
        end

        if (send_pulse_i) begin
            done_o <= 1'b0;

            if (!enable_i) begin
                error_o           <= 1'b1;
                irq_error_event_o <= 1'b1;
            end else if (legacy_busy) begin
                error_o           <= 1'b1;
                irq_error_event_o <= 1'b1;
            end else begin
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
