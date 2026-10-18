module npu_register_bank_irq (
    input  wire               clk,
    input  wire               resetn,

    input  wire               wr_en_i,
    input  wire [7:0]         wr_addr_i,
    input  wire [31:0]        wr_data_i,
    input  wire [3:0]         wr_strb_i,

    input  wire [7:0]         rd_addr_i,
    output reg  [31:0]        rd_data_o,

    output wire               irq_o,

    output wire               accel_busy_o,
    output wire               accel_done_sticky_o,
    output wire               accel_error_sticky_o,
    output wire [7:0]         saturation_count_o
);

// ------------------------------------------------------------
// SoC 32 · NPU Interrupt Register Bank
// ------------------------------------------------------------
//
// Existing SoC 31 map:
//
// 0x00 CONTROL      W1P
// 0x04 STATUS       RO
// 0x08 VERSION      RO
// 0x0C SAT_COUNT    RO
// 0x10 BIAS_CH0     RW
// 0x14 BIAS_CH1     RW
// 0x18 SCALE_CH0    RW
// 0x1C SCALE_CH1    RW
// 0x20 ZERO_POINT   RW
// 0x40..0x5C ACC_IN0..7 RW
// 0x60 OUT_CH0      RO
// 0x64 OUT_CH1      RO
// 0x68 CYCLE_COUNT  RO
//
// SoC 32 additions:
//
// 0x6C IRQ_ENABLE   RW
//      bit 0 DONE IRQ enable
//      bit 1 ERROR IRQ enable
//
// 0x70 IRQ_STATUS   RO / W1C
//      bit 0 DONE event pending
//      bit 1 ERROR event pending
//
// Level interrupt:
//
//   irq_o = |(IRQ_ENABLE & IRQ_STATUS)
//
// IRQ_STATUS remains set until software writes 1 to the
// corresponding bit. Event set wins over W1C clear if both
// happen in the same clock.

localparam [31:0] VERSION_VALUE = 32'h0001_0000;

function [31:0] apply_wstrb32;
    input [31:0] old_value;
    input [31:0] new_value;
    input [3:0]  strb;

    integer byte_index;

    begin
        apply_wstrb32 = old_value;

        for (
            byte_index = 0;
            byte_index < 4;
            byte_index = byte_index + 1
        ) begin
            if (strb[byte_index]) begin
                apply_wstrb32[
                    (byte_index * 8) +: 8
                ] =
                    new_value[
                        (byte_index * 8) +: 8
                    ];
            end
        end
    end
endfunction

reg signed [31:0] bias_ch0_q;
reg signed [31:0] bias_ch1_q;

reg signed [15:0] mult_ch0_q;
reg signed [15:0] mult_ch1_q;

reg [5:0] shift_ch0_q;
reg [5:0] shift_ch1_q;

reg signed [15:0] zp_ch0_q;
reg signed [15:0] zp_ch1_q;

reg signed [31:0] acc_in_q [0:7];

reg start_pulse_q;
reg done_sticky_q;
reg error_sticky_q;

reg [1:0] irq_enable_q;
reg [1:0] irq_status_q;

wire accel_busy_w;
wire accel_done_w;
wire accel_result_valid_w;

wire [31:0] q_ch0_batch_w;
wire [31:0] q_ch1_batch_w;

wire [7:0] saturation_count_w;

reg [31:0] cycle_count_q;

assign accel_busy_o = accel_busy_w;
assign accel_done_sticky_o = done_sticky_q;
assign accel_error_sticky_o = error_sticky_q;
assign saturation_count_o = saturation_count_w;

assign irq_o =
    |(irq_enable_q & irq_status_q);

// ------------------------------------------------------------
// CONTROL decode.
// ------------------------------------------------------------
wire control_write_w;

