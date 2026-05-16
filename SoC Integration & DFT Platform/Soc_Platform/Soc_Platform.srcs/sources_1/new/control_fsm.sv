`timescale 1ns / 1ps
import soc_pkg::*;

module control_fsm (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        start_pulse,
    input  logic [2:0]  mode,
    input  logic [2:0]  op,

    input  logic        alu_ready,
    input  logic        alu_done,
    input  logic        dma_done,
    input  logic        error_seen,

    output logic        alu_valid,
    output logic        fifo_wr_valid,
    output logic        fifo_rd_valid,
    output logic        dma_start,

    output logic        busy,
    output logic        system_done,
    output logic        system_error,
    output logic [3:0]  state_dbg
);

    state_t state_q, state_d;

    always_comb begin
        state_d = state_q;

        unique case (state_q)
            ST_IDLE: begin
                if (start_pulse)
                    state_d = ST_DECODE;
            end

            ST_DECODE: begin
                if (error_seen) begin
                    state_d = ST_ERROR;
                end else begin
                    unique case (mode)
                        MODE_ALU, MODE_TIMING: state_d = ST_START_ALU;
                        MODE_FIFO:             state_d = ST_FIFO_ACCESS;
                        MODE_DMA:              state_d = ST_START_DMA;
                        MODE_FAULT:            state_d = ST_ERROR;
                        default:               state_d = ST_ERROR;
                    endcase
                end
            end

            ST_START_ALU: begin
                if (alu_ready)
                    state_d = ST_WAIT_ALU;
            end

            ST_WAIT_ALU: begin
                if (alu_done)
                    state_d = error_seen ? ST_ERROR : ST_WRITE_RESULT;
            end

            ST_FIFO_ACCESS: begin
                state_d = error_seen ? ST_ERROR : ST_WRITE_RESULT;
            end

            ST_START_DMA: begin
                state_d = ST_WAIT_DMA;
            end

            ST_WAIT_DMA: begin
                if (dma_done)
                    state_d = error_seen ? ST_ERROR : ST_WRITE_RESULT;
            end

            ST_WRITE_RESULT: begin
                state_d = error_seen ? ST_ERROR : ST_DONE;
            end

            ST_DONE: begin
                state_d = ST_IDLE;
            end

            ST_ERROR: begin
                state_d = ST_IDLE;
            end

            default: begin
                state_d = ST_IDLE;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst_n)
            state_q <= ST_IDLE;
        else
            state_q <= state_d;
    end

    always_comb begin
        alu_valid     = 1'b0;
        fifo_wr_valid = 1'b0;
        fifo_rd_valid = 1'b0;
        dma_start     = 1'b0;
        system_done   = 1'b0;
        system_error  = 1'b0;
        busy          = 1'b0;
        state_dbg     = state_q;

        unique case (state_q)
            ST_IDLE: begin
                busy = 1'b0;
            end

            ST_START_ALU: begin
                busy      = 1'b1;
                alu_valid = 1'b1;
            end

            ST_FIFO_ACCESS: begin
                busy          = 1'b1;
                fifo_wr_valid = (op == FIFO_WRITE);
                fifo_rd_valid = (op == FIFO_READ);
            end

            ST_START_DMA: begin
                busy      = 1'b1;
                dma_start = 1'b1;
            end

            ST_DECODE, ST_WAIT_ALU, ST_WAIT_DMA, ST_WRITE_RESULT: begin
                busy = 1'b1;
            end

            ST_DONE: begin
                system_done = 1'b1;
            end

            ST_ERROR: begin
                system_error = 1'b1;
            end

            default: begin
            end
        endcase
    end

endmodule
