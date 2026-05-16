# FPGA SoC Integration & Validation Platform

This  Basys 3 FPGA project takes form in a small SoC-style validation platform with multiple hardware blocks connected through a simple valid/ready style control flow.

The system lets you test:
- ALU operations
- FIFO buffering
- DMA-style multi-cycle transfers
- Fault/error detection
- Latency counting
- LED and seven-segment debug output

---

## 1. Project Files

Add these files to Vivado as **Design Sources**:

```text
soc_pkg.sv
input_interface.sv
alu_block.sv
fifo_buffer.sv
dma_engine.sv
error_monitor.sv
control_fsm.sv
display_controller.sv
uart_debug.sv
soc_top.sv
```

Add this file only as a **Simulation Source**:

```text
soc_top_tb.sv
```

Add this file as a **Constraints File**:

```text
constraints.xdc
```

---

## 2. Basic Board Controls

| Basys 3 Input | Meaning |
|---|---|
| `SW[15:0]` | Main control/input word |
| `BTNC` | Execute selected command |
| `BTND` | Reset system |

Press `BTND` once before testing.  
Set the switches for the mode you want.  
Press `BTNC` to run that command.

---

## 3. Switch Mapping

The 16 switches are decoded like this:

```text
SW[15:13] = mode
SW[12:10] = operation / command
SW[9:5]   = data_a
SW[4:0]   = data_b / fault_type
```

Example:

```text
SW = 16'h0065
```

This means:

```text
mode   = 000
op     = 000
data_a = 00011
data_b = 00101
```

So the system runs an ALU operation using A = 3 and B = 5.

---

## 4. Mapped Addresses / Mode Map

This project does not use a full CPU memory bus. Instead, the switch fields act like simple register-mapped control fields.

| Mode Bits | Mode Name | What It Tests |
|---|---|---|
| `000` | ALU Mode | ADD, SUB, AND, OR, compare, checksum |
| `001` | FIFO Mode | Write/read buffering and FIFO status |
| `010` | DMA Mode | Multi-cycle transfer behavior |
| `011` | Fault Mode | Injected errors and error monitor response |
| `100` | Timing Mode | Latency/count tracking |
| `101-111` | Reserved | Not used yet |

---

## 5. ALU Operation Map

When `SW[15:13] = 000`, the operation field selects the ALU command.

| `SW[12:10]` | ALU Operation |
|---|---|
| `000` | ADD |
| `001` | SUB |
| `010` | AND |
| `011` | OR |
| `100` | Compare |
| `101` | Checksum |
| `110-111` | Invalid / reserved |

---

## 6. Fault Type Map

In fault mode, the lower bits select which error case to inject.

| Fault Type | Meaning |
|---|---|
| `0` | Invalid operation |
| `1` | FIFO overflow |
| `2` | Timeout |
| `3` | Checksum failure |

---

## 7. LED Meanings

| LED | Meaning |
|---|---|
| `LED0` | System idle |
| `LED1` | System busy |
| `LED2` | Command done |
| `LED3` | System error |
| `LED4` | FIFO full |
| `LED5` | FIFO empty |
| `LED6` | DMA active |
| `LED7` | Timeout/error-related status |
| `LED8` | Checksum failure |
| `LED9` | Timing/pipeline mode active |

Other LEDs may show extra debug/status bits.

---

## 8. Seven-Segment Display

The seven-segment display changes based on the active mode.

| Mode | Display Shows |
|---|---|
| ALU Mode | ALU result |
| FIFO Mode | FIFO count/status |
| DMA Mode | DMA count/status |
| Fault Mode | Error code |
| Timing Mode | Latency count |

---

## 9. Error Codes

| Error Code | Meaning |
|---|---|
| `0` | No error |
| `1` | Invalid operation |
| `2` | FIFO overflow |
| `3` | Timeout |
| `4` | Checksum failure |

If `LED3` turns on, check the seven-segment display or `error_code` in simulation.

---

## 10. How to Use on the Basys 3

1. Program the FPGA with the generated bitstream.
2. Press `BTND` to reset.
3. Set `SW[15:13]` to choose the mode.
4. Set `SW[12:10]` to choose the operation.
5. Set `SW[9:5]` and `SW[4:0]` as input values.
6. Press `BTNC` to execute.
7. Watch the LEDs and seven-segment display.

---

## 11. Quick Demo Examples

### Example 1: ALU ADD

Set:

```text
SW[15:13] = 000
SW[12:10] = 000
SW[9:5]   = 00011
SW[4:0]   = 00101
```

This tests:

```text
3 + 5 = 8
```

Expected behavior:

```text
LED2 pulses/done
Seven-segment shows result 8
No error LED
```

---

### Example 2: Invalid ALU Operation

Set:

```text
SW[15:13] = 000
SW[12:10] = 110 or 111
```

Expected behavior:

```text
LED3 turns on for error
error_code = 1
```

---

### Example 3: FIFO Mode

Set:

```text
SW[15:13] = 001
```

Then press `BTNC`.

Expected behavior:

```text
FIFO status updates
LED4/LED5 show full/empty status
Seven-segment shows FIFO-related value
```

---

### Example 4: DMA Mode

Set:

```text
SW[15:13] = 010
```

Then press `BTNC`.

Expected behavior:

```text
LED6 shows DMA activity
system_done pulses after multi-cycle transfer
Seven-segment shows DMA/debug value
```

---

### Example 5: Fault Mode

Set:

```text
SW[15:13] = 011
SW[4:0]   = selected fault type
```

Then press `BTNC`.

Expected behavior:

```text
LED3 shows system error
Seven-segment shows error code
```

---

## 12. Simulation Test

Before programming the board, run behavioral simulation in Vivado.

Expected passing output:

```text
Starting FPGA SoC Integration Platform tests...
ALL SOC TESTS PASSED.
```

If you see this, the top-level integration test passed.

---

## 13. What This Project Demonstrates

This project capabilties:

- FSM-based control
- Datapath integration
- FIFO buffering
- DMA-style multi-cycle hardware behavior
- Error monitoring
- Fault injection
- Latency tracking
- FPGA hardware debug using LEDs and seven-segment display

Essentially:

> This is project allows switches act like register-mapped inputs, the FSM controls ALU/FIFO/DMA blocks, and the board outputs show status, results, latency, and error conditions.
