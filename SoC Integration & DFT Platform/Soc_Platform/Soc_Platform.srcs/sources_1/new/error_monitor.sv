`timescale 1ns / 1ps
import soc_pkg::*;

module error_monitor (
    input  logic       invalid_op,
    input  logic       fifo_overflow,
    input  logic       fifo_underflow,
    input  logic       timeout,
    input  logic       checksum_fail,
    input  logic       fault_enable,
    input  logic [2:0] fault_type,

    output logic       error_flag,
    output logic [3:0] error_code
);

    always_comb begin
        error_flag = 1'b0;
        error_code = ERR_NONE;

        if (invalid_op) begin
            error_flag = 1'b1;
            error_code = ERR_INVALID_OP;
        end else if (fifo_overflow) begin
            error_flag = 1'b1;
            error_code = ERR_FIFO_OVF;
        end else if (fifo_underflow) begin
            error_flag = 1'b1;
            error_code = ERR_FIFO_OVF;
        end else if (timeout) begin
            error_flag = 1'b1;
            error_code = ERR_TIMEOUT;
        end else if (checksum_fail) begin
            error_flag = 1'b1;
            error_code = ERR_CSUM_FAIL;
        end else if (fault_enable) begin
            error_flag = 1'b1;
            unique case (fault_type)
                FAULT_INVALID_OP: error_code = ERR_INVALID_OP;
                FAULT_FIFO_OVF:   error_code = ERR_FIFO_OVF;
                FAULT_TIMEOUT:    error_code = ERR_TIMEOUT;
                FAULT_CSUM:       error_code = ERR_CSUM_FAIL;
                default:          error_code = ERR_FAULT_INJ;
            endcase
        end
    end

endmodule
