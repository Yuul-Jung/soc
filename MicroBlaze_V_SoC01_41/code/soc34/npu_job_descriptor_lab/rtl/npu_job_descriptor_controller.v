module npu_job_descriptor_controller (
    input  wire               clk,
    input  wire               resetn,

    // Software-visible register interface.
    input  wire               wr_en_i,
    input  wire [7:0]         wr_addr_i,
    input  wire [31:0]        wr_data_i,
    input  wire [3:0]         wr_strb_i,

    input  wire [7:0]         rd_addr_i,
    output reg  [31:0]        rd_data_o,

    // Job engine handshake/status.
    output reg                job_start_o,

    output reg  [11:0]        active_input_base_o,
    output reg  [11:0]        active_output_base_o,
    output reg  [15:0]        active_length_words_o,

    output reg signed [31:0]  active_bias_ch0_o,
    output reg signed [31:0]  active_bias_ch1_o,

    output reg signed [15:0]  active_mult_ch0_o,
    output reg signed [15:0]  active_mult_ch1_o,

    output reg        [5:0]   active_shift_ch0_o,
    output reg        [5:0]   active_shift_ch1_o,

    output reg signed [15:0]  active_zp_ch0_o,
    output reg signed [15:0]  active_zp_ch1_o,

    input  wire               engine_busy_i,
    input  wire               engine_done_i,
    input  wire               engine_error_i,

    input  wire [15:0]        read_word_count_i,
    input  wire [15:0]        write_word_count_i,

    output wire               busy_o,
    output reg                done_sticky_o,
    output reg                error_sticky_o,
    output reg  [7:0]         error_code_o,
    output reg  [31:0]        job_id_o
);

// ------------------------------------------------------------
// SoC 34 · Job Descriptor / Command Controller
// ------------------------------------------------------------
//
// Register map:
//
// 0x00 CONTROL          W1P
//      bit0 START
//      bit1 CLEAR_DONE
//      bit2 CLEAR_ERROR
//
// 0x04 STATUS           RO
//      bit0 BUSY
//      bit1 DONE_STICKY
//      bit2 ERROR_STICKY
//      bit3 DESCRIPTOR_VALID
//
// 0x08 VERSION          RO = 0x0001_0000
// 0x0C JOB_ID           RO
//
// Shadow descriptor:
// 0x10 INPUT_BASE       RW byte address, 4-byte aligned
// 0x14 OUTPUT_BASE      RW byte address, 4-byte aligned
// 0x18 LENGTH_WORDS     RW
// 0x1C ERROR_CODE       RO
//
// Kernel parameters:
// 0x20 BIAS_CH0         RW
// 0x24 BIAS_CH1         RW
// 0x28 SCALE_CH0        RW [15:0] multiplier, [21:16] shift
// 0x2C SCALE_CH1        RW
// 0x30 ZERO_POINT       RW [15:0] CH0, [31:16] CH1
//
// Active descriptor snapshot:
// 0x34 ACTIVE_INPUT     RO
// 0x38 ACTIVE_OUTPUT    RO
// 0x3C ACTIVE_LENGTH    RO
//
// Engine counters:
// 0x40 READ_WORD_COUNT  RO
// 0x44 WRITE_WORD_COUNT RO
//
// Current teaching kernel still consumes exactly 8 int32 input words
// and produces two packed 32-bit output words.
// LENGTH_WORDS therefore must be 8 in SoC 34.
//
// SoC 35 will integrate this controller with the full accelerator
// system while retaining the descriptor concept.

localparam [31:0] VERSION_VALUE = 32'h0001_0000;

localparam [7:0] ERR_NONE               = 8'd0;
localparam [7:0] ERR_BUSY               = 8'd1;
localparam [7:0] ERR_INPUT_ALIGN        = 8'd2;
localparam [7:0] ERR_OUTPUT_ALIGN       = 8'd3;
localparam [7:0] ERR_LENGTH_UNSUPPORTED = 8'd4;
localparam [7:0] ERR_INPUT_RANGE        = 8'd5;
localparam [7:0] ERR_OUTPUT_RANGE       = 8'd6;
localparam [7:0] ERR_BUFFER_OVERLAP     = 8'd7;
localparam [7:0] ERR_ENGINE             = 8'd8;

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
// Shadow descriptor.
// ------------------------------------------------------------
reg [11:0] shadow_input_base_q;
reg [11:0] shadow_output_base_q;
reg [15:0] shadow_length_words_q;

reg signed [31:0] shadow_bias_ch0_q;
reg signed [31:0] shadow_bias_ch1_q;

reg signed [15:0] shadow_mult_ch0_q;
reg signed [15:0] shadow_mult_ch1_q;

reg [5:0] shadow_shift_ch0_q;
reg [5:0] shadow_shift_ch1_q;

reg signed [15:0] shadow_zp_ch0_q;
reg signed [15:0] shadow_zp_ch1_q;

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

assign busy_o =
    engine_busy_i;

