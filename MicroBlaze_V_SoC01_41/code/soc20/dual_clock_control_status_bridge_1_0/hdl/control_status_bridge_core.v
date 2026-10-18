module control_status_bridge_core (
    input  wire        clk,
    input  wire        resetn,

    // Bus-independent register access
    input  wire        wr_en,
    input  wire [7:0]  wr_offset,
    input  wire [31:0] wr_data,
    input  wire [3:0]  wr_strb,

    input  wire [7:0]  rd_offset,
    output reg  [31:0] rd_data,

    // Generic control / status interface
    output reg  [31:0] control_o,
    input  wire [31:0] status_i,

    // Software -> functional RTL
    output reg  [31:0] in_data_o,
    output reg         in_valid_o,
    input  wire        in_ready_i,

    // Functional RTL -> software
    input  wire [31:0] out_data_i,
    input  wire        out_valid_i,
    output wire        out_ready_o,

    // Event/interrupt visibility
    output wire        irq_o
);

localparam [7:0] REG_CONTROL       = 8'h00;
localparam [7:0] REG_CORE_STATUS   = 8'h04;
localparam [7:0] REG_BRIDGE_STATUS = 8'h08;
localparam [7:0] REG_IN_DATA       = 8'h0C;
localparam [7:0] REG_COMMAND       = 8'h10;
localparam [7:0] REG_OUT_DATA      = 8'h14;
localparam [7:0] REG_EVENT_STATUS  = 8'h18;
localparam [7:0] REG_VERSION       = 8'h1C;
localparam [7:0] REG_ID            = 8'h20;

localparam [31:0] VERSION_VALUE = 32'h0001_0000;
localparam [31:0] ID_VALUE      = 32'h4353_4231; // ASCII "CSB1"

reg [31:0] in_data_shadow;
reg [31:0] out_data_latched;
reg        out_pending;
reg        error_status;
reg [2:0]  event_status;

integer byte_index;

wire command_write;
wire command_submit;
wire command_pop_out;
wire command_clear_error;

wire event_write;
wire event_clear_in_accepted;
wire event_clear_out_captured;
wire event_clear_error;

wire in_handshake;
wire out_handshake;

wire submit_error;
wire pop_error;
wire error_event;

assign command_write =
    wr_en &&
    (wr_offset == REG_COMMAND) &&
    wr_strb[0];

assign command_submit      = command_write && wr_data[0];
assign command_pop_out     = command_write && wr_data[1];
assign command_clear_error = command_write && wr_data[2];

assign event_write =
    wr_en &&
    (wr_offset == REG_EVENT_STATUS) &&
    wr_strb[0];

assign event_clear_in_accepted = event_write && wr_data[0];
assign event_clear_out_captured = event_write && wr_data[1];
assign event_clear_error = event_write && wr_data[2];

assign in_handshake  = in_valid_o && in_ready_i;
assign out_ready_o   = !out_pending;
assign out_handshake = out_valid_i && out_ready_o;

assign submit_error = command_submit && in_valid_o;
assign pop_error    = command_pop_out && !out_pending;
assign error_event  = submit_error || pop_error;

assign irq_o = |event_status;

always @(posedge clk) begin
    if (!resetn) begin
        control_o        <= 32'h0000_0000;
        in_data_shadow   <= 32'h0000_0000;
        in_data_o        <= 32'h0000_0000;
        in_valid_o       <= 1'b0;
        out_data_latched <= 32'h0000_0000;
        out_pending      <= 1'b0;
        error_status     <= 1'b0;
    end else begin
        // General RW control word.
        if (wr_en && (wr_offset == REG_CONTROL)) begin
            for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1) begin
                if (wr_strb[byte_index]) begin
                    control_o[byte_index*8 +: 8] <=
                        wr_data[byte_index*8 +: 8];
                end
            end
        end

        // Software writes a shadow value first.
        // SUBMIT copies this stable value into the pending transfer register.
        if (wr_en && (wr_offset == REG_IN_DATA)) begin
            for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1) begin
                if (wr_strb[byte_index]) begin
                    in_data_shadow[byte_index*8 +: 8] <=
                        wr_data[byte_index*8 +: 8];
                end
            end
        end

        // Existing pending input is released only after READY/VALID handshake.
        if (in_handshake) begin
            in_valid_o <= 1'b0;
        end

        // SUBMIT is rejected if one input word is already pending.
        if (command_submit && !in_valid_o) begin
            in_data_o  <= in_data_shadow;
            in_valid_o <= 1'b1;
        end

        // Software explicitly POPs an already captured output word.
        if (command_pop_out && out_pending) begin
            out_pending <= 1'b0;
        end

        // A new output transfer is captured whenever the bridge buffer is empty.
        // Hardware capture has priority over a same-cycle empty POP.
        if (out_handshake) begin
            out_data_latched <= out_data_i;
            out_pending      <= 1'b1;
        end

        // Software clear has lower priority than a new bridge error.
        if (command_clear_error) begin
            error_status <= 1'b0;
        end

        if (error_event) begin
            error_status <= 1'b1;
        end
    end
end

// Event status uses hardware-set priority over software W1C clear.
always @(posedge clk) begin
    if (!resetn) begin
        event_status <= 3'b000;
    end else begin
        if (in_handshake) begin
            event_status[0] <= 1'b1;
        end else if (event_clear_in_accepted) begin
            event_status[0] <= 1'b0;
        end

        if (out_handshake) begin
            event_status[1] <= 1'b1;
        end else if (event_clear_out_captured) begin
            event_status[1] <= 1'b0;
        end

        if (error_event) begin
            event_status[2] <= 1'b1;
        end else if (event_clear_error) begin
            event_status[2] <= 1'b0;
        end
    end
end

always @(*) begin
    case (rd_offset)
        REG_CONTROL:
            rd_data = control_o;

        REG_CORE_STATUS:
            rd_data = status_i;

        REG_BRIDGE_STATUS:
            rd_data = {
                27'h0,
                out_valid_i,
                error_status,
                out_pending,
                in_valid_o,
                in_ready_i
            };

        REG_IN_DATA:
            rd_data = in_data_shadow;

        REG_COMMAND:
            rd_data = 32'h0000_0000;

        REG_OUT_DATA:
            rd_data = out_data_latched;

        REG_EVENT_STATUS:
            rd_data = {29'h0, event_status};

        REG_VERSION:
            rd_data = VERSION_VALUE;

        REG_ID:
            rd_data = ID_VALUE;

        default:
            rd_data = 32'h0000_0000;
    endcase
end

endmodule
