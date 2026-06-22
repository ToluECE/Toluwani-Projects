

# ------------------------------------------------------------
# Library set
# ------------------------------------------------------------
create_library_set \
    -name typical_libs \
    -timing [list /network/rit/lab/ceashpc/software/cadence/FreePDK45/osu_soc/lib/files/gscl45nm.lib]

# ------------------------------------------------------------
# RC corner
#  first-pass RC estimate.
# ------------------------------------------------------------
create_rc_corner \
    -name typical_rc

# ------------------------------------------------------------
# Delay corner
# ------------------------------------------------------------
create_delay_corner \
    -name typical_delay \
    -library_set typical_libs \
    -rc_corner typical_rc

# ------------------------------------------------------------
# Constraint mode
# ------------------------------------------------------------
create_constraint_mode \
    -name functional_mode \
    -sdc_files [list /network/rit/home/ta173712/Tolu/synth/outputs/latency_ai_accel_top_mapped.sdc]

# ------------------------------------------------------------
# Analysis view
# ------------------------------------------------------------
create_analysis_view \
    -name functional_typical_view \
    -constraint_mode functional_mode \
    -delay_corner typical_delay

# ------------------------------------------------------------
# Set setup/hold views
# ------------------------------------------------------------
set_analysis_view \
    -setup [list functional_typical_view] \
    -hold  [list functional_typical_view]