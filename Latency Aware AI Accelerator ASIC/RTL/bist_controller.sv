`timescale 1ns/1ps

module bist_controller (
    input  logic clk,
    input  logic rst_n,

    input  logic start,

    output logic busy,
    output logic done,
    output logic pass
);

    typedef enum logic [1:0] {
        S_IDLE,
        S_RUN,
        S_DONE
    } state_t;

    state_t state, next_state;

    logic [2:0] idx;
    logic signed [31:0] acc;

    logic signed [7:0] test_a;
    logic signed [7:0] test_b;
    logic signed [15:0] mult_result;
    logic signed [31:0] mult_extended;
    logic signed [31:0] acc_next;

    localparam logic signed [31:0] EXPECTED_RESULT = 32'sd70;

    // ------------------------------------------------------------
    // Test vector A
    // ------------------------------------------------------------
    always_comb begin
        unique case (idx)
            3'd0: test_a = 8'sd1;
            3'd1: test_a = 8'sd2;
            3'd2: test_a = 8'sd3;
            3'd3: test_a = 8'sd4;
            default: test_a = 8'sd0;
        endcase
    end

    // ------------------------------------------------------------
    // Test vector B
    // ------------------------------------------------------------
    always_comb begin
        unique case (idx)
            3'd0: test_b = 8'sd5;
            3'd1: test_b = 8'sd6;
            3'd2: test_b = 8'sd7;
            3'd3: test_b = 8'sd8;
            default: test_b = 8'sd0;
        endcase
    end

    assign mult_result   = test_a * test_b;
    assign mult_extended = {{16{mult_result[15]}}, mult_result};
    assign acc_next      = acc + mult_extended;

    // ------------------------------------------------------------
    // State register
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // ------------------------------------------------------------
    // Next-state logic
    // ------------------------------------------------------------
    always_comb begin
        next_state = state;

        unique case (state)
            S_IDLE: begin
                if (start)
                    next_state = S_RUN;
            end

            S_RUN: begin
                if (idx == 3'd3)
                    next_state = S_DONE;
            end

            S_DONE: begin
                next_state = S_IDLE;
            end

            default: begin
                next_state = S_IDLE;
            end
        endcase
    end

    // ------------------------------------------------------------
    // BIST datapath
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx  <= 3'd0;
            acc  <= 32'sd0;
            busy <= 1'b0;
            done <= 1'b0;
            pass <= 1'b0;
        end else begin
            unique case (state)
                S_IDLE: begin
                    busy <= 1'b0;

                    if (start) begin
                        idx  <= 3'd0;
                        acc  <= 32'sd0;
                        busy <= 1'b1;
                        done <= 1'b0;
                        pass <= 1'b0;
                    end
                end

                S_RUN: begin
                    busy <= 1'b1;
                    acc  <= acc_next;

                    if (idx == 3'd3) begin
                        pass <= (acc_next == EXPECTED_RESULT);
                    end else begin
                        idx <= idx + 3'd1;
                    end
                end

                S_DONE: begin
                    busy <= 1'b0;
                    done <= 1'b1;
                end

                default: begin
                    busy <= 1'b0;
                end
            endcase
        end
    end

endmodule