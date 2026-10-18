module xpm_ready_valid_bus_bridge #(
    parameter integer WIDTH = 32,
    parameter integer SETTLE_CYCLES = 8
)(
    // Source clock domain
    input  wire                 src_clk,
    input  wire                 src_resetn,
    input  wire [WIDTH-1:0]     src_data_i,
    input  wire                 src_valid_i,
    output wire                 src_ready_o,

    // Destination clock domain
    input  wire                 dest_clk,
    input  wire                 dest_resetn,
    output wire [WIDTH-1:0]     dest_data_o,
    output wire                 dest_valid_o,
    input  wire                 dest_ready_i
);

// Ready/Valid wrapper around XPM_CDC_HANDSHAKE.
//
// One transfer can be outstanding.
// A new source word is accepted only after the full previous handshake
// returns to idle.

localparam [1:0] SRC_IDLE          = 2'd0;
localparam [1:0] SRC_WAIT_RCV_HIGH = 2'd1;
localparam [1:0] SRC_WAIT_RCV_LOW  = 2'd2;

reg [1:0] src_state;
reg [WIDTH-1:0] src_data_hold;
reg src_send;

wire src_rcv;
wire [WIDTH-1:0] dest_out;
wire dest_req;
reg  dest_ack;

// Post-reset guard lets the unreset XPM handshake synchronizers
// observe stable zero values before new traffic is accepted.
reg [7:0] src_settle_count;
reg [7:0] dest_settle_count;

wire src_active;
wire dest_active;

assign src_active =
    (src_settle_count >= SETTLE_CYCLES);

assign dest_active =
    (dest_settle_count >= SETTLE_CYCLES);

assign src_ready_o =
    src_active &&
    (src_state == SRC_IDLE);

assign dest_data_o  = dest_out;
assign dest_valid_o =
    dest_active &&
    dest_req &&
    !dest_ack;

always @(posedge src_clk) begin
    if (!src_resetn) begin
        src_state        <= SRC_IDLE;
        src_data_hold    <= {WIDTH{1'b0}};
        src_send         <= 1'b0;
        src_settle_count <= 8'd0;
    end else begin
        if (!src_active) begin
            src_settle_count <= src_settle_count + 1'b1;
        end

        case (src_state)
            SRC_IDLE: begin
                src_send <= 1'b0;

                if (src_active && src_valid_i) begin
                    src_data_hold <= src_data_i;
                    src_send      <= 1'b1;
                    src_state     <= SRC_WAIT_RCV_HIGH;
                end
            end

            SRC_WAIT_RCV_HIGH: begin
                if (src_rcv) begin
                    src_send  <= 1'b0;
                    src_state <= SRC_WAIT_RCV_LOW;
                end
            end

            SRC_WAIT_RCV_LOW: begin
                if (!src_rcv) begin
                    src_state <= SRC_IDLE;
                end
            end

            default: begin
                src_state <= SRC_IDLE;
                src_send  <= 1'b0;
            end
        endcase
    end
end

always @(posedge dest_clk) begin
    if (!dest_resetn) begin
        dest_ack          <= 1'b0;
        dest_settle_count <= 8'd0;
    end else begin
        if (!dest_active) begin
            dest_settle_count <= dest_settle_count + 1'b1;
            dest_ack <= 1'b0;
        end else if (!dest_ack && dest_req && dest_ready_i) begin
            dest_ack <= 1'b1;
        end else if (dest_ack && !dest_req) begin
            dest_ack <= 1'b0;
        end
    end
end

xpm_cdc_handshake #(
    .DEST_EXT_HSK(1),
    .DEST_SYNC_FF(4),
    .INIT_SYNC_FF(0),
    .SIM_ASSERT_CHK(1),
    .SRC_SYNC_FF(4),
    .WIDTH(WIDTH)
) u_xpm_cdc_handshake (
    .src_clk(src_clk),
    .src_in(src_data_hold),
    .src_send(src_send),
    .src_rcv(src_rcv),

    .dest_clk(dest_clk),
    .dest_out(dest_out),
    .dest_req(dest_req),
    .dest_ack(dest_ack)
);

endmodule
