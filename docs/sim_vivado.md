# ✅ **sim_vivado.md — Updated Version (2026 Edition)**

```markdown
# Vivado XSIM Simulation Guide — AXI‑Full Backend  
**DexterLab Documentation Suite — 2026 Edition**

This document explains how to run the AXI‑Full backend simulation using Vivado XSIM.  
XSIM provides waveform‑level AXI simulation with full GUI support.

---

## 1. Directory Structure

Located under:

parser_axi_full/sim/vivado/core/

Codice

Contains:

- `Makefile`
- `xsim_env.bat`
- `stop_200us.tcl`
- log files
- waveform database (`.wdb`)

---

## 2. Requirements

- **Windows 10/11**
- **Vivado 2025.1**
- `settings64.bat` available in the Vivado installation directory

---

## 3. Environment Setup

Before running any simulation, activate the Vivado environment:

xsim_env.bat

Codice

This loads `settings64.bat` and prepares the Vivado toolchain (`xvhdl`, `xelab`, `xsim`).

---

## 4. Running the Simulation

### Full simulation (compile + elaborate + run)

make xsim

Codice

### GUI simulation

make xsim_gui

Codice

or manually:

xsim tb_axi_sim --gui

Codice

---

## 5. Debug Logging

Debug logging is controlled in:

cmd_cfg.vhd

Codice

Enable debug messages by setting:

```vhdl
ENABLE_DEBUG_LOG := true;
Debug prints appear in the XSIM console output.

6. Generated Files
Vivado produces:

xsim.dir/ — XSIM working directory

tb_axi_sim.wdb — waveform database

.log, .jou — log files

.pb — elaboration database

7. Cleaning
To remove generated files:

Codice
make clean
This clears:

.Xil/

xsim.dir/

.log, .jou, .pb, .wdb

8. Summary
Vivado XSIM provides waveform‑level AXI simulation with full GUI support.
It validates:

AXI burst behavior

write/read channel correctness

timing and handshake rules

parser integration

For GHDL simulation, see sim_ghdl.md.
