README — GHDL Simulation Environment
(parser_axi_full/sim/ghdl/core)
Overview
This directory contains the GHDL simulation environment for the AXI‑Full backend of the DexterLab Parser system.

The simulation validates:

the AXI‑Full backend (cmd_axi_full.vhd)

integration with the parser core (cmd_parser.vhd and related packages)

AXI burst handling (INCR, FIFO, WRAP)

multi‑beat sequencing

AXI channel behavior (AW, W, B, AR, R)

the complete AXI‑Full testbench (tb_axi.vhd)

This README explains how to run the simulation.
For architectural details and protocol documentation, refer to the main project documentation under docs/.

Directory Structure
File / Directory	Description
Makefile	Build, elaborate, simulate, and waveform automation
tb_axi.vhd	AXI‑Full top‑level testbench
workdir/	GHDL working directory (object files, elaboration artifacts)
wave.ghw / wave.vcd / wave.fst	Generated waveform files
README.md	This document


The Makefile automatically imports:

parser core sources from ../../../rtl/

AXI‑Full backend sources from ../../../rtl/

testbench sources from ../../../tb/

Requirements
GHDL (LLVM backend recommended)

GTKWave (waveform viewer)

MSYS2 / MINGW64 or Linux shell

VHDL‑93 or later

Makefile Overview
The Makefile supports:

separate compilation of RTL and testbench

selectable VHDL standard (93, 93c, 2002, 2008)

selectable waveform format (ghw, vcd, fst)

batch simulation

interactive simulation with GTKWave

automatic cleanup

Default top‑level entity:

Codice
tb_axi
Default waveform format:

Codice
ghw
Running the Simulation
Full simulation (compile + elaborate + run)
Codice
make all
This performs:

cleanup

RTL compilation

testbench compilation

elaboration

simulation

Batch simulation
Codice
make sim
Runs:

Codice
ghdl -r tb_axi --wave=wave.ghw --stop-time=200us
(Stop time can be adjusted in the Makefile.)

Interactive simulation + waveform
Codice
make simwave
This target:

removes any previous waveform

runs the simulation with --assert-level=note

opens GTKWave automatically

Useful for debugging.

Waveform Viewing
Manual waveform viewing:

Codice
make wave
or:

Codice
gtkwave wave.ghw &
Debug Logging
Debug messages (severity note) are controlled by:

vhdl
constant ENABLE_DEBUG_LOG : boolean := false;
located in:

Codice
cmd_cfg.vhd
Debug OFF (default)
suppresses all debug prints

warnings, errors, and fatals remain active

Debug ON
Set:

vhdl
ENABLE_DEBUG_LOG := true;
Cleaning
Codice
make clean
This removes:

workdir/*.o

workdir/*.cf

waveform files

local build artifacts

Additional Documentation
For complete information about:

parser architecture

command semantics

AXI‑Full behavior

burst/fifo/wrap handling

integration guidelines

refer to the documentation in the docs/ directory of the parser_axi_full project.
