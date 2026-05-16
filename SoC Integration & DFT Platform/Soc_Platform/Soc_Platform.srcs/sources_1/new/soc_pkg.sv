`timescale 1ns / 1ps

package soc_pkg;
  // =========================================================
  // Demo modes from SW[15:13]
  // =========================================================
  localparam logic [2:0] MODE_ALU    = 3'd0;
  localparam logic [2:0] MODE_FIFO   = 3'd1;
  localparam logic [2:0] MODE_DMA    = 3'd2;
  localparam logic [2:0] MODE_FAULT  = 3'd3;
  localparam logic [2:0] MODE_TIMING = 3'd4;

  // =========================================================
  // ALU / demo operation encodings from SW[12:10]
  // =========================================================
  localparam logic [2:0] OP_ADD      = 3'd0;
  localparam logic [2:0] OP_SUB      = 3'd1;
  localparam logic [2:0] OP_AND      = 3'd2;
  localparam logic [2:0] OP_OR       = 3'd3;
  localparam logic [2:0] OP_CMP      = 3'd4;
  localparam logic [2:0] OP_CHECKSUM = 3'd5;

  // FIFO-mode op aliases
  localparam logic [2:0] FIFO_WRITE  = OP_ADD;
  localparam logic [2:0] FIFO_READ   = OP_SUB;

  // Fault injection types from SW[12:10] when MODE_FAULT is selected
  localparam logic [2:0] FAULT_INVALID_OP = 3'd0;
  localparam logic [2:0] FAULT_FIFO_OVF   = 3'd1;
  localparam logic [2:0] FAULT_TIMEOUT    = 3'd2;
  localparam logic [2:0] FAULT_CSUM       = 3'd3;

  // =========================================================
  // Error code encodings
  // =========================================================
  localparam logic [3:0] ERR_NONE        = 4'd0;
  localparam logic [3:0] ERR_INVALID_OP  = 4'd1;
  localparam logic [3:0] ERR_FIFO_OVF    = 4'd2;
  localparam logic [3:0] ERR_TIMEOUT     = 4'd3;
  localparam logic [3:0] ERR_CSUM_FAIL   = 4'd4;
  localparam logic [3:0] ERR_FAULT_INJ   = 4'd5;

  // =========================================================
  // Top-level control FSM states
  // =========================================================
  typedef enum logic [3:0] {
    ST_IDLE,
    ST_DECODE,
    ST_START_ALU,
    ST_WAIT_ALU,
    ST_FIFO_ACCESS,
    ST_START_DMA,
    ST_WAIT_DMA,
    ST_WRITE_RESULT,
    ST_ERROR,
    ST_DONE
  } state_t;
endpackage
