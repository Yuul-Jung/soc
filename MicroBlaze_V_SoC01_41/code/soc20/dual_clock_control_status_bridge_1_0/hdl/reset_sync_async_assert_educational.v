module reset_sync_async_assert_educational #(
    parameter integer STAGES = 2
)(
    input  wire clk,
    input  wire arstn_i,
    output wire srstn_o
);

// Active-Low reset synchronizer.
// Assertion: asynchronous
// Deassertion: synchronous to clk
//
// For AMD FPGA production designs, prefer XPM_CDC_ASYNC_RST.

(* ASYNC_REG = "TRUE" *)
(* SHREG_EXTRACT = "NO" *)
reg [STAGES-1:0] reset_ff;

integer i;

always @(posedge clk or negedge arstn_i) begin
    if (!arstn_i) begin
        reset_ff <= {STAGES{1'b0}};
    end else begin
        reset_ff[0] <= 1'b1;

        for (i = 1; i < STAGES; i = i + 1) begin
            reset_ff[i] <= reset_ff[i-1];
        end
    end
end

assign srstn_o = reset_ff[STAGES-1];

endmodule
