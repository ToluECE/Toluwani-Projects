# ASIC



# ============================================================
# Tool Paths
# ============================================================

# Cadence Genus synthesis
Genus(no gui + script) - /network/rit/lab/ceashpc/software/cadence/GENUS181/bin/genus -files script.tcl

Genus(with GUI) - /network/rit/lab/ceashpc/software/cadence/GENUS181/bin/genus -gui


# Cadence Innovus P n R
Innovus(no gui) - /network/rit/lab/ceashpc/software/cadence/INNOVUS201/bin/innovus

Innovus(with GUI) - /network/rit/lab/ceashpc/software/cadence/INNOVUS201/bin/innovus -gui



# ============================================================
# PDK Root
# ============================================================

PDK_ROOT=/network/rit/lab/ceashpc/software/cadence/FreePDK45

# Standard-cell kit for synthesis, place, and route
OSU_SOC=$PDK_ROOT/osu_soc

# Base kit for custom design, Calibre signoff, SPICE models, Virtuoso support
NCSU_BASEKIT=$PDK_ROOT/ncsu_basekit


# ============================================================
# OSU Standard-Cell Library Files
# Used for Genus + Innovus digital flow
# ============================================================

# Main library folder
OSU_LIB=$OSU_SOC/lib/files

# Genus synthesis timing/power library
LIB=$OSU_LIB/gscl45nm.lib

# Innovus physical abstract library
LEF=$OSU_LIB/gscl45nm.lef

# Innovus MMMC/timing library
TLF=$OSU_LIB/gscl45nm.tlf

# Compiled timing database
DB=$OSU_LIB/gscl45nm.db

# Gate-level Verilog standard-cell simulation models
VERILOG_CELLS=$OSU_LIB/gscl45nm.v

# VHDL standard-cell models
VHDL_CELLS=$OSU_LIB/gscl45nm.vhdl

# SPICE netlist for standard cells
SPICE_CELLS=$OSU_LIB/cells.sp

# GDS layer map for Encounter/Innovus streamOut
GDS_MAP=$OSU_LIB/gds2_encounter.map


# ============================================================
# OSU Standard-Cell Source GDS
# Used when doing final GDS merge/reference
# ============================================================

# Per-cell GDS library folder
STD_CELL_GDS_DIR=$OSU_SOC/lib/source/gds



# ============================================================
# NCSU Calibre Signoff Rule Decks
# Used after Innovus routing / GDS export
# ============================================================

CALIBRE_DIR=$NCSU_BASEKIT/techfile/calibre

# Calibre DRC rule deck
CALIBRE_DRC=$CALIBRE_DIR/calibreDRC.rul

# Calibre LVS rule deck
CALIBRE_LVS=$CALIBRE_DIR/calibreLVS.rul

# Calibre parasitic extraction / xRC rule deck
CALIBRE_PEX=$CALIBRE_DIR/calibrexRC.rul

# Calibre layer include file
CALIBRE_LAYER_INC=$CALIBRE_DIR/layer.inc


# ============================================================
# NCSU HSPICE / Transistor Model Files
# Used for SPICE simulation and post-layout extracted sims
# ============================================================

HSPICE_DIR=$NCSU_BASEKIT/models/hspice

# Main process corners
HSPICE_NOM=$HSPICE_DIR/hspice_nom.include
HSPICE_SS=$HSPICE_DIR/hspice_ss.include
HSPICE_FF=$HSPICE_DIR/hspice_ff.include

# Detailed transistor model folders
HSPICE_MODELS_NOM=$HSPICE_DIR/tran_models/models_nom
HSPICE_MODELS_SS=$HSPICE_DIR/tran_models/models_ss
HSPICE_MODELS_FF=$HSPICE_DIR/tran_models/models_ff


# ============================================================
# NCSU Virtuoso / Techfile Support
# ============================================================

TECHFILE=$NCSU_BASEKIT/techfile/FreePDK45.tf
TECHFILE_CNI=$NCSU_BASEKIT/techfile/cni/Santana.tech
DISPLAY_DRF=$NCSU_BASEKIT/cdssetup/display.drf
CDS_LIB=$NCSU_BASEKIT/cdssetup/cds.lib
CDS_SETUP=$NCSU_BASEKIT/cdssetup/setup.csh


# ============================================================
# Documentation
# ============================================================

FREEPDK45_MANUAL=$NCSU_BASEKIT/doc/FreePDK45_Manual.txt
FREEPDK45_RELEASE_NOTES=$NCSU_BASEKIT/doc/FreePDK45_Release_Notes.txt