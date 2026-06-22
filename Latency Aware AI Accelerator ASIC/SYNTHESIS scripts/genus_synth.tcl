
# ------------------------------------------------------------
# SETUP
# ------------------------------------------------------------
set TOP latency_ai_accel_top

set PDK_ROOT /network/rit/lab/ceashpc/software/cadence/FreePDK45
set OSU_SOC $PDK_ROOT/osu_soc
set OSU_LIB $OSU_SOC/lib/files

set LIB $OSU_LIB/gscl45nm.lib

# ------------------------------------------------------------
# RTL file order
# Lower-level modules first, top-level module last
# ------------------------------------------------------------
set RTL_FILES [list \
    ../rtl/apb_reg_if.sv \
    ../rtl/scratchpad.sv \
    ../rtl/mac_engine.sv \
    ../rtl/bist_controller.sv \
    ../rtl/latency_ai_accel_top.sv \
]

# ------------------------------------------------------------
# Search paths
# ------------------------------------------------------------
set_db init_lib_search_path $OSU_LIB
set_db init_hdl_search_path ../rtl

# ------------------------------------------------------------
# Output folders
# ------------------------------------------------------------
file mkdir reports
file mkdir outputs
file mkdir logs

# ------------------------------------------------------------
# Library setup
# ------------------------------------------------------------
puts "============================================================"
puts "Using standard-cell library:"
puts $LIB
puts "============================================================"

set_db library $LIB

# ------------------------------------------------------------
# Read RTL
# ------------------------------------------------------------
puts "============================================================"
puts "Reading RTL"
puts "============================================================"

read_hdl -sv $RTL_FILES

# ------------------------------------------------------------
# Elaborate top design
# ------------------------------------------------------------
puts "============================================================"
puts "Elaborating top module: $TOP"
puts "============================================================"

elaborate $TOP

# ------------------------------------------------------------
# Initial design checks
# ------------------------------------------------------------
puts "============================================================"
puts "Checking design before synthesis"
puts "============================================================"

check_design > reports/check_design_pre_synth.rpt

# ------------------------------------------------------------
# Read timing constraints
# ------------------------------------------------------------
puts "============================================================"
puts "Reading constraints"
puts "============================================================"

read_sdc constraints.sdc

# ------------------------------------------------------------
# Synthesis
# ------------------------------------------------------------
puts "============================================================"
puts "Running generic synthesis"
puts "============================================================"
syn_generic

puts "============================================================"
puts "Running technology mapping"
puts "============================================================"
syn_map

puts "============================================================"
puts "Running optimization"
puts "============================================================"
syn_opt

# ------------------------------------------------------------
# Reports
# ------------------------------------------------------------
puts "============================================================"
puts "Writing synthesis reports"
puts "============================================================"


report_timing > reports/timing.rpt
report_timing -max_paths 20 > reports/timing_top20.rpt
report_timing -lint > reports/timing_lint.rpt
report_area > reports/area.rpt
report_power > reports/power.rpt
report_qor > reports/qor.rpt
report_gates > reports/gates.rpt
report_hierarchy > reports/hierarchy.rpt
report_registers > reports/registers.rpt
check_design > reports/check_design_post_synth.rpt

# ------------------------------------------------------------
# Outputs for gate-level sim / Innovus
# ------------------------------------------------------------
puts "============================================================"
puts "Writing mapped outputs"
puts "============================================================"

write_hdl > outputs/${TOP}_mapped.v
write_sdc > outputs/${TOP}_mapped.sdc
write_db outputs/${TOP}_genus.db

puts "============================================================"
puts "GENUS SYNTHESIS COMPLETE"
puts "Mapped netlist: outputs/${TOP}_mapped.v"
puts "Mapped SDC    : outputs/${TOP}_mapped.sdc"
puts "Reports       : reports/"
puts "============================================================"

exit