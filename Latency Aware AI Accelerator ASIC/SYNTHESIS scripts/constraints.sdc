# ============================================================
# SDC Constraints
# Clock: 100 MHz
# ============================================================

create_clock -name pclk -period 10.000 [get_ports pclk]

# Asynchronous active-low reset
set_false_path -from [get_ports presetn]

# Input delays
set_input_delay 1.000 -clock pclk [get_ports {
    psel
    penable
    pwrite
    paddr[*]
    pwdata[*]
}]

# Input transition estimate
set_input_transition 0.100 [get_ports {
    psel
    penable
    pwrite
    paddr[*]
    pwdata[*]
}]

# Output delays
set_output_delay 1.000 -clock pclk [get_ports {
    prdata[*]
    pready
    pslverr
    accel_busy
    accel_done
    accel_result[*]
}]

# Output load estimate
set_load 0.050 [all_outputs]

# Design rule constraints
set_max_transition 0.500 [current_design]
set_max_fanout 16 [current_design]