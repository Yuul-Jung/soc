module tensor_bram_data_plane_demo_top (
    input  wire                 clk,
    input  wire                 resetn,

    input  wire                 start_i,

    // CPU-side simulation/native access.
    input  wire                 cpu_en_i,
    input  wire [3:0]           cpu_we_i,
    input  wire [11:0]          cpu_addr_i,
    input  wire [31:0]          cpu_wdata_i,
    output wire [31:0]          cpu_rdata_o,

    input  wire signed [31:0]   bias_ch0_i,
    input  wire signed [31:0]   bias_ch1_i,

    input  wire signed [15:0]   mult_ch0_i,
    input  wire signed [15:0]   mult_ch1_i,

    input  wire        [5:0]    shift_ch0_i,
    input  wire        [5:0]    shift_ch1_i,

    input  wire signed [15:0]   zp_ch0_i,
    input  wire signed [15:0]   zp_ch1_i,

    output wire                 busy_o,
    output wire                 done_o,
    output wire                 error_o,

    output wire [15:0]          read_word_count_o,
    output wire [15:0]          write_word_count_o
);

// Pure Shell / Wrapper.
//
// Simulation/OOC:
//   Port A = CPU-side native model access.
//
// Actual Vivado Block Design:
//   replace tensor_bram_tdp_4k_model with a True Dual-Port
//   Block Memory Generator.
//   Port A is accessed through AXI BRAM Controller.
//   Port B is connected to tensor_bram_data_plane_engine.

wire        npu_bram_en;
wire [3:0]  npu_bram_we;
wire [11:0] npu_bram_addr;
wire [31:0] npu_bram_wdata;
wire [31:0] npu_bram_rdata;

tensor_bram_tdp_4k_model u_tensor_bram (
    .clk(clk),

    .a_en_i(cpu_en_i),
    .a_we_i(cpu_we_i),
    .a_addr_i(cpu_addr_i),
    .a_wdata_i(cpu_wdata_i),
    .a_rdata_o(cpu_rdata_o),

    .b_en_i(npu_bram_en),
    .b_we_i(npu_bram_we),
    .b_addr_i(npu_bram_addr),
    .b_wdata_i(npu_bram_wdata),
    .b_rdata_o(npu_bram_rdata)
);

tensor_bram_data_plane_engine u_data_plane (
    .clk(clk),
    .resetn(resetn),

    .start_i(start_i),

    .bias_ch0_i(bias_ch0_i),
    .bias_ch1_i(bias_ch1_i),

    .mult_ch0_i(mult_ch0_i),
    .mult_ch1_i(mult_ch1_i),

    .shift_ch0_i(shift_ch0_i),
    .shift_ch1_i(shift_ch1_i),

    .zp_ch0_i(zp_ch0_i),
    .zp_ch1_i(zp_ch1_i),

    .busy_o(busy_o),
    .done_o(done_o),
    .error_o(error_o),

    .bram_en_o(npu_bram_en),
    .bram_we_o(npu_bram_we),
    .bram_addr_o(npu_bram_addr),
    .bram_wdata_o(npu_bram_wdata),
    .bram_rdata_i(npu_bram_rdata),

    .read_word_count_o(read_word_count_o),
    .write_word_count_o(write_word_count_o)
);

endmodule