assign control_write_w =
    wr_en_i &&
    (wr_addr_i[7:2] == 6'h00);

wire start_request_w;
wire clear_done_request_w;
wire clear_error_request_w;

assign start_request_w =
    control_write_w &&
    wr_strb_i[0] &&
    wr_data_i[0];

assign clear_done_request_w =
    control_write_w &&
    wr_strb_i[0] &&
    wr_data_i[1];

assign clear_error_request_w =
    control_write_w &&
    wr_strb_i[0] &&
    wr_data_i[2];

// ------------------------------------------------------------
// IRQ decode.
// ------------------------------------------------------------
wire irq_enable_write_w;
wire irq_status_write_w;

assign irq_enable_write_w =
    wr_en_i &&
    (wr_addr_i[7:2] == 6'h1B);

assign irq_status_write_w =
    wr_en_i &&
    (wr_addr_i[7:2] == 6'h1C);

wire [1:0] irq_clear_mask_w;

assign irq_clear_mask_w =
    irq_status_write_w &&
    wr_strb_i[0]
    ? wr_data_i[1:0]
    : 2'b00;

// ------------------------------------------------------------
// Event generation.
// ------------------------------------------------------------
wire error_event_w;

assign error_event_w =
    start_request_w &&
    accel_busy_w;

wire [1:0] irq_event_set_w;

assign irq_event_set_w = {
    error_event_w,
    accel_done_w
};

wire [1:0] irq_status_after_clear_w;
wire [1:0] irq_status_next_w;

assign irq_status_after_clear_w =
    irq_status_q &
    ~irq_clear_mask_w;

assign irq_status_next_w =
    irq_status_after_clear_w |
    irq_event_set_w;

wire done_sticky_next_w;
wire error_sticky_next_w;

assign done_sticky_next_w =
    (done_sticky_q && !clear_done_request_w) ||
    accel_done_w;

assign error_sticky_next_w =
    (error_sticky_q && !clear_error_request_w) ||
    error_event_w;

// ------------------------------------------------------------
// SoC 30 accelerator reused unchanged.
// ------------------------------------------------------------
wire [127:0] acc_ch0_batch_w;
wire [127:0] acc_ch1_batch_w;

assign acc_ch0_batch_w = {
    acc_in_q[3],
    acc_in_q[2],
    acc_in_q[1],
    acc_in_q[0]
};

assign acc_ch1_batch_w = {
    acc_in_q[7],
    acc_in_q[6],
    acc_in_q[5],
    acc_in_q[4]
};

requantize_batch2x4_serial u_accelerator (
    .clk(clk),
    .resetn(resetn),

    .start_i(start_pulse_q),

    .acc_ch0_batch_i(acc_ch0_batch_w),
    .acc_ch1_batch_i(acc_ch1_batch_w),

    .bias_ch0_i(bias_ch0_q),
    .bias_ch1_i(bias_ch1_q),

    .mult_ch0_i(mult_ch0_q),
    .mult_ch1_i(mult_ch1_q),

    .shift_ch0_i(shift_ch0_q),
    .shift_ch1_i(shift_ch1_q),

    .zp_ch0_i(zp_ch0_q),
    .zp_ch1_i(zp_ch1_q),

    .busy_o(accel_busy_w),
    .done_o(accel_done_w),
    .result_valid_o(accel_result_valid_w),

    .q_ch0_batch_o(q_ch0_batch_w),
    .q_ch1_batch_o(q_ch1_batch_w),

    .saturation_count_o(saturation_count_w)
);

integer i;
reg [31:0] merged_w;

always @(posedge clk) begin
    if (!resetn) begin
        bias_ch0_q <= 32'sd0;
        bias_ch1_q <= 32'sd0;

        mult_ch0_q <= 16'sd1;
        mult_ch1_q <= 16'sd1;

        shift_ch0_q <= 6'd0;
        shift_ch1_q <= 6'd0;

        zp_ch0_q <= 16'sd0;
        zp_ch1_q <= 16'sd0;

        for (i = 0; i < 8; i = i + 1) begin
            acc_in_q[i] <= 32'sd0;
        end

        start_pulse_q  <= 1'b0;
        done_sticky_q  <= 1'b0;
        error_sticky_q <= 1'b0;

        irq_enable_q <= 2'b00;
        irq_status_q <= 2'b00;

        cycle_count_q <= 32'd0;
    end else begin
        start_pulse_q <= 1'b0;

        done_sticky_q  <= done_sticky_next_w;
        error_sticky_q <= error_sticky_next_w;
        irq_status_q   <= irq_status_next_w;

        if (
            start_request_w &&
            !accel_busy_w
        ) begin
            start_pulse_q <= 1'b1;
            done_sticky_q <= 1'b0;
            cycle_count_q <= 32'd0;
        end

        if (accel_busy_w) begin
            cycle_count_q <=
                cycle_count_q + 32'd1;
        end

        if (irq_enable_write_w) begin
            merged_w = apply_wstrb32(
                {30'd0, irq_enable_q},
                wr_data_i,
                wr_strb_i
            );

            irq_enable_q <=
                merged_w[1:0];
        end

        if (wr_en_i) begin
            case (wr_addr_i[7:2])
                6'h04: begin
                    merged_w = apply_wstrb32(
                        bias_ch0_q,
                        wr_data_i,
                        wr_strb_i
                    );
                    bias_ch0_q <= $signed(merged_w);
                end

                6'h05: begin
                    merged_w = apply_wstrb32(
                        bias_ch1_q,
                        wr_data_i,
                        wr_strb_i
                    );
                    bias_ch1_q <= $signed(merged_w);
                end

                6'h06: begin
                    merged_w = apply_wstrb32(
                        {
                            10'd0,
                            shift_ch0_q,
                            mult_ch0_q
                        },
                        wr_data_i,
                        wr_strb_i
                    );

                    mult_ch0_q <=
                        $signed(merged_w[15:0]);

                    shift_ch0_q <=
                        merged_w[21:16];
                end

                6'h07: begin
                    merged_w = apply_wstrb32(
                        {
                            10'd0,
                            shift_ch1_q,
                            mult_ch1_q
                        },
                        wr_data_i,
                        wr_strb_i
                    );

                    mult_ch1_q <=
                        $signed(merged_w[15:0]);

                    shift_ch1_q <=
                        merged_w[21:16];
                end

                6'h08: begin
                    merged_w = apply_wstrb32(
                        {
                            zp_ch1_q,
                            zp_ch0_q
                        },
                        wr_data_i,
                        wr_strb_i
                    );

                    zp_ch0_q <=
                        $signed(merged_w[15:0]);

                    zp_ch1_q <=
                        $signed(merged_w[31:16]);
                end

                6'h10: begin
                    merged_w = apply_wstrb32(
                        acc_in_q[0],
                        wr_data_i,
                        wr_strb_i
                    );
                    acc_in_q[0] <= $signed(merged_w);
                end

                6'h11: begin
                    merged_w = apply_wstrb32(
                        acc_in_q[1],
                        wr_data_i,
                        wr_strb_i
                    );
                    acc_in_q[1] <= $signed(merged_w);
                end

                6'h12: begin
                    merged_w = apply_wstrb32(
                        acc_in_q[2],
                        wr_data_i,
                        wr_strb_i
                    );
                    acc_in_q[2] <= $signed(merged_w);
                end

                6'h13: begin
                    merged_w = apply_wstrb32(
                        acc_in_q[3],
                        wr_data_i,
                        wr_strb_i
                    );
                    acc_in_q[3] <= $signed(merged_w);
                end

                6'h14: begin
                    merged_w = apply_wstrb32(
                        acc_in_q[4],
                        wr_data_i,
                        wr_strb_i
                    );
                    acc_in_q[4] <= $signed(merged_w);
                end

                6'h15: begin
                    merged_w = apply_wstrb32(
                        acc_in_q[5],
                        wr_data_i,
                        wr_strb_i
                    );
                    acc_in_q[5] <= $signed(merged_w);
                end

                6'h16: begin
                    merged_w = apply_wstrb32(
                        acc_in_q[6],
                        wr_data_i,
                        wr_strb_i
                    );
                    acc_in_q[6] <= $signed(merged_w);
                end

                6'h17: begin
                    merged_w = apply_wstrb32(
                        acc_in_q[7],
                        wr_data_i,
                        wr_strb_i
                    );
                    acc_in_q[7] <= $signed(merged_w);
                end

                default: begin
                end
            endcase
        end
    end
end

always @(*) begin
    case (rd_addr_i[7:2])
        6'h00: rd_data_o = 32'h0000_0000;

        6'h01: rd_data_o = {
            28'd0,
            (saturation_count_w != 8'd0),
            error_sticky_q,
            done_sticky_q,
            accel_busy_w
        };

        6'h02: rd_data_o = VERSION_VALUE;

        6'h03: rd_data_o = {
            24'd0,
            saturation_count_w
        };

        6'h04: rd_data_o = bias_ch0_q;
        6'h05: rd_data_o = bias_ch1_q;

        6'h06: rd_data_o = {
            10'd0,
            shift_ch0_q,
            mult_ch0_q
        };

        6'h07: rd_data_o = {
            10'd0,
            shift_ch1_q,
            mult_ch1_q
        };

        6'h08: rd_data_o = {
            zp_ch1_q,
            zp_ch0_q
        };

        6'h10: rd_data_o = acc_in_q[0];
        6'h11: rd_data_o = acc_in_q[1];
        6'h12: rd_data_o = acc_in_q[2];
        6'h13: rd_data_o = acc_in_q[3];

        6'h14: rd_data_o = acc_in_q[4];
        6'h15: rd_data_o = acc_in_q[5];
        6'h16: rd_data_o = acc_in_q[6];
        6'h17: rd_data_o = acc_in_q[7];

        6'h18: rd_data_o = q_ch0_batch_w;
        6'h19: rd_data_o = q_ch1_batch_w;
        6'h1A: rd_data_o = cycle_count_q;

        6'h1B: rd_data_o = {
            30'd0,
            irq_enable_q
        };

        6'h1C: rd_data_o = {
            30'd0,
            irq_status_q
        };

        default: rd_data_o = 32'h0000_0000;
    endcase
end

endmodule
