module example_ready_valid_core #(
    parameter integer PROCESS_CYCLES = 4
)(
    input  wire        clk,
    input  wire        resetn,

    input  wire [31:0] control_i,
    output wire [31:0] status_o,

    input  wire [31:0] in_data_i,
    input  wire        in_valid_i,
    output wire        in_ready_o,

    output reg  [31:0] out_data_o,
    output reg         out_valid_o,
    input  wire        out_ready_i
);

localparam [1:0] ST_IDLE = 2'd0;
localparam [1:0] ST_RUN  = 2'd1;
localparam [1:0] ST_OUT  = 2'd2;

reg [1:0]  state;
reg [7:0]  cycles_left;
reg [31:0] data_latched;
reg [1:0]  mode_latched;

wire input_handshake;
wire output_handshake;

assign in_ready_o = (state == ST_IDLE);
assign input_handshake = in_valid_i && in_ready_o;
assign output_handshake = out_valid_o && out_ready_i;

assign status_o = {
    28'h0,
    out_valid_o,
    (state == ST_RUN),
    (state == ST_IDLE),
    in_ready_o
};

function [31:0] process_value;
    input [31:0] value;
    input [1:0] mode;
    begin
        case (mode)
            2'b00: process_value = value;
            2'b01: process_value = value + 32'd1;
            2'b10: process_value = value << 1;
            2'b11: process_value = ~value;
            default: process_value = value;
        endcase
    end
endfunction

always @(posedge clk) begin
    if (!resetn) begin
        state         <= ST_IDLE;
        cycles_left   <= 8'd0;
        data_latched  <= 32'h0000_0000;
        mode_latched  <= 2'b00;
        out_data_o    <= 32'h0000_0000;
        out_valid_o   <= 1'b0;
    end else begin
        case (state)
            ST_IDLE: begin
                out_valid_o <= 1'b0;

                if (input_handshake) begin
                    data_latched <= in_data_i;
                    mode_latched <= control_i[1:0];

                    if (PROCESS_CYCLES <= 1) begin
                        cycles_left <= 8'd0;
                    end else begin
                        cycles_left <= PROCESS_CYCLES - 1;
                    end

                    state <= ST_RUN;
                end
            end

            ST_RUN: begin
                if (cycles_left != 0) begin
                    cycles_left <= cycles_left - 1'b1;
                end else begin
                    out_data_o  <= process_value(data_latched, mode_latched);
                    out_valid_o <= 1'b1;
                    state       <= ST_OUT;
                end
            end

            ST_OUT: begin
                if (output_handshake) begin
                    out_valid_o <= 1'b0;
                    state       <= ST_IDLE;
                end
            end

            default: begin
                state       <= ST_IDLE;
                out_valid_o <= 1'b0;
            end
        endcase
    end
end

endmodule
