module legacy_uart_tx_core #(
    parameter integer CLKS_PER_BIT = 868
)(
    input  wire       clk,
    input  wire       resetn,

    input  wire       tx_start_i,
    input  wire [7:0] tx_data_i,

    output reg        tx_o,
    output reg        busy_o,
    output reg        done_pulse_o
);

localparam [2:0] ST_IDLE  = 3'd0;
localparam [2:0] ST_START = 3'd1;
localparam [2:0] ST_DATA  = 3'd2;
localparam [2:0] ST_STOP  = 3'd3;

reg [2:0]  state;
reg [31:0] clk_count;
reg [2:0]  bit_index;
reg [7:0]  data_latched;

always @(posedge clk) begin
    if (!resetn) begin
        state        <= ST_IDLE;
        clk_count    <= 32'd0;
        bit_index    <= 3'd0;
        data_latched <= 8'h00;

        tx_o         <= 1'b1;
        busy_o       <= 1'b0;
        done_pulse_o <= 1'b0;
    end else begin
        done_pulse_o <= 1'b0;

        case (state)
            ST_IDLE: begin
                tx_o      <= 1'b1;
                busy_o    <= 1'b0;
                clk_count <= 32'd0;

                if (tx_start_i) begin
                    data_latched <= tx_data_i;
                    busy_o       <= 1'b1;
                    tx_o         <= 1'b0;
                    state        <= ST_START;
                end
            end

            ST_START: begin
                busy_o <= 1'b1;

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 32'd0;
                    bit_index <= 3'd0;
                    tx_o      <= data_latched[0];
                    state     <= ST_DATA;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            ST_DATA: begin
                busy_o <= 1'b1;

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count <= 32'd0;

                    if (bit_index == 3'd7) begin
                        tx_o  <= 1'b1;
                        state <= ST_STOP;
                    end else begin
                        bit_index <= bit_index + 1'b1;
                        tx_o <= data_latched[bit_index + 1'b1];
                    end
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            ST_STOP: begin
                busy_o <= 1'b1;
                tx_o   <= 1'b1;

                if (clk_count == CLKS_PER_BIT - 1) begin
                    clk_count    <= 32'd0;
                    busy_o       <= 1'b0;
                    done_pulse_o <= 1'b1;
                    state        <= ST_IDLE;
                end else begin
                    clk_count <= clk_count + 1'b1;
                end
            end

            default: begin
                state  <= ST_IDLE;
                tx_o   <= 1'b1;
                busy_o <= 1'b0;
            end
        endcase
    end
end

endmodule
