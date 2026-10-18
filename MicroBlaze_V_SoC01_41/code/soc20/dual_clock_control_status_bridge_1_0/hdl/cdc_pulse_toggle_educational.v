module cdc_pulse_toggle_educational (
    input  wire src_clk,
    input  wire src_resetn,
    input  wire src_pulse_i,

    input  wire dest_clk,
    input  wire dest_resetn,
    output wire dest_pulse_o
);

// Educational pulse CDC using a toggle synchronizer.
// The source pulse rate must be slow enough that each toggle can be observed
// by the destination domain.
//
// For AMD FPGA production designs, prefer XPM_CDC_PULSE.

reg src_toggle;

(* ASYNC_REG = "TRUE" *)
(* SHREG_EXTRACT = "NO" *)
reg [1:0] dest_toggle_sync;

reg dest_toggle_d;

always @(posedge src_clk) begin
    if (!src_resetn) begin
        src_toggle <= 1'b0;
    end else if (src_pulse_i) begin
        src_toggle <= ~src_toggle;
    end
end

always @(posedge dest_clk) begin
    if (!dest_resetn) begin
        dest_toggle_sync <= 2'b00;
        dest_toggle_d    <= 1'b0;
    end else begin
        dest_toggle_sync[0] <= src_toggle;
        dest_toggle_sync[1] <= dest_toggle_sync[0];
        dest_toggle_d       <= dest_toggle_sync[1];
    end
end

assign dest_pulse_o =
    dest_toggle_sync[1] ^ dest_toggle_d;

endmodule
