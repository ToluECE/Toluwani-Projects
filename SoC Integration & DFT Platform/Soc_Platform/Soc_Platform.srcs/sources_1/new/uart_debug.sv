`timescale 1ns / 1ps

module uart_debug #(
    parameter int CLK_HZ = 100_000_000,
    parameter int BAUD   = 115200
)(
    input  logic       clk,
    input  logic       rst_n,
    input  logic       event_valid,
    input  logic [2:0] mode,
    input  logic [2:0] op,
    input  logic [7:0] result,
    input  logic [3:0] error_code,
    output logic       tx,
    output logic       busy
);

    localparam int CLKS_PER_BIT = CLK_HZ / BAUD;
    localparam int BIT_W = $clog2(CLKS_PER_BIT);

    typedef enum logic [1:0] {U_IDLE, U_START, U_DATA, U_STOP} uart_state_t;
    uart_state_t state_q;

    logic [BIT_W-1:0] clk_count;
    logic [2:0]       bit_index;
    logic [7:0]       tx_byte;

    // Compact debug packet: one byte that changes with mode/op/result/error.
    // This keeps hardware small while proving UART observability.
    always_comb begin
        tx_byte = {1'b0, mode, op[1:0], ^result, |error_code};
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state_q   <= U_IDLE;
            clk_count <= '0;
            bit_index <= 3'd0;
            tx        <= 1'b1;
            busy      <= 1'b0;
        end else begin
            unique case (state_q)
                U_IDLE: begin
                    tx        <= 1'b1;
                    clk_count <= '0;
                    bit_index <= 3'd0;
                    busy      <= 1'b0;
                    if (event_valid) begin
                        busy    <= 1'b1;
                        state_q <= U_START;
                    end
                end

                U_START: begin
                    tx <= 1'b0;
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= '0;
                        state_q   <= U_DATA;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                U_DATA: begin
                    tx <= tx_byte[bit_index];
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= '0;
                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state_q   <= U_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                U_STOP: begin
                    tx <= 1'b1;
                    if (clk_count == CLKS_PER_BIT-1) begin
                        clk_count <= '0;
                        state_q   <= U_IDLE;
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end
            endcase
        end
    end

endmodule
