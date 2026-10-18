module legacy_pwm_core (
    input  wire        clk,
    input  wire        resetn,

    input  wire        enable_i,
    input  wire        invert_i,
    input  wire [31:0] period_i,
    input  wire [31:0] duty_i,

    output wire        pwm_o,
    output wire        active_o
);

reg [31:0] counter;

wire raw_pwm;

assign active_o = enable_i && (period_i != 0);

assign raw_pwm =
    active_o &&
    (counter < duty_i);

assign pwm_o =
    invert_i ? ~raw_pwm : raw_pwm;

always @(posedge clk) begin
    if (!resetn) begin
        counter <= 32'd0;
    end else if (!active_o) begin
        counter <= 32'd0;
    end else if (counter >= period_i - 1'b1) begin
        counter <= 32'd0;
    end else begin
        counter <= counter + 1'b1;
    end
end

endmodule
