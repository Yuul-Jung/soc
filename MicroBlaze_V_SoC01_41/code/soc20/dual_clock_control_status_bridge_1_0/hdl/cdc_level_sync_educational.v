module cdc_level_sync_educational #(
    parameter integer STAGES = 2
)(
    input  wire dest_clk,
    input  wire async_level_i,
    output wire sync_level_o
);

// Educational implementation of a single-bit level synchronizer.
// For AMD FPGA production designs, prefer XPM_CDC_SINGLE.
//
// Do not use this structure independently on each bit of a coherent bus.

(* ASYNC_REG = "TRUE" *)
(* SHREG_EXTRACT = "NO" *)
reg [STAGES-1:0] sync_ff = {STAGES{1'b0}};

integer i;

always @(posedge dest_clk) begin
    sync_ff[0] <= async_level_i;

    for (i = 1; i < STAGES; i = i + 1) begin
        sync_ff[i] <= sync_ff[i-1];
    end
end

assign sync_level_o = sync_ff[STAGES-1];

endmodule
