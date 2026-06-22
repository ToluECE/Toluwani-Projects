`timescale 1ns/1ps

module scratchpad #(
    parameter int VEC_DEPTH = 64
)(
    input  logic              clk,
    input  logic              rst_n,

    input  logic              a_we,
    input  logic              b_we,
    input  logic [7:0]        wr_index,
    input  logic signed [7:0] wr_data,

    input  logic [7:0]        rd_index,
    output logic signed [7:0] a_rd_data,
    output logic signed [7:0] b_rd_data,

    input  logic              apb_read_a,
    input  logic              apb_read_b,
    input  logic [7:0]        apb_rd_index,
    output logic [31:0]       apb_rd_data
);

    logic signed [7:0] mem_a [0:VEC_DEPTH-1];
    logic signed [7:0] mem_b [0:VEC_DEPTH-1];

    integer i;

    // ------------------------------------------------------------
    // Write logic
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < VEC_DEPTH; i = i + 1) begin
                mem_a[i] <= 8'sd0;
                mem_b[i] <= 8'sd0;
            end
        end else begin
            if (a_we && (wr_index < VEC_DEPTH[7:0]))
                mem_a[wr_index] <= wr_data;

            if (b_we && (wr_index < VEC_DEPTH[7:0]))
                mem_b[wr_index] <= wr_data;
        end
    end

    // ------------------------------------------------------------
    // MAC read path
    // asynchronous read for simple ASIC-friendly RTL
    // ------------------------------------------------------------
    always_comb begin
        if (rd_index < VEC_DEPTH[7:0]) begin
            a_rd_data = mem_a[rd_index];
            b_rd_data = mem_b[rd_index];
        end else begin
            a_rd_data = 8'sd0;
            b_rd_data = 8'sd0;
        end
    end

    // ------------------------------------------------------------
    // APB readback path
    // ------------------------------------------------------------
    always_comb begin
        apb_rd_data = 32'd0;

        if (apb_rd_index < VEC_DEPTH[7:0]) begin
            if (apb_read_a)
                apb_rd_data = {{24{mem_a[apb_rd_index][7]}}, mem_a[apb_rd_index]};
            else if (apb_read_b)
                apb_rd_data = {{24{mem_b[apb_rd_index][7]}}, mem_b[apb_rd_index]};
        end
    end

endmodule