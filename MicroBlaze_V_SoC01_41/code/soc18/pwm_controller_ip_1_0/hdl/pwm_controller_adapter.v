module pwm_controller_adapter (
    input  wire        clk,
    input  wire        resetn,

    input  wire        enable_i,
    input  wire        invert_i,
    input  wire [31:0] period_shadow_i,
    input  wire [31:0] duty_shadow_i,
    input  wire        update_pulse_i,
    input  wire        clear_error_pulse_i,

    output wire        active_o,
    output reg         error_o,
    output reg  [31:0] active_period_o,
    output reg  [31:0] active_duty_o,

    output wire        pwm_o
);

reg active_enable;
reg active_invert;

legacy_pwm_core u_legacy_pwm_core (
    .clk(clk),
    .resetn(resetn),

    .enable_i(active_enable),
    .invert_i(active_invert),
    .period_i(active_period_o),
    .duty_i(active_duty_o),

    .pwm_o(pwm_o),
    .active_o(active_o)
);

always @(posedge clk) begin
    if (!resetn) begin
        active_enable   <= 1'b0;
        active_invert   <= 1'b0;
        active_period_o <= 32'd1000;
        active_duty_o   <= 32'd500;
        error_o         <= 1'b0;
    end else begin
        if (clear_error_pulse_i) begin
            error_o <= 1'b0;
        end

        if (update_pulse_i) begin
            if (
                (period_shadow_i == 0) ||
                (duty_shadow_i > period_shadow_i)
            ) begin
                error_o <= 1'b1;
            end else begin
                active_enable   <= enable_i;
                active_invert   <= invert_i;
                active_period_o <= period_shadow_i;
                active_duty_o   <= duty_shadow_i;
                error_o         <= 1'b0;
            end
        end
    end
end

endmodule
