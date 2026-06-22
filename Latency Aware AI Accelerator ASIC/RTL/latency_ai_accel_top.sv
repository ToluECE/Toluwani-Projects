`timescale 1ns/1ps

module latency_ai_accel_top #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 16,
    parameter int VEC_DEPTH  = 64
)(
    input  logic                  pclk,
    input  logic                  presetn,

    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic [DATA_WIDTH-1:0] pwdata,
    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr,

    output logic                  accel_busy,
    output logic                  accel_done,
    output logic [31:0]           accel_result
);

    // ------------------------------------------------------------
    // Internal control/status signals
    // ------------------------------------------------------------
    logic mac_start;
    logic bist_start;

    logic [7:0] vec_len;

    logic mac_busy;
    logic mac_done;
    logic signed [31:0] mac_result;
    logic [31:0] mac_cycle_count;

    logic bist_busy;
    logic bist_done;
    logic bist_pass;

    logic cfg_error;

    // ------------------------------------------------------------
    // Scratchpad interface
    // ------------------------------------------------------------
    logic spad_a_we;
    logic spad_b_we;
    logic [7:0] spad_wr_index;
    logic signed [7:0] spad_wr_data;

    logic spad_read_a;
    logic spad_read_b;
    logic [7:0] spad_rd_index;
    logic [31:0] spad_rd_data;

    logic [7:0] mac_rd_index;
    logic signed [7:0] mac_a_data;
    logic signed [7:0] mac_b_data;

    // ------------------------------------------------------------
    // APB register interface
    // ------------------------------------------------------------
    apb_reg_if #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .VEC_DEPTH (VEC_DEPTH)
    ) u_apb_reg_if (
        .clk             (pclk),
        .rst_n           (presetn),

        .psel            (psel),
        .penable         (penable),
        .pwrite          (pwrite),
        .paddr           (paddr),
        .pwdata          (pwdata),
        .prdata          (prdata),
        .pready          (pready),
        .pslverr         (pslverr),

        .mac_start       (mac_start),
        .bist_start      (bist_start),

        .vec_len         (vec_len),

        .mac_busy        (mac_busy),
        .mac_done        (mac_done),
        .mac_result      (mac_result),
        .mac_cycle_count (mac_cycle_count),

        .bist_busy       (bist_busy),
        .bist_done       (bist_done),
        .bist_pass       (bist_pass),

        .spad_a_we       (spad_a_we),
        .spad_b_we       (spad_b_we),
        .spad_wr_index   (spad_wr_index),
        .spad_wr_data    (spad_wr_data),

        .spad_read_a     (spad_read_a),
        .spad_read_b     (spad_read_b),
        .spad_rd_index   (spad_rd_index),
        .spad_rd_data    (spad_rd_data),

        .cfg_error       (cfg_error)
    );

    // ------------------------------------------------------------
    // Scratchpad memories
    // ------------------------------------------------------------
    scratchpad #(
        .VEC_DEPTH(VEC_DEPTH)
    ) u_scratchpad (
        .clk          (pclk),
        .rst_n        (presetn),

        .a_we         (spad_a_we),
        .b_we         (spad_b_we),
        .wr_index     (spad_wr_index),
        .wr_data      (spad_wr_data),

        .rd_index     (mac_rd_index),
        .a_rd_data    (mac_a_data),
        .b_rd_data    (mac_b_data),

        .apb_read_a   (spad_read_a),
        .apb_read_b   (spad_read_b),
        .apb_rd_index (spad_rd_index),
        .apb_rd_data  (spad_rd_data)
    );

    // ------------------------------------------------------------
    // INT8 MAC engine
    // ------------------------------------------------------------
    mac_engine #(
        .VEC_DEPTH(VEC_DEPTH)
    ) u_mac_engine (
        .clk         (pclk),
        .rst_n       (presetn),

        .start       (mac_start),
        .vec_len     (vec_len),

        .rd_index    (mac_rd_index),
        .a_data      (mac_a_data),
        .b_data      (mac_b_data),

        .busy        (mac_busy),
        .done        (mac_done),
        .result      (mac_result),
        .cycle_count (mac_cycle_count)
    );

    // ------------------------------------------------------------
    // BIST controller
    // ------------------------------------------------------------
    bist_controller u_bist_controller (
        .clk   (pclk),
        .rst_n (presetn),

        .start (bist_start),

        .busy  (bist_busy),
        .done  (bist_done),
        .pass  (bist_pass)
    );

    // ------------------------------------------------------------
    // External debug/status outputs
    // ------------------------------------------------------------
    assign accel_busy   = mac_busy | bist_busy;
    assign accel_done   = mac_done;
    assign accel_result = mac_result;

endmodule