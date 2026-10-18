module uart_tx_register_bank #(
    parameter [31:0] BAUD_DIV_VALUE = 32'd868
)(
    input  wire        clk,
    input  wire        resetn,

    input  wire        wr_en,
    input  wire [7:0]  wr_offset,
    input  wire [31:0] wr_data,
    input  wire [3:0]  wr_strb,

    input  wire [7:0]  rd_offset,
    output reg  [31:0] rd_data,

    input  wire        busy_i,
    input  wire        done_i,
    input  wire        error_i,
    input  wire        irq_done_event_i,
    input  wire        irq_error_event_i,

    output reg         enable_o,
    output reg         send_pulse_o,
    output reg         clear_pulse_o,
    output reg  [7:0]  tx_data_o,
    output reg  [1:0]  irq_status_o
);

localparam [7:0] REG_CONTROL    = 8'h00;
localparam [7:0] REG_STATUS     = 8'h04;
localparam [7:0] REG_TX_DATA    = 8'h08;
localparam [7:0] REG_COMMAND    = 8'h0C;
localparam [7:0] REG_IRQ_STATUS = 8'h10;
localparam [7:0] REG_BAUD_DIV   = 8'h14;
localparam [7:0] REG_VERSION    = 8'h18;
localparam [7:0] REG_ID         = 8'h1C;

localparam [31:0] VERSION_VALUE = 32'h0001_0000;
localparam [31:0] ID_VALUE      = 32'h5554_5831; // ASCII "UTX1"

always @(posedge clk) begin
    if (!resetn) begin
        enable_o      <= 1'b0;
        send_pulse_o  <= 1'b0;
        clear_pulse_o <= 1'b0;
        tx_data_o     <= 8'h00;
        irq_status_o  <= 2'b00;
    end else begin
        send_pulse_o  <= 1'b0;
        clear_pulse_o <= 1'b0;

        // Hardware event set has priority over software W1C clear.
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
                    end
                end

                REG_TX_DATA: begin
                    if (wr_strb[0]) begin
                        tx_data_o <= wr_data[7:0];
                    end
                end

                REG_COMMAND: begin
                    if (wr_strb[0]) begin
                        send_pulse_o  <= wr_data[0];
                        clear_pulse_o <= wr_data[1];
                    end
                end

                default: begin
                end
            endcase
        end
    end
end

always @(*) begin
    case (rd_offset)
        REG_CONTROL:
            rd_data = {31'h0, enable_o};

        REG_STATUS:
            rd_data = {29'h0, error_i, done_i, busy_i};

        REG_TX_DATA:
            rd_data = {24'h0, tx_data_o};

        REG_COMMAND:
            rd_data = 32'h0000_0000;

        REG_IRQ_STATUS:
            rd_data = {30'h0, irq_status_o};

        REG_BAUD_DIV:
            rd_data = BAUD_DIV_VALUE;

        REG_VERSION:
            rd_data = VERSION_VALUE;

        REG_ID:
            rd_data = ID_VALUE;

        default:
            rd_data = 32'h0000_0000;
    endcase
end

endmodule
