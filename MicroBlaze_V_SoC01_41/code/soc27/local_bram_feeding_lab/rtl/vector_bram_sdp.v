module vector_bram_sdp #(
    parameter integer ADDR_WIDTH = 8,
    parameter integer DATA_WIDTH = 32
) (
    input  wire                      clk,
    input  wire                      resetn,

    input  wire                      wr_en_i,
    input  wire [ADDR_WIDTH-1:0]     wr_addr_i,
    input  wire [DATA_WIDTH-1:0]     wr_data_i,

    input  wire                      rd_en_i,
    input  wire [ADDR_WIDTH-1:0]     rd_addr_i,
    output reg  [DATA_WIDTH-1:0]     rd_data_o,
    output reg                       rd_valid_o
);

// Simple-dual-port local vector buffer.
//
// Write port: synchronous.
// Read port : synchronous, one registered read-data stage.
//
// Do not reset the RAM array itself. This coding style is intentionally
// kept close to Vivado RAM inference templates.
//
// RAM_STYLE requests block RAM mapping. Actual mapping must still be
// verified with report_ram_utilization after synthesis.

(* ram_style = "block" *)
reg [DATA_WIDTH-1:0] mem [
    0:(1 << ADDR_WIDTH)-1
];

always @(posedge clk) begin
    if (wr_en_i) begin
        mem[wr_addr_i] <= wr_data_i;
    end
end

always @(posedge clk) begin
    if (rd_en_i) begin
        rd_data_o <= mem[rd_addr_i];
    end
end

always @(posedge clk) begin
    if (!resetn) begin
        rd_valid_o <= 1'b0;
    end else begin
        rd_valid_o <= rd_en_i;
    end
end

endmodule
