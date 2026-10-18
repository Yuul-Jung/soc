module custom_register_bank (
    input  wire        clk,
    input  wire        resetn,

    // Bus-independent register access interface.
    // SoC 12 will connect this interface to AXI4-Lite.
    input  wire        wr_en,
    input  wire [7:0]  wr_offset,
    input  wire [31:0] wr_data,
    input  wire [3:0]  wr_strb,

    input  wire [7:0]  rd_offset,
    output reg  [31:0] rd_data,

    // Hardware status / event inputs
    input  wire        busy_i,
    input  wire        done_i,
    input  wire        error_i,
    input  wire        irq_done_event_i,
    input  wire        irq_error_event_i,
    input  wire [31:0] data_out_i,

    // Control outputs
    output reg         enable_o,
    output reg  [1:0]  mode_o,
    output reg         start_pulse_o,
    output reg         clear_pulse_o,
    output reg  [31:0] data_in_o,
    output reg  [1:0]  irq_status_o
);

localparam [7:0] REG_CONTROL    = 8'h00;
localparam [7:0] REG_STATUS     = 8'h04;
localparam [7:0] REG_COMMAND    = 8'h08;
localparam [7:0] REG_IRQ_STATUS = 8'h0C;
localparam [7:0] REG_DATA_IN    = 8'h10;
localparam [7:0] REG_DATA_OUT   = 8'h14;
localparam [7:0] REG_VERSION    = 8'h18;
localparam [7:0] REG_ID         = 8'h1C;

localparam [31:0] VERSION_VALUE = 32'h0001_0000;
localparam [31:0] ID_VALUE      = 32'h524D_4150; // ASCII "RMAP"

integer byte_index;

always @(posedge clk) begin
    if (!resetn) begin
        enable_o      <= 1'b0;
        mode_o        <= 2'b00;
        start_pulse_o <= 1'b0;
        clear_pulse_o <= 1'b0;
        data_in_o     <= 32'h0000_0000;
        irq_status_o  <= 2'b00;
    end else begin
        // W1P pulses are one clock wide by default.
        start_pulse_o <= 1'b0;
        clear_pulse_o <= 1'b0;

        // Hardware events set IRQ status.
        // Event set has priority over software clear in the same cycle.
        if (irq_done_event_i) begin
            irq_status_o[0] <= 1'b1;
        end else if (
            wr_en &&
            (wr_offset == REG_IRQ_STATUS) &&
            wr_strb[0] &&
            wr_data[0]
        ) begin
            irq_status_o[0] <= 1'b0;
        end

        if (irq_error_event_i) begin
            irq_status_o[1] <= 1'b1;
        end else if (
            wr_en &&
            (wr_offset == REG_IRQ_STATUS) &&
            wr_strb[0] &&
            wr_data[1]
        ) begin
            irq_status_o[1] <= 1'b0;
        end

        if (wr_en) begin
            case (wr_offset)
                REG_CONTROL: begin
                    if (wr_strb[0]) begin
                        enable_o <= wr_data[0];
                        mode_o   <= wr_data[2:1];
                    end
                end

                REG_COMMAND: begin
                    if (wr_strb[0]) begin
                        start_pulse_o <= wr_data[0];
                        clear_pulse_o <= wr_data[1];
                    end
                end

                REG_DATA_IN: begin
                    // Byte-enable write using WSTRB-equivalent strobes.
                    for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1) begin
                        if (wr_strb[byte_index]) begin
                            data_in_o[byte_index*8 +: 8] <=
                                wr_data[byte_index*8 +: 8];
                        end
                    end
                end

                default: begin
                    // RO / reserved / unmapped writes have no effect.
                end
            endcase
        end
    end
end

always @(*) begin
    case (rd_offset)
        REG_CONTROL: begin
            rd_data = {29'h0, mode_o, enable_o};
        end

        REG_STATUS: begin
            rd_data = {29'h0, error_i, done_i, busy_i};
        end

        REG_COMMAND: begin
            // W1P command register has no retained state.
            rd_data = 32'h0000_0000;
        end

        REG_IRQ_STATUS: begin
            rd_data = {30'h0, irq_status_o};
        end

        REG_DATA_IN: begin
            rd_data = data_in_o;
        end

        REG_DATA_OUT: begin
            rd_data = data_out_i;
        end

        REG_VERSION: begin
            rd_data = VERSION_VALUE;
        end

        REG_ID: begin
            rd_data = ID_VALUE;
        end

        default: begin
            rd_data = 32'h0000_0000;
        end
    endcase
end

endmodule