// ------------------------------------------------------------
// Descriptor validation.
//
// BRAM byte-address range: 0x000..0xFFF.
// Current input span: LENGTH_WORDS * 4 bytes.
// Current output span: 8 bytes.
// ------------------------------------------------------------
wire input_aligned_w;
wire output_aligned_w;
wire length_supported_w;

wire [16:0] input_end_exclusive_w;
wire [12:0] output_end_exclusive_w;

wire input_range_ok_w;
wire output_range_ok_w;

wire no_overlap_w;
wire descriptor_valid_w;

assign input_aligned_w =
    (shadow_input_base_q[1:0] == 2'b00);

assign output_aligned_w =
    (shadow_output_base_q[1:0] == 2'b00);

assign length_supported_w =
    (shadow_length_words_q == 16'd8);

assign input_end_exclusive_w =
    {5'd0, shadow_input_base_q} +
    ({1'b0, shadow_length_words_q} << 2);

assign output_end_exclusive_w =
    {1'b0, shadow_output_base_q} +
    13'd8;

assign input_range_ok_w =
    (input_end_exclusive_w <= 17'h01000);

assign output_range_ok_w =
    (output_end_exclusive_w <= 13'h1000);

assign no_overlap_w =
    (
        output_end_exclusive_w <=
        {1'b0, shadow_input_base_q}
    ) ||
    (
        input_end_exclusive_w <=
        {5'd0, shadow_output_base_q}
    );

assign descriptor_valid_w =
    input_aligned_w &&
    output_aligned_w &&
    length_supported_w &&
    input_range_ok_w &&
    output_range_ok_w &&
    no_overlap_w;

function [7:0] descriptor_error_code;
    input dummy;

    begin
        if (!input_aligned_w)
            descriptor_error_code = ERR_INPUT_ALIGN;
        else if (!output_aligned_w)
            descriptor_error_code = ERR_OUTPUT_ALIGN;
        else if (!length_supported_w)
            descriptor_error_code = ERR_LENGTH_UNSUPPORTED;
        else if (!input_range_ok_w)
            descriptor_error_code = ERR_INPUT_RANGE;
        else if (!output_range_ok_w)
            descriptor_error_code = ERR_OUTPUT_RANGE;
        else if (!no_overlap_w)
            descriptor_error_code = ERR_BUFFER_OVERLAP;
        else
            descriptor_error_code = ERR_NONE;
    end
endfunction

reg [31:0] merged_w;

// ------------------------------------------------------------
// Register / command process.
// ------------------------------------------------------------
always @(posedge clk) begin
    if (!resetn) begin
        shadow_input_base_q <= 12'h000;
        shadow_output_base_q <= 12'h100;
        shadow_length_words_q <= 16'd8;

        shadow_bias_ch0_q <= 32'sd0;
        shadow_bias_ch1_q <= 32'sd4;

        shadow_mult_ch0_q <= 16'sd1;
        shadow_mult_ch1_q <= 16'sd3;

        shadow_shift_ch0_q <= 6'd1;
        shadow_shift_ch1_q <= 6'd1;

        shadow_zp_ch0_q <= 16'sd0;
        shadow_zp_ch1_q <= -16'sd3;

        active_input_base_o <= 12'h000;
        active_output_base_o <= 12'h100;
        active_length_words_o <= 16'd8;

        active_bias_ch0_o <= 32'sd0;
        active_bias_ch1_o <= 32'sd4;

        active_mult_ch0_o <= 16'sd1;
        active_mult_ch1_o <= 16'sd3;

        active_shift_ch0_o <= 6'd1;
        active_shift_ch1_o <= 6'd1;

        active_zp_ch0_o <= 16'sd0;
        active_zp_ch1_o <= -16'sd3;

        job_start_o <= 1'b0;

        done_sticky_o <= 1'b0;
        error_sticky_o <= 1'b0;
        error_code_o <= ERR_NONE;

        job_id_o <= 32'd0;
    end else begin
        job_start_o <= 1'b0;

        if (clear_done_request_w) begin
            done_sticky_o <= 1'b0;
        end

        if (clear_error_request_w) begin
            error_sticky_o <= 1'b0;
            error_code_o <= ERR_NONE;
        end

        if (engine_done_i) begin
            done_sticky_o <= 1'b1;
        end

        if (engine_error_i) begin
            error_sticky_o <= 1'b1;
            error_code_o <= ERR_ENGINE;
        end

        // START snapshots the descriptor only when valid and idle.
        if (start_request_w) begin
            if (engine_busy_i) begin
                error_sticky_o <= 1'b1;
                error_code_o <= ERR_BUSY;
            end else if (!descriptor_valid_w) begin
                error_sticky_o <= 1'b1;
                error_code_o <= descriptor_error_code(1'b0);
            end else begin
                active_input_base_o <= shadow_input_base_q;
                active_output_base_o <= shadow_output_base_q;
                active_length_words_o <= shadow_length_words_q;

                active_bias_ch0_o <= shadow_bias_ch0_q;
                active_bias_ch1_o <= shadow_bias_ch1_q;

                active_mult_ch0_o <= shadow_mult_ch0_q;
                active_mult_ch1_o <= shadow_mult_ch1_q;

                active_shift_ch0_o <= shadow_shift_ch0_q;
                active_shift_ch1_o <= shadow_shift_ch1_q;

                active_zp_ch0_o <= shadow_zp_ch0_q;
                active_zp_ch1_o <= shadow_zp_ch1_q;

                job_start_o <= 1'b1;

                done_sticky_o <= 1'b0;
                error_sticky_o <= 1'b0;
                error_code_o <= ERR_NONE;

                job_id_o <= job_id_o + 32'd1;
            end
        end

        // Shadow descriptor/register writes are legal while a job runs.
        // They do not affect the current active snapshot.
        if (wr_en_i) begin
            case (wr_addr_i[7:2])
                6'h04: begin
                    merged_w = apply_wstrb32(
                        {20'd0, shadow_input_base_q},
                        wr_data_i,
                        wr_strb_i
                    );
                    shadow_input_base_q <= merged_w[11:0];
                end

                6'h05: begin
                    merged_w = apply_wstrb32(
                        {20'd0, shadow_output_base_q},
                        wr_data_i,
                        wr_strb_i
                    );
                    shadow_output_base_q <= merged_w[11:0];
                end

                6'h06: begin
                    merged_w = apply_wstrb32(
                        {16'd0, shadow_length_words_q},
                        wr_data_i,
                        wr_strb_i
                    );
                    shadow_length_words_q <= merged_w[15:0];
                end

                6'h08: begin
                    merged_w = apply_wstrb32(
                        shadow_bias_ch0_q,
                        wr_data_i,
                        wr_strb_i
                    );
                    shadow_bias_ch0_q <= $signed(merged_w);
                end

                6'h09: begin
                    merged_w = apply_wstrb32(
                        shadow_bias_ch1_q,
                        wr_data_i,
                        wr_strb_i
                    );
                    shadow_bias_ch1_q <= $signed(merged_w);
                end

                6'h0A: begin
                    merged_w = apply_wstrb32(
                        {
                            10'd0,
                            shadow_shift_ch0_q,
                            shadow_mult_ch0_q
                        },
                        wr_data_i,
                        wr_strb_i
                    );

                    shadow_mult_ch0_q <=
                        $signed(merged_w[15:0]);

                    shadow_shift_ch0_q <=
                        merged_w[21:16];
                end

                6'h0B: begin
                    merged_w = apply_wstrb32(
                        {
                            10'd0,
                            shadow_shift_ch1_q,
                            shadow_mult_ch1_q
                        },
                        wr_data_i,
                        wr_strb_i
                    );

                    shadow_mult_ch1_q <=
                        $signed(merged_w[15:0]);

                    shadow_shift_ch1_q <=
                        merged_w[21:16];
                end

                6'h0C: begin
                    merged_w = apply_wstrb32(
                        {
                            shadow_zp_ch1_q,
                            shadow_zp_ch0_q
                        },
                        wr_data_i,
                        wr_strb_i
                    );

                    shadow_zp_ch0_q <=
                        $signed(merged_w[15:0]);

                    shadow_zp_ch1_q <=
                        $signed(merged_w[31:16]);
                end

                default: begin
                end
            endcase
        end
    end
end

// ------------------------------------------------------------
// Read mux.
// ------------------------------------------------------------
always @(*) begin
    case (rd_addr_i[7:2])
        6'h00: rd_data_o = 32'h0000_0000;

        6'h01: rd_data_o = {
            28'd0,
            descriptor_valid_w,
            error_sticky_o,
            done_sticky_o,
            engine_busy_i
        };

        6'h02: rd_data_o = VERSION_VALUE;
        6'h03: rd_data_o = job_id_o;

        6'h04: rd_data_o = {20'd0, shadow_input_base_q};
        6'h05: rd_data_o = {20'd0, shadow_output_base_q};
        6'h06: rd_data_o = {16'd0, shadow_length_words_q};
        6'h07: rd_data_o = {24'd0, error_code_o};

        6'h08: rd_data_o = shadow_bias_ch0_q;
        6'h09: rd_data_o = shadow_bias_ch1_q;

        6'h0A: rd_data_o = {
            10'd0,
            shadow_shift_ch0_q,
            shadow_mult_ch0_q
        };

        6'h0B: rd_data_o = {
            10'd0,
            shadow_shift_ch1_q,
            shadow_mult_ch1_q
        };

        6'h0C: rd_data_o = {
            shadow_zp_ch1_q,
            shadow_zp_ch0_q
        };

        6'h0D: rd_data_o = {20'd0, active_input_base_o};
        6'h0E: rd_data_o = {20'd0, active_output_base_o};
        6'h0F: rd_data_o = {16'd0, active_length_words_o};

        6'h10: rd_data_o = {16'd0, read_word_count_i};
        6'h11: rd_data_o = {16'd0, write_word_count_i};

        default: rd_data_o = 32'h0000_0000;
    endcase
end

endmodule
