module pwm_register_bank (
    input  wire        clk,
    input  wire        resetn,

    input  wire        wr_en,
    input  wire [7:0]  wr_offset,
    input  wire [31:0] wr_data,
    input  wire [3:0]  wr_strb,

    input  wire [7:0]  rd_offset,
    output reg  [31:0] rd_data,

    input  wire        active_i,
    input  wire        error_i,
    input  wire [31:0] active_period_i,
    input  wire [31:0] active_duty_i,

    output reg         enable_o,
    output reg         invert_o,
    output reg  [31:0] period_shadow_o,
    output reg  [31:0] duty_shadow_o,
    output reg         update_pulse_o,
    output reg         clear_error_pulse_o
);

localparam [7:0] REG_CONTROL       = 8'h00;
localparam [7:0] REG_PERIOD_SHADOW = 8'h04;
localparam [7:0] REG_DUTY_SHADOW   = 8'h08;
localparam [7:0] REG_COMMAND       = 8'h0C;
localparam [7:0] REG_STATUS        = 8'h10;
localparam [7:0] REG_ACTIVE_PERIOD = 8'h14;
localparam [7:0] REG_ACTIVE_DUTY   = 8'h18;
localparam [7:0] REG_ID            = 8'h1C;
localparam [7:0] REG_VERSION       = 8'h20;

localparam [31:0] ID_VALUE      = 32'h5057_4D31; // ASCII "PWM1"
localparam [31:0] VERSION_VALUE = 32'h0001_0000;

integer byte_index;

always @(posedge clk) begin
    if (!resetn) begin
        enable_o            <= 1'b0;
        invert_o            <= 1'b0;
        period_shadow_o     <= 32'd1000;
        duty_shadow_o       <= 32'd500;
        update_pulse_o      <= 1'b0;
        clear_error_pulse_o <= 1'b0;
    end else begin
        update_pulse_o      <= 1'b0;
        clear_error_pulse_o <= 1'b0;

        if (wr_en) begin
            case (wr_offset)
                REG_CONTROL: begin
                    if (wr_strb[0]) begin
                        enable_o <= wr_data[0];
                        invert_o <= wr_data[1];
                    end
                end

                REG_PERIOD_SHADOW: begin
                    for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1) begin
                        if (wr_strb[byte_index]) begin
                            period_shadow_o[byte_index*8 +: 8] <=
                                wr_data[byte_index*8 +: 8];
                        end
                    end
                end

                REG_DUTY_SHADOW: begin
                    for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1) begin
                        if (wr_strb[byte_index]) begin
                            duty_shadow_o[byte_index*8 +: 8] <=
                                wr_data[byte_index*8 +: 8];
                        end
                    end
                end

                REG_COMMAND: begin
                    if (wr_strb[0]) begin
                        update_pulse_o      <= wr_data[0];
                        clear_error_pulse_o <= wr_data[1];
                    end
                end

                default: begin
                end
            endcase
        end
    end
end

always @(*) begin
    case (rd_offset)
        REG_CONTROL:
            rd_data = {30'h0, invert_o, enable_o};

        REG_PERIOD_SHADOW:
            rd_data = period_shadow_o;

        REG_DUTY_SHADOW:
            rd_data = duty_shadow_o;

        REG_COMMAND:
            rd_data = 32'h0000_0000;

        REG_STATUS:
            rd_data = {30'h0, error_i, active_i};

        REG_ACTIVE_PERIOD:
            rd_data = active_period_i;

        REG_ACTIVE_DUTY:
            rd_data = active_duty_i;

        REG_ID:
            rd_data = ID_VALUE;

        REG_VERSION:
            rd_data = VERSION_VALUE;

        default:
            rd_data = 32'h0000_0000;
    endcase
end

endmodule
