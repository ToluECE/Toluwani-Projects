`timescale 1ns/1ps

module apb_reg_if #(
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_WIDTH = 16,
    parameter int VEC_DEPTH  = 64
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic [DATA_WIDTH-1:0] pwdata,
    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr,

    output logic                  mac_start,
    output logic                  bist_start,

    output logic [7:0]            vec_len,

    input  logic                  mac_busy,
    input  logic                  mac_done,
    input  logic signed [31:0]    mac_result,
    input  logic [31:0]           mac_cycle_count,

    input  logic                  bist_busy,
    input  logic                  bist_done,
    input  logic                  bist_pass,

    output logic                  spad_a_we,
    output logic                  spad_b_we,
    output logic [7:0]            spad_wr_index,
    output logic signed [7:0]     spad_wr_data,

    output logic                  spad_read_a,
    output logic                  spad_read_b,
    output logic [7:0]            spad_rd_index,
    input  logic [31:0]           spad_rd_data,

    output logic                  cfg_error
);

    // ------------------------------------------------------------
    // Address Map
    // ------------------------------------------------------------
    localparam logic [15:0] ADDR_CTRL        = 16'h0000;
    localparam logic [15:0] ADDR_STATUS      = 16'h0004;
    localparam logic [15:0] ADDR_LEN         = 16'h0008;
    localparam logic [15:0] ADDR_RESULT      = 16'h000C;
    localparam logic [15:0] ADDR_CYCLE_COUNT = 16'h0010;

    localparam logic [15:0] ADDR_A_BASE      = 16'h0100;
    localparam logic [15:0] ADDR_B_BASE      = 16'h0200;

    logic apb_write;
    logic apb_read;

    logic addr_is_a_spad;
    logic addr_is_b_spad;
    logic addr_is_reg;

    assign apb_write = psel && penable && pwrite;
    assign apb_read  = psel && penable && !pwrite;

    assign pready = 1'b1;

    assign addr_is_a_spad =
        (paddr >= ADDR_A_BASE) &&
        (paddr <  ADDR_A_BASE + (VEC_DEPTH * 4));

    assign addr_is_b_spad =
        (paddr >= ADDR_B_BASE) &&
        (paddr <  ADDR_B_BASE + (VEC_DEPTH * 4));

    assign addr_is_reg =
        (paddr == ADDR_CTRL)        ||
        (paddr == ADDR_STATUS)      ||
        (paddr == ADDR_LEN)         ||
        (paddr == ADDR_RESULT)      ||
        (paddr == ADDR_CYCLE_COUNT);

    assign spad_wr_index = paddr[7:2];
    assign spad_wr_data  = pwdata[7:0];

    assign spad_rd_index = paddr[7:2];

    // ------------------------------------------------------------
    // Register write path
    // ------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vec_len    <= 8'd0;
            mac_start  <= 1'b0;
            bist_start <= 1'b0;
            cfg_error  <= 1'b0;
        end else begin
            mac_start  <= 1'b0;
            bist_start <= 1'b0;

            if (apb_write) begin
                unique case (paddr)
                    ADDR_CTRL: begin
                        if (!mac_busy && !bist_busy) begin
                            mac_start  <= pwdata[0];
                            bist_start <= pwdata[2];
                        end
                    end

                    ADDR_LEN: begin
                        if ((pwdata[7:0] != 8'd0) &&
                            (pwdata[7:0] <= VEC_DEPTH[7:0])) begin
                            vec_len   <= pwdata[7:0];
                            cfg_error <= 1'b0;
                        end else begin
                            cfg_error <= 1'b1;
                        end
                    end

                    default: begin
                        // Scratchpad writes are handled with decoded write enables.
                    end
                endcase
            end
        end
    end

    // ------------------------------------------------------------
    // Scratchpad write enables
    // ------------------------------------------------------------
    always_comb begin
        spad_a_we = 1'b0;
        spad_b_we = 1'b0;

        if (apb_write && !mac_busy && !bist_busy) begin
            if (addr_is_a_spad)
                spad_a_we = 1'b1;
            else if (addr_is_b_spad)
                spad_b_we = 1'b1;
        end
    end

    // ------------------------------------------------------------
    // Scratchpad read decode
    // ------------------------------------------------------------
    always_comb begin
        spad_read_a = 1'b0;
        spad_read_b = 1'b0;

        if (apb_read) begin
            if (addr_is_a_spad)
                spad_read_a = 1'b1;
            else if (addr_is_b_spad)
                spad_read_b = 1'b1;
        end
    end

    // ------------------------------------------------------------
    // APB read path
    // ------------------------------------------------------------
    always_comb begin
        prdata  = 32'd0;
        pslverr = 1'b0;

        if (psel && penable) begin
            if (!addr_is_reg && !addr_is_a_spad && !addr_is_b_spad)
                pslverr = 1'b1;
        end

        if (apb_read) begin
            unique case (paddr)
                ADDR_CTRL: begin
                    prdata = 32'd0;
                end

                ADDR_STATUS: begin
                    prdata = {
                        26'd0,
                        cfg_error,
                        bist_pass,
                        bist_done,
                        mac_done,
                        bist_busy | mac_busy,
                        mac_busy
                    };
                end

                ADDR_LEN: begin
                    prdata = {24'd0, vec_len};
                end

                ADDR_RESULT: begin
                    prdata = mac_result;
                end

                ADDR_CYCLE_COUNT: begin
                    prdata = mac_cycle_count;
                end

                default: begin
                    if (addr_is_a_spad || addr_is_b_spad)
                        prdata = spad_rd_data;
                    else
                        prdata = 32'd0;
                end
            endcase
        end
    end

endmodule