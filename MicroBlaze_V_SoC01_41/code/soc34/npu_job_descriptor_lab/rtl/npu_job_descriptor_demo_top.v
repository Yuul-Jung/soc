module npu_job_descriptor_demo_top (
    input  wire               clk,
    input  wire               resetn,

    // CPU register interface.
    input  wire               reg_wr_en_i,
    input  wire [7:0]         reg_wr_addr_i,
    input  wire [31:0]        reg_wr_data_i,
    input  wire [3:0]         reg_wr_strb_i,

    input  wire [7:0]         reg_rd_addr_i,
    output wire [31:0]        reg_rd_data_o,

    // CPU tensor-memory interface.
    input  wire               mem_en_i,
    input  wire [3:0]         mem_we_i,
    input  wire [11:0]        mem_addr_i,
    input  wire [31:0]        mem_wdata_i,
    output wire [31:0]        mem_rdata_o,

    output wire               busy_o,
    output wire               done_sticky_o,
    output wire               error_sticky_o,
    output wire [7:0]         error_code_o,
    output wire [31:0]        job_id_o
);

// Pure Shell / Wrapper.
//
// SoC 34 separates:
//   Descriptor/control registers
//   Tensor BRAM data plane
//   Job engine
//
// Actual AXI shells are added around these interfaces in the
// integrated SoC path. This chapter focuses on Job semantics.

wire job_start;

wire [11:0] active_input_base;
wire [11:0] active_output_base;
wire [15:0] active_length_words;

wire signed [31:0] active_bias_ch0;
wire signed [31:0] active_bias_ch1;

wire signed [15:0] active_mult_ch0;
wire signed [15:0] active_mult_ch1;

wire [5:0] active_shift_ch0;
wire [5:0] active_shift_ch1;

wire signed [15:0] active_zp_ch0;
wire signed [15:0] active_zp_ch1;

wire engine_busy;
wire engine_done;
wire engine_error;

wire [15:0] read_word_count;
wire [15:0] write_word_count;

wire        npu_bram_en;
wire [3:0]  npu_bram_we;
wire [11:0] npu_bram_addr;
wire [31:0] npu_bram_wdata;
wire [31:0] npu_bram_rdata;

npu_job_descriptor_controller u_descriptor (
    .clk(clk),
    .resetn(resetn),

    .wr_en_i(reg_wr_en_i),
    .wr_addr_i(reg_wr_addr_i),
    .wr_data_i(reg_wr_data_i),
    .wr_strb_i(reg_wr_strb_i),

    .rd_addr_i(reg_rd_addr_i),
    .rd_data_o(reg_rd_data_o),

    .job_start_o(job_start),

    .active_input_base_o(active_input_base),
    .active_output_base_o(active_output_base),
    .active_length_words_o(active_length_words),

    .active_bias_ch0_o(active_bias_ch0),
    .active_bias_ch1_o(active_bias_ch1),

    .active_mult_ch0_o(active_mult_ch0),
    .active_mult_ch1_o(active_mult_ch1),

    .active_shift_ch0_o(active_shift_ch0),
    .active_shift_ch1_o(active_shift_ch1),

    .active_zp_ch0_o(active_zp_ch0),
    .active_zp_ch1_o(active_zp_ch1),

    .engine_busy_i(engine_busy),
    .engine_done_i(engine_done),
    .engine_error_i(engine_error),

    .read_word_count_i(read_word_count),
    .write_word_count_i(write_word_count),

    .busy_o(busy_o),
    .done_sticky_o(done_sticky_o),
    .error_sticky_o(error_sticky_o),
    .error_code_o(error_code_o),
    .job_id_o(job_id_o)
);

tensor_job_engine u_engine (
    .clk(clk),
    .resetn(resetn),

    .start_i(job_start),

    .input_base_i(active_input_base),
    .output_base_i(active_output_base),
    .length_words_i(active_length_words),

    .bias_ch0_i(active_bias_ch0),
    .bias_ch1_i(active_bias_ch1),

    .mult_ch0_i(active_mult_ch0),
    .mult_ch1_i(active_mult_ch1),

    .shift_ch0_i(active_shift_ch0),
    .shift_ch1_i(active_shift_ch1),

    .zp_ch0_i(active_zp_ch0),
    .zp_ch1_i(active_zp_ch1),

    .busy_o(engine_busy),
    .done_o(engine_done),
    .error_o(engine_error),

    .bram_en_o(npu_bram_en),
    .bram_we_o(npu_bram_we),
    .bram_addr_o(npu_bram_addr),
    .bram_wdata_o(npu_bram_wdata),
    .bram_rdata_i(npu_bram_rdata),

    .read_word_count_o(read_word_count),
    .write_word_count_o(write_word_count)
);

tensor_bram_tdp_4k_model u_tensor_bram (
    .clk(clk),

    .a_en_i(mem_en_i),
    .a_we_i(mem_we_i),
    .a_addr_i(mem_addr_i),
    .a_wdata_i(mem_wdata_i),
    .a_rdata_o(mem_rdata_o),

    .b_en_i(npu_bram_en),
    .b_we_i(npu_bram_we),
    .b_addr_i(npu_bram_addr),
    .b_wdata_i(npu_bram_wdata),
    .b_rdata_o(npu_bram_rdata)
);

endmodule
