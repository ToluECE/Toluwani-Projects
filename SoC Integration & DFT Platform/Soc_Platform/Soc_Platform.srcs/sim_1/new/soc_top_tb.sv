`timescale 1ns/1ps
import soc_pkg::*;

module soc_top_tb;

    logic        clk;
    logic        btn_reset;
    logic [15:0] SW;
    logic        btn_execute;

    logic [15:0] LED;
    logic [6:0]  seg;
    logic [3:0]  an;
    logic        dp;
    logic        uart_tx;
    logic [7:0]  alu_result;
    logic        system_done;
    logic        system_error;
    logic [3:0]  error_code;
    logic [7:0]  latency_count;

    soc_top dut (
        .clk(clk), .btn_reset(btn_reset), .SW(SW), .btn_execute(btn_execute),
        .LED(LED), .seg(seg), .an(an), .dp(dp), .uart_tx(uart_tx),
        .alu_result(alu_result), .system_done(system_done),
        .system_error(system_error), .error_code(error_code), .latency_count(latency_count)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task automatic apply_reset;
    begin
        btn_reset   = 1'b1;
        SW          = 16'd0;
        btn_execute = 1'b0;
        repeat (5) @(posedge clk);
        btn_reset = 1'b0;
        repeat (3) @(posedge clk);
    end
    endtask

    task automatic run_transaction(
        input logic [2:0] t_mode,
        input logic [2:0] t_op,
        input logic [4:0] t_a,
        input logic [4:0] t_b
    );
    begin
        @(negedge clk);
        SW[4:0]   = t_a;
        SW[9:5]   = t_b;
        SW[12:10] = t_op;
        SW[15:13] = t_mode;

        btn_execute = 1'b1;
        repeat (3) @(negedge clk); // long enough for 2-flop synchronizer
        btn_execute = 1'b0;
    end
    endtask

    task automatic wait_terminal;
        int cycles;
    begin
        cycles = 0;
        while ((system_done !== 1'b1) && (system_error !== 1'b1) && cycles < 80) begin
            @(posedge clk);
            cycles++;
        end
        if (cycles >= 80)
            $fatal(1, "Timeout waiting for done/error");
    end
    endtask

    task automatic expect_done(input string name);
    begin
        wait_terminal();
        if ((system_done !== 1'b1) || (system_error !== 1'b0))
            $fatal(1, "%s expected done without error", name);
        @(posedge clk);
    end
    endtask

    task automatic expect_error(input string name, input logic [3:0] exp_code);
    begin
        wait_terminal();
        if (system_error !== 1'b1)
            $fatal(1, "%s expected system_error", name);
        if (error_code !== exp_code)
            $fatal(1, "%s expected error_code=%0d got %0d", name, exp_code, error_code);
        @(posedge clk);
    end
    endtask

    // -----------------------------------------------------
    // Assertion layer: interview-useful safety checks
    // -----------------------------------------------------
    property done_or_error_one_cycle;
        @(posedge clk) disable iff (btn_reset)
        (system_done || system_error) |=> !(system_done || system_error);
    endproperty
    assert property (done_or_error_one_cycle)
        else $error("DONE/ERROR should be a one-cycle terminal pulse");

    property dma_bounded_latency;
        @(posedge clk) disable iff (btn_reset)
        dut.dma_start |-> ##[1:25] dut.dma_done;
    endproperty
    assert property (dma_bounded_latency)
        else $error("DMA did not finish within expected bounded latency");

    property no_fifo_write_when_full_without_error;
        @(posedge clk) disable iff (btn_reset)
        (dut.fifo_wr_valid && dut.fifo_full) |-> ##[0:2] system_error;
    endproperty
    assert property (no_fifo_write_when_full_without_error)
        else $error("FIFO full write did not produce an error");

    initial begin
        $display("Starting FPGA SoC Integration Platform tests...");
        apply_reset();

        // Mode 1: ALU normal ADD
        run_transaction(MODE_ALU, OP_ADD, 5'd5, 5'd3);
        expect_done("ALU ADD");
        if (alu_result !== 8'd8)
            $fatal(1, "ALU ADD expected 8 got %0d", alu_result);

        // ALU CMP
        run_transaction(MODE_ALU, OP_CMP, 5'd7, 5'd7);
        expect_done("ALU CMP");
        if (alu_result !== 8'd1)
            $fatal(1, "ALU CMP expected 1 got %0d", alu_result);

        // ALU invalid opcode
        run_transaction(MODE_ALU, 3'd6, 5'd1, 5'd1);
        expect_error("Invalid opcode", ERR_INVALID_OP);

        // Mode 2: FIFO write then read
        run_transaction(MODE_FIFO, FIFO_WRITE, 5'd21, 5'd0);
        expect_done("FIFO write");
        if (dut.fifo_count !== 4'd1)
            $fatal(1, "FIFO count expected 1 got %0d", dut.fifo_count);

        run_transaction(MODE_FIFO, FIFO_READ, 5'd0, 5'd0);
        expect_done("FIFO read");
        if (dut.fifo_count !== 4'd0)
            $fatal(1, "FIFO count expected 0 got %0d", dut.fifo_count);

        // Mode 3: DMA normal transfer, length = data_b = 6 cycles
        run_transaction(MODE_DMA, OP_ADD, 5'd0, 5'd6);
        expect_done("DMA normal");
        if (latency_count < 8'd5)
            $fatal(1, "DMA latency too small: %0d", latency_count);

        // Mode 4: Fault injection checksum failure
        run_transaction(MODE_FAULT, FAULT_CSUM, 5'd0, 5'd0);
        expect_error("Fault checksum", ERR_CSUM_FAIL);

        // Mode 5: Timing mode reuses ALU path but displays latency
        run_transaction(MODE_TIMING, OP_OR, 5'd12, 5'd10);
        expect_done("Timing mode");
        if (alu_result !== 8'd14)
            $fatal(1, "Timing OR expected 14 got %0d", alu_result);

        $display("ALL SOC TESTS PASSED.");
        $finish;
    end

endmodule
