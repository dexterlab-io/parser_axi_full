markdown
# AXI‑Full Backend — Documentation Index  
**DexterLab Documentation Suite — 2026 Edition**

This index provides a complete overview of all documentation files related to the AXI‑Full backend.

---

## 1. Core Backend Documentation

### Backend Overview  
`backend_axi_full.md`  
High‑level description of backend features, architecture, parser integration, and simulation support.

### Architecture  
`axi_full_architecture.md`  
Detailed description of internal backend structure: burst engine, address generator, controllers, response handler.

### Architecture Diagrams  
`axi_full_architecture_diagrams.md`  
ASCII diagrams illustrating backend data flow, burst sequencing, address generation, and response pipeline.

### Command Mapping  
`axi_full_cmd_mapping.md`  
Parser command → AXI‑Full transaction mapping, including burst types, byte‑enable propagation, and response mapping.

### Timing & Handshake  
`axi_full_timing.md`  
Formal AXI handshake rules, ready/valid behavior, beat sequencing, WLAST/RLAST generation, and corner cases.

### Error Model  
`axi_full_errors.md`  
Backend‑specific error conditions and parser response mapping.

### Integration Guide  
`axi_full_integration.md`  
Guidelines for integrating the backend into RAM, peripherals, SoC subsystems, and multi‑master systems.

---

## 2. Simulation Documentation

### GHDL Simulation  
`sim_ghdl.md`  
Fast, pure‑VHDL simulation environment.

### Vivado / XSIM Simulation  
`sim_vivado.md`  
Waveform‑level AXI simulation with GUI support.

---

## 3. Additional Documentation

### Testbench Architecture  
`testbench_architecture.md`  
Structure of the AXI‑Full backend testbench, including monitors, slave models, RAM models, and sequencing.

### Quickstart Guide  
`quickstart.md`  
Rapid introduction to backend usage, simulation, and integration.

### Address Map  
`address_map.md`  
Recommended address map structure for RAM and peripherals.

### Arbiter Specification  
`arbiter_specification.md`  
Rules for multi‑master arbitration and atomic command handling.

---

## 4. Parser Dependency

**Parser Core Version:** `parser_core v1.1.0`  
Fully backward‑compatible with `parser_core v1.0.0`.

---

## 5. Summary

This index provides a complete map of all AXI‑Full backend documentation files.
