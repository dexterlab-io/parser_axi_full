markdown
# AXI‑Full Backend Quickstart Guide  
**DexterLab Documentation Suite — 2026 Edition**

This guide provides a rapid introduction to using, simulating, and integrating the AXI‑Full backend.

---

## 1. What the Backend Does

The AXI‑Full backend converts parser commands (`t_cmd_out`) into AXI‑Full transactions:

- single transfers  
- INCR bursts  
- FIFO bursts  
- WRAP bursts  
- byte‑enable propagation  
- AXI‑compliant handshake behavior  

---

## 2. Minimal Integration

### Required Signals

Connect:

- `t_cmd_out` → backend  
- `t_rsp_in` ← backend  
- AXI AW/W/B channels  
- AXI AR/R channels  

### Clock & Reset

- single synchronous clock  
- active‑high synchronous reset  

---

## 3. Running GHDL Simulation

Inside:

parser_axi_full/sim/ghdl/core/

Codice

Run:

make all
make sim
make simwave
make wave

Codice

---

## 4. Running Vivado Simulation

Inside:

parser_axi_full/sim/vivado/core/

Codice

Run:

xsim_env.bat
make xsim
make xsim_gui

Codice

---

## 5. Common Debug Options

Enable debug logging in:

cmd_cfg.vhd

Codice

Set:

```vhdl
ENABLE_DEBUG_LOG := true;
6. Where to Go Next
Architecture → axi_full_architecture.md

Diagrams → axi_full_architecture_diagrams.md

Command Mapping → axi_full_cmd_mapping.md

Timing → axi_full_timing.md

Errors → axi_full_errors.md

Integration → axi_full_integration.md

7. Summary
This quickstart provides the essential steps to begin using and simulating the AXI‑Full backend.

Codice

---

# ✅ **testbench_architecture.md**

```markdown
# AXI‑Full Testbench Architecture  
**DexterLab Documentation Suite — 2026 Edition**

This document describes the structure of the AXI‑Full backend testbench used in GHDL and Vivado simulations.

---

## 1. Testbench Components

### 1.1 DUT (Device Under Test)
- AXI‑Full backend  
- connected to AXI slave model  
- connected to parser command generator  

### 1.2 AXI Slave Model
Implements:

- AW/W/B channels  
- AR/R channels  
- burst behavior  
- FIFO mode  
- WRAP mode  
- error injection (SLVERR, DECERR)  

### 1.3 RAM Model
Used for:

- INCR bursts  
- WRAP bursts  
- partial writes (WSTRB)  

### 1.4 FIFO Peripheral Model
Used for:

- FIFO bursts  
- constant‑address behavior  

### 1.5 Parser Command Generator
Produces:

- single commands  
- INCR bursts  
- FIFO bursts  
- WRAP bursts  
- alignment tests  
- error tests  

---

## 2. Monitors

### Write Monitor
Checks:

- AW/W/B sequencing  
- WLAST correctness  
- WSTRB correctness  

### Read Monitor
Checks:

- AR/R sequencing  
- RLAST correctness  
- data integrity  

---

## 3. Scoreboard

Tracks:

- expected vs actual AXI responses  
- expected vs actual read data  
- error conditions  

---

## 4. Logging

Controlled by:

cmd_cfg.vhd
ENABLE_DEBUG_LOG := true;

Codice

Logs:

- command execution  
- AXI handshake  
- burst sequencing  
- error detection  

---

## 5. Summary

The testbench provides a complete environment for validating AXI‑Full backend behavior across all burst types, timing rules, and error conditions.
