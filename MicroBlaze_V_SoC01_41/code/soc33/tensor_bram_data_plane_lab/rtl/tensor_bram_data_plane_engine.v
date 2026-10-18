module tensor_bram_data_plane_engine (
    input  wire                 clk,
    input  wire                 resetn,

    input  wire                 start_i,

    input  wire signed [31:0]   bias_ch0_i,
    input  wire signed [31:0]   bias_ch1_i,

    input  wire signed [15:0]   mult_ch0_i,
    input  wire signed [15:0]   mult_ch1_i,

    input  wire        [5:0]    shift_ch0_i,
    input  wire        [5:0]    shift_ch1_i,

    input  wire signed [15:0]   zp_ch0_i,
    input  wire signed [15:0]   zp_ch1_i,

    output wire                 busy_o,
    output reg                  done_o,
    output reg                  error_o,

    // Native BRAM Port B.
    output reg                  bram_en_o,
    output reg  [3:0]           bram_we_o,
    output reg  [11:0]          bram_addr_o,
    output reg  [31:0]          bram_wdata_o,
    input  wire [31:0]          bram_rdata_i,

    output reg  [15:0]          read_word_count_o,
    output reg  [15:0]          write_word_count_o
);

// ------------------------------------------------------------
// SoC 33 Data Plane
// ------------------------------------------------------------
//
// Fixed teaching memory map:
//
// Input int32 tensor:
//   0x000 CH0 sample0
//   0x004 CH0 sample1
//   0x008 CH0 sample2
//   0x00C CH0 sample3
//   0x010 CH1 sample0
//   0x014 CH1 sample1
//   0x018 CH1 sample2
//   0x01C CH1 sample3
//
// Output packed int8 tensor:
//   0x100 OUT_CH0 = four signed int8 values
//   0x104 OUT_CH1 = four signed int8 values
//
// SoC 34 will replace these fixed addresses with programmable
// descriptor/base registers.
//
// BRAM read latency:
//   request clock -> synchronous BRAM output update
//   next engine state captures bram_rdata_i
// ------------------------------------------------------------

localparam [11:0] INPUT_BASE_ADDR     = 12'h000;
localparam [11:0] OUTPUT_CH0_ADDR     = 12'h100;
localparam [11:0] OUTPUT_CH1_ADDR     = 12'h104;

localparam [3:0] ST_IDLE          = 4'd0;
localparam [3:0] ST_READ_REQ      = 4'd1;
localparam [3:0] ST_READ_CAPTURE  = 4'd2;
localparam [3:0] ST_START_REQUANT = 4'd3;
localparam [3:0] ST_WAIT_RESULT   = 4'd4;
localparam [3:0] ST_WRITE_CH0     = 4'd5;
localparam [3:0] ST_WRITE_CH1     = 4'd6;
localparam [3:0] ST_DONE          = 4'd7;

reg [3:0] state_q;
reg [3:0] read_index_q;

reg [127:0] acc_ch0_batch_q;
reg [127:0] acc_ch1_batch_q;

reg requant_start_q;

wire requant_busy_w;
wire requant_done_w;
wire requant_result_valid_w;

wire [31:0] q_ch0_batch_w;
wire [31:0] q_ch1_batch_w;

wire [7:0] saturation_count_w;

assign busy_o =
    (state_q != ST_IDLE) &&
    (state_q != ST_DONE);

requantize_batch2x4_serial u_requant_batch (
    .clk(clk),
    .resetn(resetn),

    .start_i(requant_start_q),

    .acc_ch0_batch_i(acc_ch0_batch_q),
    .acc_ch1_batch_i(acc_ch1_batch_q),

    .bias_ch0_i(bias_ch0_i),
    .bias_ch1_i(bias_ch1_i),

    .mult_ch0_i(mult_ch0_i),
    .mult_ch1_i(mult_ch1_i),

    .shift_ch0_i(shift_ch0_i),
    .shift_ch1_i(shift_ch1_i),

    .zp_ch0_i(zp_ch0_i),
    .zp_ch1_i(zp_ch1_i),

    .busy_o(requant_busy_w),
    .done_o(requant_done_w),
    .result_valid_o(requant_result_valid_w),

    .q_ch0_batch_o(q_ch0_batch_w),
    .q_ch1_batch_o(q_ch1_batch_w),

    .saturation_count_o(saturation_count_w)
);

