`timescale 1ns/1ps

module mac_engine #(
    parameter int VEC_DEPTH = 64
)(
    input  logic              clk,
    input  logic              rst_n,

    input  logic              start,
    input  logic [7:0]        vec_len,

    output logic [7:0]        rd_index,
    input  logic signed [7:0] a_data,
    input  logic signed [7:0] b_data,

    output logic              busy,
    output logic              done,
    output logic signed [31:0] result,
    output logic [31:0]       cycle_count
);

    typedef enum logic [1:0] {
        S_IDLE,
        S_RUN,
        S_DONE
    } state_t;

    state_t state, next_state;

    logic [7:0] idx;
    logic signed [31:0] acc;

    logic signed [15:0] mult_result;
    logic signed [31:0] mult_extended;
    logic signed [31:0] acc_next;

    assign rd_index      = idx;
    assign mult_result   = a_data * b_data;
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
                if (start && (vec_len != 8'd0))
                    next_state = S_RUN;
            end

            S_RUN: begin
                if (idx == vec_len - 1'b1)
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
    // Datapath and status registers
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx         <= 8'd0;
            acc         <= 32'sd0;
            result      <= 32'sd0;
            cycle_count <= 32'd0;
            busy        <= 1'b0;
            done        <= 1'b0;
        end else begin
            unique case (state)
                S_IDLE: begin
                    busy <= 1'b0;

                    if (start && (vec_len != 8'd0)) begin
                        idx         <= 8'd0;
                        acc         <= 32'sd0;
                        result      <= 32'sd0;
                        cycle_count <= 32'd0;
                        busy        <= 1'b1;
                        done        <= 1'b0;
                    end
                end

                S_RUN: begin
                    busy        <= 1'b1;
                    acc         <= acc_next;
                    cycle_count <= cycle_count + 32'd1;

                    if (idx == vec_len - 1'b1) begin
                        result <= acc_next;
                    end else begin
                        idx <= idx + 8'd1;
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