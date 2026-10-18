module pingpong_vector_memory #(
    parameter integer ADDR_WIDTH = 8
) (
    input  wire                      clk,
    input  wire                      resetn,

    input  wire                      load_bank_i,
    input  wire                      load_active_i,

    input  wire                      act_wr_en_i,
    input  wire [ADDR_WIDTH-1:0]     act_wr_addr_i,
    input  wire [31:0]               act_wr_data_i,

    input  wire                      weight_wr_en_i,
    input  wire [ADDR_WIDTH-1:0]     weight_wr_addr_i,
    input  wire [31:0]               weight_wr_data_i,

    input  wire                      compute_bank_i,
    input  wire                      compute_active_i,

    input  wire                      act_rd_en_i,
    input  wire [ADDR_WIDTH-1:0]     act_rd_addr_i,
    output wire [31:0]               act_rd_data_o,
    output wire                      act_rd_valid_o,

    input  wire                      weight_rd_en_i,
    input  wire [ADDR_WIDTH-1:0]     weight_rd_addr_i,
    output wire [31:0]               weight_rd_data_o,
    output wire                      weight_rd_valid_o,

    output wire                      bank_conflict_o
);

// Two complete local-buffer banks.
//
// Bank 0:
//   activation0 + weight0
//
// Bank 1:
//   activation1 + weight1
//
// Intended ping-pong operation:
//   Compute bank 0 while load bank 1.
//   Then compute bank 1 while load bank 0.
//
// Writes to the currently-computed bank are blocked while compute_active_i
// is high. A conflict flag makes the violation observable.

wire same_bank_conflict_w;

assign same_bank_conflict_w =
    load_active_i &&
    compute_active_i &&
    (load_bank_i == compute_bank_i);

assign bank_conflict_o =
    same_bank_conflict_w &&
    (
        act_wr_en_i ||
        weight_wr_en_i
    );

wire safe_act_write_w;
wire safe_weight_write_w;

assign safe_act_write_w =
    act_wr_en_i &&
    !same_bank_conflict_w;

assign safe_weight_write_w =
    weight_wr_en_i &&
    !same_bank_conflict_w;

// ---------------- Bank 0 ----------------
wire [31:0] act0_rd_data;
wire        act0_rd_valid;

wire [31:0] weight0_rd_data;
wire        weight0_rd_valid;

vector_bram_sdp #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(32)
) u_act_bank0 (
    .clk(clk),
    .resetn(resetn),

    .wr_en_i(
        safe_act_write_w &&
        (load_bank_i == 1'b0)
    ),
    .wr_addr_i(act_wr_addr_i),
    .wr_data_i(act_wr_data_i),

    .rd_en_i(
        act_rd_en_i &&
        (compute_bank_i == 1'b0)
    ),
    .rd_addr_i(act_rd_addr_i),
    .rd_data_o(act0_rd_data),
    .rd_valid_o(act0_rd_valid)
);

vector_bram_sdp #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(32)
) u_weight_bank0 (
    .clk(clk),
    .resetn(resetn),

    .wr_en_i(
        safe_weight_write_w &&
        (load_bank_i == 1'b0)
    ),
    .wr_addr_i(weight_wr_addr_i),
    .wr_data_i(weight_wr_data_i),

    .rd_en_i(
        weight_rd_en_i &&
        (compute_bank_i == 1'b0)
    ),
    .rd_addr_i(weight_rd_addr_i),
    .rd_data_o(weight0_rd_data),
    .rd_valid_o(weight0_rd_valid)
);

// ---------------- Bank 1 ----------------
wire [31:0] act1_rd_data;
wire        act1_rd_valid;

wire [31:0] weight1_rd_data;
wire        weight1_rd_valid;

vector_bram_sdp #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(32)
) u_act_bank1 (
    .clk(clk),
    .resetn(resetn),

    .wr_en_i(
        safe_act_write_w &&
        (load_bank_i == 1'b1)
    ),
    .wr_addr_i(act_wr_addr_i),
    .wr_data_i(act_wr_data_i),

    .rd_en_i(
        act_rd_en_i &&
        (compute_bank_i == 1'b1)
    ),
    .rd_addr_i(act_rd_addr_i),
    .rd_data_o(act1_rd_data),
    .rd_valid_o(act1_rd_valid)
);

vector_bram_sdp #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(32)
) u_weight_bank1 (
    .clk(clk),
    .resetn(resetn),

    .wr_en_i(
        safe_weight_write_w &&
        (load_bank_i == 1'b1)
    ),
    .wr_addr_i(weight_wr_addr_i),
    .wr_data_i(weight_wr_data_i),

    .rd_en_i(
        weight_rd_en_i &&
        (compute_bank_i == 1'b1)
    ),
    .rd_addr_i(weight_rd_addr_i),
    .rd_data_o(weight1_rd_data),
    .rd_valid_o(weight1_rd_valid)
);

assign act_rd_data_o =
    compute_bank_i
    ? act1_rd_data
    : act0_rd_data;

assign act_rd_valid_o =
    compute_bank_i
    ? act1_rd_valid
    : act0_rd_valid;

assign weight_rd_data_o =
    compute_bank_i
    ? weight1_rd_data
    : weight0_rd_data;

assign weight_rd_valid_o =
    compute_bank_i
    ? weight1_rd_valid
    : weight0_rd_valid;

endmodule
