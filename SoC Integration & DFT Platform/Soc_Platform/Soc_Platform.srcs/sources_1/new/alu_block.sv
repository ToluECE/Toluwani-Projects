`timescale 1ns / 1ps
import soc_pkg::*;

module alu_block (
    input  logic        clk,
    input  logic        rst_n,

    // Valid/ready-style command interface
    input  logic        valid,
    output logic        ready,
    input  logic [2:0]  op,
    input  logic [4:0]  data_a,
    input  logic [4:0]  data_b,

    output logic [7:0]  result,
    output logic        done,
    output logic        error_flag,
    output logic        checksum_fail
);

    logic [7:0] result_next;
    logic       error_next;
    logic       csum_fail_next;

    assign ready = 1'b1; // 1-cycle datapath, no backpressure

    always_comb begin
        result_next     = 8'd0;
        error_next      = 1'b0;
        csum_fail_next  = 1'b0;

        unique case (op)
            OP_ADD:      result_next = data_a + data_b;
            OP_SUB:      result_next = data_a - data_b;
            OP_AND:      result_next = {3'b000, (data_a & data_b)};
            OP_OR:       result_next = {3'b000, (data_a | data_b)};
            OP_CMP:      result_next = (data_a == data_b) ? 8'd1 : 8'd0;
            OP_CHECKSUM: begin
                // Simple visible checksum demo: expected low nibble = A[3:0] XOR B[3:0]
                result_next    = {4'd0, data_a[3:0] ^ data_b[3:0]};
                csum_fail_next = 1'b0;
            end
            default: begin
                result_next = 8'd0;
                error_next  = 1'b1;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            result        <= 8'd0;
            done          <= 1'b0;
            error_flag    <= 1'b0;
            checksum_fail <= 1'b0;
        end else begin
            // These are transaction-status pulses. Clear them every cycle so
            // a previous invalid ALU op does not poison later FIFO/DMA tests.
            done          <= 1'b0;
            error_flag    <= 1'b0;
            checksum_fail <= 1'b0;

            if (valid && ready) begin
                result        <= result_next;
                error_flag    <= error_next;
                checksum_fail <= csum_fail_next;
                done          <= 1'b1;
            end
        end
    end

endmodule
