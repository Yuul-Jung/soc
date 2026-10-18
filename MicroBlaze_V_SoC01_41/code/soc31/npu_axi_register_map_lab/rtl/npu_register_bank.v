module npu_register_bank (
    input  wire               clk,
    input  wire               resetn,

    // Register-write interface from AXI4-Lite shell.
    input  wire               wr_en_i,
    input  wire [7:0]         wr_addr_i,
    input  wire [31:0]        wr_data_i,
    input  wire [3:0]         wr_strb_i,

    // Register-read interface from AXI4-Lite shell.
    input  wire [7:0]         rd_addr_i,
    output reg  [31:0]        rd_data_o,

    // Optional debug/status outputs.
    output wire               accel_busy_o,
    output wire               accel_done_sticky_o,
    output wire               accel_error_sticky_o,
    output wire [7:0]         saturation_count_o
);

// ------------------------------------------------------------
// SoC 31 NPU Register Map
// ------------------------------------------------------------
//
// 0x00 CONTROL      RW/W1P
//      bit 0 START        : write 1 -> one-clock start pulse
//      bit 1 CLEAR_DONE   : write 1 -> clear DONE sticky
//      bit 2 CLEAR_ERROR  : write 1 -> clear ERROR sticky
//
// 0x04 STATUS       RO
//      bit 0 BUSY
//      bit 1 DONE_STICKY
//      bit 2 ERROR_STICKY
//      bit 3 SATURATED_ANY
//
// 0x08 VERSION      RO = 0x0001_0000
// 0x0C SAT_COUNT    RO
//
// 0x10 BIAS_CH0     RW signed int32
// 0x14 BIAS_CH1     RW signed int32
//
// 0x18 SCALE_CH0    RW
//      [15:0]  signed multiplier
//      [21:16] unsigned right shift
//
// 0x1C SCALE_CH1    RW
//      [15:0]  signed multiplier
//      [21:16] unsigned right shift
//
// 0x20 ZERO_POINT   RW
//      [15:0]  signed zp_ch0
//      [31:16] signed zp_ch1
//
// 0x40..0x5C ACC_IN[0..7] RW signed int32
//      0..3 -> CH0 sample0..3
//      4..7 -> CH1 sample0..3
//
// 0x60 OUT_CH0      RO four packed signed int8 values
// 0x64 OUT_CH1      RO four packed signed int8 values
// 0x68 CYCLE_COUNT  RO cycles from accepted START to accelerator DONE
//
// START while BUSY is rejected and sets ERROR_STICKY.
//
// Register bank and accelerator share one clock domain in SoC 31.

localparam [31:0] VERSION_VALUE = 32'h0001_0000;

// ------------------------------------------------------------
// Byte-write helper.
// ------------------------------------------------------------
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

// ------------------------------------------------------------
// Software-visible configuration registers.
// ------------------------------------------------------------
reg signed [31:0] bias_ch0_q;
reg signed [31:0] bias_ch1_q;

reg signed [15:0] mult_ch0_q;
reg signed [15:0] mult_ch1_q;

reg [5:0] shift_ch0_q;
reg [5:0] shift_ch1_q;

reg signed [15:0] zp_ch0_q;
reg signed [15:0] zp_ch1_q;

reg signed [31:0] acc_in_q [0:7];

// ------------------------------------------------------------
// Accelerator control/status.
// ------------------------------------------------------------
reg start_pulse_q;
reg done_sticky_q;
reg error_sticky_q;

wire accel_busy_w;
wire accel_done_w;
wire accel_result_valid_w;

wire [31:0] q_ch0_batch_w;
wire [31:0] q_ch1_batch_w;

wire [7:0] saturation_count_w;

reg [31:0] cycle_count_q;

wire control_write_w;

assign control_write_w =
    wr_en_i &&
    (wr_addr_i[7:2] == 6'h00);

wire start_request_w;

assign start_request_w =
    control_write_w &&
    wr_strb_i[0] &&
    wr_data_i[0];

wire clear_done_request_w;

assign clear_done_request_w =
    control_write_w &&
    wr_strb_i[0] &&
    wr_data_i[1];

wire clear_error_request_w;

assign clear_error_request_w =
    control_write_w &&
    wr_strb_i[0] &&
    wr_data_i[2];

assign accel_busy_o =
    accel_busy_w;

assign accel_done_sticky_o =
    done_sticky_q;

assign accel_error_sticky_o =
    error_sticky_q;

assign saturation_count_o =
    saturation_count_w;

// ------------------------------------------------------------
// Requantization accelerator from SoC 30.
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

// ------------------------------------------------------------
// Register write/control process.
// ------------------------------------------------------------
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

        cycle_count_q <= 32'd0;
    end else begin
        // W1P behavior: pulse returns low automatically.
        start_pulse_q <= 1'b0;

        // Sticky status clear requests.
        if (clear_done_request_w) begin
            done_sticky_q <= 1'b0;
        end

        if (clear_error_request_w) begin
            error_sticky_q <= 1'b0;
        end

        // Accelerator completion wins after clear in the same clock.
        if (accel_done_w) begin
            done_sticky_q <= 1'b1;
        end

        // START:
        // - accepted only while idle
        // - clears previous DONE
        // - START while BUSY becomes sticky error
        if (start_request_w) begin
            if (accel_busy_w) begin
                error_sticky_q <= 1'b1;
            end else begin
                start_pulse_q <= 1'b1;
                done_sticky_q <= 1'b0;
                cycle_count_q <= 32'd0;
            end
        end

        if (accel_busy_w) begin
            cycle_count_q <= cycle_count_q + 32'd1;
        end

        // Configuration/input writes.
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

// ------------------------------------------------------------
// Register read mux.
// ------------------------------------------------------------
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

        default: rd_data_o = 32'h0000_0000;
    endcase
end

endmodule
