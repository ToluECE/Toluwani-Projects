`timescale 1ns / 1ps
import soc_pkg::*;

module soc_top (
    input  logic        clk,
    input  logic        btn_reset,    // active-high reset button, map to BTND
    input  logic [15:0] SW,
    input  logic        btn_execute,  // map to BTNC

    output logic [15:0] LED,
    output logic [6:0]  seg,
    output logic [3:0]  an,
    output logic        dp,
    output logic        uart_tx,

    // Debug/test visibility
    output logic [7:0]  alu_result,
    output logic        system_done,
    output logic        system_error,
    output logic [3:0]  error_code,
    output logic [7:0]  latency_count
);

    logic rst_n;
    assign rst_n = ~btn_reset;

    logic [2:0] mode, op, fault_type;
    logic [4:0] data_a, data_b;
    logic       fault_enable;
    logic       start_pulse;

    logic       alu_valid, alu_ready, alu_done, alu_invalid_op, alu_checksum_fail;
    logic       fifo_wr_valid, fifo_rd_valid, fifo_full, fifo_empty, fifo_overflow, fifo_underflow;
    logic [7:0] fifo_rdata;
    logic [3:0] fifo_count;
    logic       dma_start, dma_busy, dma_done, dma_timeout;
    logic [7:0] dma_count;
    logic       error_seen;
    logic [3:0] error_code_raw;
    logic       busy;
    logic [3:0] state_dbg;
    logic       uart_busy;

    // Fault-mode behavior
    logic force_dma_timeout;
    logic injected_checksum_fail;
    logic injected_invalid_op;
    logic injected_fifo_overflow;

    assign force_dma_timeout       = fault_enable && (fault_type == FAULT_TIMEOUT);
    assign injected_checksum_fail  = fault_enable && (fault_type == FAULT_CSUM);
    assign injected_invalid_op     = fault_enable && (fault_type == FAULT_INVALID_OP);
    assign injected_fifo_overflow  = fault_enable && (fault_type == FAULT_FIFO_OVF);

    input_interface u_input_interface (
        .clk(clk), .rst_n(rst_n), .SW(SW), .btn_execute(btn_execute),
        .mode(mode), .op(op), .data_a(data_a), .data_b(data_b),
        .fault_enable(fault_enable), .fault_type(fault_type), .start_pulse(start_pulse)
    );

    alu_block u_alu_block (
        .clk(clk), .rst_n(rst_n), .valid(alu_valid), .ready(alu_ready),
        .op(op), .data_a(data_a), .data_b(data_b),
        .result(alu_result), .done(alu_done), .error_flag(alu_invalid_op),
        .checksum_fail(alu_checksum_fail)
    );

    fifo_buffer #(.WIDTH(8), .DEPTH(8)) u_fifo_buffer (
        .clk(clk), .rst_n(rst_n),
        .wr_valid(fifo_wr_valid || injected_fifo_overflow), .wr_ready(), .wr_data({3'd0, data_a}),
        .rd_valid(fifo_rd_valid), .rd_ready(), .rd_data(fifo_rdata),
        .full(fifo_full), .empty(fifo_empty),
        .overflow(fifo_overflow), .underflow(fifo_underflow), .count(fifo_count)
    );

    dma_engine #(.MAX_CYCLES(20)) u_dma_engine (
        .clk(clk), .rst_n(rst_n), .start(dma_start), .length(data_b),
        .force_timeout(force_dma_timeout), .busy(dma_busy), .done(dma_done),
        .timeout(dma_timeout), .dma_count(dma_count)
    );

    error_monitor u_error_monitor (
        .invalid_op(alu_invalid_op || injected_invalid_op),
        .fifo_overflow(fifo_overflow || injected_fifo_overflow),
        .fifo_underflow(fifo_underflow),
        .timeout(dma_timeout),
        .checksum_fail(alu_checksum_fail || injected_checksum_fail),
        .fault_enable(fault_enable), .fault_type(fault_type),
        .error_flag(error_seen), .error_code(error_code_raw)
    );

    control_fsm u_control_fsm (
        .clk(clk), .rst_n(rst_n), .start_pulse(start_pulse), .mode(mode), .op(op),
        .alu_ready(alu_ready), .alu_done(alu_done), .dma_done(dma_done), .error_seen(error_seen),
        .alu_valid(alu_valid), .fifo_wr_valid(fifo_wr_valid), .fifo_rd_valid(fifo_rd_valid),
        .dma_start(dma_start), .busy(busy), .system_done(system_done),
        .system_error(system_error), .state_dbg(state_dbg)
    );


    // Latch error codes so the code remains visible during the FSM's
    // one-cycle system_error pulse. Many error sources, such as an invalid
    // ALU op, are transaction pulses, so the raw combinational error_code
    // can return to 0 before the testbench/hardware display samples it.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            error_code <= ERR_NONE;
        end else if (start_pulse) begin
            error_code <= ERR_NONE;
        end else if (error_seen) begin
            error_code <= error_code_raw;
        end
    end

    // Cycle-level latency tracking from execute pulse until DONE/ERROR.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            latency_count <= 8'd0;
        end else if (start_pulse) begin
            latency_count <= 8'd0;
        end else if (busy && latency_count != 8'hFF) begin
            latency_count <= latency_count + 1'b1;
        end
    end

    display_controller u_display_controller (
        .clk(clk), .rst_n(rst_n), .mode(mode), .result(alu_result),
        .fifo_count(fifo_count), .dma_count(dma_count), .error_code(error_code),
        .latency(latency_count), .idle(!busy && !system_done && !system_error),
        .busy(busy), .done(system_done), .error(system_error),
        .fifo_full(fifo_full), .fifo_empty(fifo_empty), .dma_active(dma_busy),
        .timeout(dma_timeout), .checksum_fail(alu_checksum_fail || injected_checksum_fail),
        .LED(LED), .seg(seg), .an(an), .dp(dp)
    );

    uart_debug u_uart_debug (
        .clk(clk), .rst_n(rst_n), .event_valid(system_done || system_error),
        .mode(mode), .op(op), .result(alu_result), .error_code(error_code),
        .tx(uart_tx), .busy(uart_busy)
    );

endmodule
