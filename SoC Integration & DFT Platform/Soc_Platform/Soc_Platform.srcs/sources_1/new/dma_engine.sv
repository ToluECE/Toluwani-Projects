`timescale 1ns / 1ps

module dma_engine #(
    parameter int MAX_CYCLES = 20
)(
    input  logic       clk,
    input  logic       rst_n,

    input  logic       start,
    input  logic [4:0] length,
    input  logic       force_timeout,

    output logic       busy,
    output logic       done,
    output logic       timeout,
    output logic [7:0] dma_count
);

    logic [7:0] target_count;

    always_comb begin
        // Use length as a visible multi-cycle transfer size.
        // Length 0 still becomes a 1-cycle transaction.
        target_count = (length == 5'd0) ? 8'd1 : {3'd0, length};
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            busy      <= 1'b0;
            done      <= 1'b0;
            timeout   <= 1'b0;
            dma_count <= 8'd0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                busy      <= 1'b1;
                timeout   <= 1'b0;
                dma_count <= 8'd0;
            end else if (busy) begin
                dma_count <= dma_count + 1'b1;

                if (force_timeout && dma_count >= MAX_CYCLES[7:0]) begin
                    busy    <= 1'b0;
                    timeout <= 1'b1;
                    done    <= 1'b1;
                end else if (!force_timeout && dma_count >= (target_count - 1'b1)) begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end
            end
        end
    end

endmodule