// ------------------------------------------------------------
// Native BRAM Port B output policy.
// ------------------------------------------------------------
always @(*) begin
    bram_en_o    = 1'b0;
    bram_we_o    = 4'b0000;
    bram_addr_o  = 12'h000;
    bram_wdata_o = 32'h0000_0000;

    case (state_q)
        ST_READ_REQ: begin
            bram_en_o = 1'b1;
            bram_we_o = 4'b0000;

            // Each int32 input occupies one 32-bit word.
            bram_addr_o =
                INPUT_BASE_ADDR +
                {read_index_q, 2'b00};
        end

        ST_WRITE_CH0: begin
            bram_en_o    = 1'b1;
            bram_we_o    = 4'b1111;
            bram_addr_o  = OUTPUT_CH0_ADDR;
            bram_wdata_o = q_ch0_batch_w;
        end

        ST_WRITE_CH1: begin
            bram_en_o    = 1'b1;
            bram_we_o    = 4'b1111;
            bram_addr_o  = OUTPUT_CH1_ADDR;
            bram_wdata_o = q_ch1_batch_w;
        end

        default: begin
        end
    endcase
end

// ------------------------------------------------------------
// Data-plane controller.
// ------------------------------------------------------------
always @(posedge clk) begin
    if (!resetn) begin
        state_q <= ST_IDLE;

        read_index_q <= 4'd0;

        acc_ch0_batch_q <= 128'd0;
        acc_ch1_batch_q <= 128'd0;

        requant_start_q <= 1'b0;

        done_o  <= 1'b0;
        error_o <= 1'b0;

        read_word_count_o  <= 16'd0;
        write_word_count_o <= 16'd0;
    end else begin
        requant_start_q <= 1'b0;
        done_o          <= 1'b0;

        case (state_q)
            ST_IDLE: begin
                if (start_i) begin
                    read_index_q <= 4'd0;

                    acc_ch0_batch_q <= 128'd0;
                    acc_ch1_batch_q <= 128'd0;

                    error_o <= 1'b0;

                    read_word_count_o  <= 16'd0;
                    write_word_count_o <= 16'd0;

                    state_q <= ST_READ_REQ;
                end
            end

            ST_READ_REQ: begin
                // Synchronous BRAM read request is issued through
                // the combinational native BRAM port above.
                state_q <= ST_READ_CAPTURE;
            end

            ST_READ_CAPTURE: begin
                read_word_count_o <=
                    read_word_count_o + 16'd1;

                case (read_index_q)
                    4'd0: acc_ch0_batch_q[31:0]    <= bram_rdata_i;
                    4'd1: acc_ch0_batch_q[63:32]   <= bram_rdata_i;
                    4'd2: acc_ch0_batch_q[95:64]   <= bram_rdata_i;
                    4'd3: acc_ch0_batch_q[127:96]  <= bram_rdata_i;

                    4'd4: acc_ch1_batch_q[31:0]    <= bram_rdata_i;
                    4'd5: acc_ch1_batch_q[63:32]   <= bram_rdata_i;
                    4'd6: acc_ch1_batch_q[95:64]   <= bram_rdata_i;

                    default:
                        acc_ch1_batch_q[127:96] <= bram_rdata_i;
                endcase

                if (read_index_q == 4'd7) begin
                    state_q <= ST_START_REQUANT;
                end else begin
                    read_index_q <=
                        read_index_q + 4'd1;

                    state_q <= ST_READ_REQ;
                end
            end

            ST_START_REQUANT: begin
                if (!requant_busy_w) begin
                    requant_start_q <= 1'b1;
                    state_q <= ST_WAIT_RESULT;
                end
            end

            ST_WAIT_RESULT: begin
                if (requant_result_valid_w) begin
                    state_q <= ST_WRITE_CH0;
                end
            end

            ST_WRITE_CH0: begin
                write_word_count_o <=
                    write_word_count_o + 16'd1;

                state_q <= ST_WRITE_CH1;
            end

            ST_WRITE_CH1: begin
                write_word_count_o <=
                    write_word_count_o + 16'd1;

                state_q <= ST_DONE;
            end

            ST_DONE: begin
                done_o <= 1'b1;
                state_q <= ST_IDLE;
            end

            default: begin
                error_o <= 1'b1;
                state_q <= ST_IDLE;
            end
        endcase
    end
end

endmodule
