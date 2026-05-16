`timescale 1ns / 1ps
import soc_pkg::*;

module display_controller (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [2:0]  mode,
    input  logic [7:0]  result,
    input  logic [3:0]  fifo_count,
    input  logic [7:0]  dma_count,
    input  logic [3:0]  error_code,
    input  logic [7:0]  latency,

    input  logic        idle,
    input  logic        busy,
    input  logic        done,
    input  logic        error,
    input  logic        fifo_full,
    input  logic        fifo_empty,
    input  logic        dma_active,
    input  logic        timeout,
    input  logic        checksum_fail,

    output logic [15:0] LED,
    output logic [6:0]  seg,
    output logic [3:0]  an,
    output logic        dp
);

    logic [15:0] display_value;
    logic [15:0] refresh;
    logic [1:0]  digit_sel;
    logic [3:0]  hex_digit;

    always_comb begin
        unique case (mode)
            MODE_ALU:    display_value = {8'd0, result};
            MODE_FIFO:   display_value = {12'd0, fifo_count};
            MODE_DMA:    display_value = {8'd0, dma_count};
            MODE_FAULT:  display_value = {12'd0, error_code};
            MODE_TIMING: display_value = {8'd0, latency};
            default:     display_value = 16'hDEAD;
        endcase
    end

    always_ff @(posedge clk) begin
        if (!rst_n)
            refresh <= 16'd0;
        else
            refresh <= refresh + 1'b1;
    end

    assign digit_sel = refresh[15:14];

    always_comb begin
        an        = 4'b1111;
        hex_digit = 4'h0;
        case (digit_sel)
            2'd0: begin an = 4'b1110; hex_digit = display_value[3:0];   end
            2'd1: begin an = 4'b1101; hex_digit = display_value[7:4];   end
            2'd2: begin an = 4'b1011; hex_digit = display_value[11:8];  end
            2'd3: begin an = 4'b0111; hex_digit = display_value[15:12]; end
            default: begin an = 4'b1111; hex_digit = 4'h0; end
        endcase
    end

    // Basys 3 seven-segment is active low: seg = {g,f,e,d,c,b,a}
    always_comb begin
        case (hex_digit)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1000000;
        endcase
    end

    assign dp = 1'b1;

    always_comb begin
        LED = 16'd0;
        LED[0] = idle;
        LED[1] = busy;
        LED[2] = done;
        LED[3] = error;
        LED[4] = fifo_full;
        LED[5] = fifo_empty;
        LED[6] = dma_active;
        LED[7] = timeout;
        LED[8] = checksum_fail;
        LED[9] = (mode == MODE_TIMING);
        LED[12:10] = mode;
        LED[15:13] = error_code[2:0];
    end

endmodule
