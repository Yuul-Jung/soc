module bram_vector_feeder #(
    parameter integer ADDR_WIDTH = 8
) (
    input  wire                      clk,
    input  wire                      resetn,

    input  wire                      start_i,
    input  wire [15:0]               vector_length_i,

    input  wire                      downstream_ready_i,

    output wire                      act_rd_en_o,
    output wire [ADDR_WIDTH-1:0]     act_rd_addr_o,
    input  wire [31:0]               act_rd_data_i,
    input  wire                      act_rd_valid_i,

    output wire                      weight_rd_en_o,
    output wire [ADDR_WIDTH-1:0]     weight_rd_addr_o,
    input  wire [31:0]               weight_rd_data_i,
    input  wire                      weight_rd_valid_i,

    output wire                      vec_valid_o,
    output wire [31:0]               a_vec_o,
    output wire [31:0]               b_vec_o,

    output reg  [15:0]               requested_groups_o,
    output reg  [15:0]               delivered_groups_o,
    output wire                      active_o
);

// This feeder is paired with vector_dot_controller_pe4.
// The downstream controller keeps READY high throughout FEED, so the
// synchronous BRAM can issue one group every clock after startup.
//
// Request side:
//   rd_en_o + rd_addr_o
//
// Response side one clock later:
//   *_rd_valid_i + *_rd_data_i
//
// The feeder does not hard-code BRAM data values or PE pipeline latency.

wire [16:0] length_plus3_w;
wire [15:0] total_groups_w;

assign length_plus3_w =
    {1'b0, vector_length_i} + 17'd3;

assign total_groups_w =
    length_plus3_w[16:2];

reg [15:0] total_groups_q;
reg        active_q;

assign active_o = active_q;

wire can_issue_w;

assign can_issue_w =
    active_q &&
    downstream_ready_i &&
    (requested_groups_o < total_groups_q);

assign act_rd_en_o    = can_issue_w;
assign weight_rd_en_o = can_issue_w;

assign act_rd_addr_o =
    requested_groups_o[ADDR_WIDTH-1:0];

assign weight_rd_addr_o =
    requested_groups_o[ADDR_WIDTH-1:0];

assign vec_valid_o =
    act_rd_valid_i &&
    weight_rd_valid_i;

assign a_vec_o = act_rd_data_i;
assign b_vec_o = weight_rd_data_i;

always @(posedge clk) begin
    if (!resetn) begin
        total_groups_q      <= 16'd0;
        requested_groups_o  <= 16'd0;
        delivered_groups_o  <= 16'd0;
        active_q             <= 1'b0;
    end else begin
        if (start_i) begin
            total_groups_q     <= total_groups_w;
            requested_groups_o <= 16'd0;
            delivered_groups_o <= 16'd0;

            active_q <=
                (vector_length_i != 16'd0);
        end else begin
            if (can_issue_w) begin
                requested_groups_o <=
                    requested_groups_o + 16'd1;
            end

            if (
                vec_valid_o &&
                downstream_ready_i
            ) begin
                delivered_groups_o <=
                    delivered_groups_o + 16'd1;

                if (
                    delivered_groups_o ==
                    (total_groups_q - 16'd1)
                ) begin
                    active_q <= 1'b0;
                end
            end
        end
    end
end

endmodule
