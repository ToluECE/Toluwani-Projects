`timescale 1ns / 1ps

module fifo_buffer #(
    parameter int WIDTH = 8,
    parameter int DEPTH = 8
)(
    input  logic             clk,
    input  logic             rst_n,

    input  logic             wr_valid,
    output logic             wr_ready,
    input  logic [WIDTH-1:0] wr_data,

    input  logic             rd_valid,
    output logic             rd_ready,
    output logic [WIDTH-1:0] rd_data,

    output logic             full,
    output logic             empty,
    output logic             overflow,
    output logic             underflow,
    output logic [$clog2(DEPTH+1)-1:0] count
);

    localparam int AW = $clog2(DEPTH);

    logic [WIDTH-1:0] mem [0:DEPTH-1];
    logic [AW-1:0] wr_ptr, rd_ptr;

    assign full     = (count == DEPTH);
    assign empty    = (count == '0);
    assign wr_ready = !full;
    assign rd_ready = !empty;
    assign rd_data  = mem[rd_ptr];

    wire do_write = wr_valid && wr_ready;
    wire do_read  = rd_valid && rd_ready;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            wr_ptr    <= '0;
            rd_ptr    <= '0;
            count     <= '0;
            overflow  <= 1'b0;
            underflow <= 1'b0;
        end else begin
            overflow  <= wr_valid && full;
            underflow <= rd_valid && empty;

            if (do_write) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end

            if (do_read) begin
                rd_ptr <= rd_ptr + 1'b1;
            end

            unique case ({do_write, do_read})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
