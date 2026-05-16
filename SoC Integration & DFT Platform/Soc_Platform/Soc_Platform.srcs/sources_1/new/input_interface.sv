`timescale 1ns / 1ps

module input_interface (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [15:0] SW,
    input  logic        btn_execute,

    output logic [2:0]  mode,
    output logic [2:0]  op,
    output logic [4:0]  data_a,
    output logic [4:0]  data_b,
    output logic        fault_enable,
    output logic [2:0]  fault_type,
    output logic        start_pulse
);

    logic btn_sync_0, btn_sync_1;
    logic btn_prev;

    // Switch map:
    // SW[4:0]   = data A
    // SW[9:5]   = data B / DMA length helper
    // SW[12:10] = ALU op, FIFO command, or fault type
    // SW[15:13] = demo mode
    assign data_a       = SW[4:0];
    assign data_b       = SW[9:5];
    assign op           = SW[12:10];
    assign mode         = SW[15:13];
    assign fault_type   = SW[12:10];
    assign fault_enable = (SW[15:13] == 3'd3);

    // Button synchronizer
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= btn_execute;
            btn_sync_1 <= btn_sync_0;
        end
    end

    // Rising-edge detector
    always_ff @(posedge clk) begin
        if (!rst_n)
            btn_prev <= 1'b0;
        else
            btn_prev <= btn_sync_1;
    end

    assign start_pulse = btn_sync_1 & ~btn_prev;

endmodule
