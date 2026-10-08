✅ sim_ghdl.md — Updated Version (2026 Edition)
markdown
# GHDL Simulation Guide — AXI‑Full Backend  
**DexterLab Documentation Suite — 2026 Edition**

This document explains how to run the AXI‑Full backend simulation using GHDL.  
The GHDL environment provides fast, pure‑VHDL simulation suitable for functional and waveform‑level validation.

---

## 1. Directory Structure

Located under:

parser_axi_full/sim/ghdl/core/

Codice

Contains:

- `Makefile`
- `tb_axi.vhd`
- `workdir/`
- waveform files (`.ghw`, `.vcd`, `.fst`)
- log files

---

## 2. Requirements

- **GHDL** (LLVM backend recommended)
- **GTKWave** for waveform viewing
- **MSYS2 / MINGW64** or **Linux**

---

## 3. Running the Simulation

### Full simulation (compile + elaborate + run)

make all

Codice

### Batch simulation (no GUI)

make sim

Codice

### Interactive simulation (run + open waveform)

make simwave

Codice

### View waveform only

make wave

Codice

---

## 4. Debug Logging

Debug logging is controlled in:

cmd_cfg.vhd

Codice

Enable debug messages by setting:

```vhdl
ENABLE_DEBUG_LOG := true;
Debug prints appear in the GHDL console output.

5. Generated Files
GHDL produces:

workdir/ — compilation artifacts

tb_axi.ghw — GTKWave waveform

.vcd / .fst — optional waveform formats

sim.log — simulation log

6. Cleaning
To remove generated files:

Codice
make clean
This clears:

workdir/

waveform files

log files

7. Summary
GHDL provides fast, pure‑VHDL simulation for the AXI‑Full backend.
It validates:

burst sequencing

address generation

AXI handshake behavior

parser integration

For Vivado simulation, see sim_vivado.md.
