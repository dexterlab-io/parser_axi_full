# GHDL Simulation Guide — AXI-Full Backend

This document explains how to run the AXI-Full backend simulation using GHDL.

---

## 1. Directory Structure

Located under:

parser_axi_full/sim/ghdl/core/

Codice

Contains:

- Makefile
- tb_axi.vhd
- workdir/
- waveform files

---

## 2. Requirements

- GHDL (LLVM recommended)
- GTKWave
- MSYS2 / MINGW64 or Linux

---

## 3. Running the Simulation

### Full simulation:

make all

Codice

### Batch simulation:

make sim

Codice

### Interactive simulation:

make simwave

Codice

### View waveform:

make wave

Codice

---

## 4. Debug Logging

Enable in:

cmd_cfg.vhd

Codice

Set:

```vhdl
ENABLE_DEBUG_LOG := true;
5. Cleaning
Codice
make clean
6. Summary
GHDL provides fast, pure-VHDL simulation for the AXI-Full backend.

Codice

---

# 📄 7. `sim_vivado.md`

```markdown
# Vivado XSIM Simulation Guide — AXI-Full Backend

This document explains how to run the AXI-Full backend simulation using Vivado
XSIM.

---

## 1. Directory Structure

Located under:

parser_axi_full/sim/vivado/core/

Codice

Contains:

- Makefile
- stop_200us.tcl
- xsim_env.bat

---

## 2. Requirements

- Windows 10/11
- Vivado 2025.1
- settings64.bat available

---

## 3. Environment Setup

Run:

xsim_env.bat

Codice

---

## 4. Running the Simulation

### Full simulation:

make xsim

Codice

### GUI:

make xsim_gui

Codice

---

## 5. Debug Logging

Enable in:

cmd_cfg.vhd

Codice

Set:

```vhdl
ENABLE_DEBUG_LOG := true;
6. Cleaning
Codice
make clean
7. Summary
Vivado XSIM provides waveform-level AXI simulation with full GUI support.
