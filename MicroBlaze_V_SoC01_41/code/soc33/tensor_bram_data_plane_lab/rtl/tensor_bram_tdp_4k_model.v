module tensor_bram_tdp_4k_model (
    input  wire         clk,

    // --------------------------------------------------------
    // Port A: CPU / AXI BRAM Controller side
    // --------------------------------------------------------
    input  wire         a_en_i,
    input  wire [3:0]   a_we_i,
    input  wire [11:0]  a_addr_i,
    input  wire [31:0]  a_wdata_i,
    output reg  [31:0]  a_rdata_o,

    // --------------------------------------------------------
    // Port B: NPU native side
    // --------------------------------------------------------
    input  wire         b_en_i,
    input  wire [3:0]   b_we_i,
    input  wire [11:0]  b_addr_i,
    input  wire [31:0]  b_wdata_i,
    output reg  [31:0]  b_rdata_o
);

// ------------------------------------------------------------
// 4 KB, 32-bit, byte-addressed True Dual-Port BRAM model.
//
// Address:
//   0x000 .. 0xFFF byte address
//
// Word index:
//   addr[11:2]
//
// Both ports use the same clock in SoC 33.
// Same-address simultaneous write/write or write/read access is
// intentionally prohibited by the software/hardware ownership rule.
//
// This RTL model is used for simulation/OOC education.
// In the Vivado Block Design, use a True Dual-Port Block Memory
// Generator and connect:
//   Port A -> AXI BRAM Controller / MicroBlaze V
//   Port B -> NPU native port
// ------------------------------------------------------------

(* ram_style = "block" *)
reg [31:0] mem [0:1023];

wire [9:0] a_word_addr_w;
wire [9:0] b_word_addr_w;

assign a_word_addr_w =
    a_addr_i[11:2];

assign b_word_addr_w =
    b_addr_i[11:2];

integer byte_index_a;
integer byte_index_b;

always @(posedge clk) begin
    if (a_en_i) begin
        // Read-first behavior for the simulation model.
        a_rdata_o <=
            mem[a_word_addr_w];

        for (
            byte_index_a = 0;
            byte_index_a < 4;
            byte_index_a = byte_index_a + 1
        ) begin
            if (a_we_i[byte_index_a]) begin
                mem[a_word_addr_w][
                    (byte_index_a * 8) +: 8
                ] <=
                    a_wdata_i[
                        (byte_index_a * 8) +: 8
                    ];
            end
        end
    end
end

always @(posedge clk) begin
    if (b_en_i) begin
        // Read-first behavior for the simulation model.
        b_rdata_o <=
            mem[b_word_addr_w];

        for (
            byte_index_b = 0;
            byte_index_b < 4;
            byte_index_b = byte_index_b + 1
        ) begin
            if (b_we_i[byte_index_b]) begin
                mem[b_word_addr_w][
                    (byte_index_b * 8) +: 8
                ] <=
                    b_wdata_i[
                        (byte_index_b * 8) +: 8
                    ];
            end
        end
    end
end

endmodule
