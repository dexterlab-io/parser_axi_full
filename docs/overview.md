# AXI-Full Backend Documentation Overview

This directory contains all documentation related to the DexterLab AXI-Full
backend. The backend translates parser commands into AXI-Full bus transactions
and provides full support for multi-beat bursts, FIFO mode, wrap addressing, and
AXI-compliant handshake behavior.

The documentation is organized to be modular and easy to navigate.

---

## 1. Core Backend Documentation

### Architecture  
**`axi_full_architecture.md`**  
Describes the internal structure of the AXI-Full backend, including the burst
engine, address generator, write/read controllers, and response logic.

### Command Mapping  
**`axi_full_cmd_mapping.md`**  
Explains how parser commands are translated into AXI-Full transactions.

### Timing & Handshake  
**`axi_full_timing.md`**  
Formal definition of AXI-Full handshake rules and multi-beat sequencing.

### Error Model  
**`axi_full_errors.md`**  
Lists backend-specific error conditions and how they map to parser responses.

### Integration Guide  
**`axi_full_integration.md`**  
Guidelines for integrating the backend into RAM, peripherals, and SoC systems.

---

## 2. Simulation Documentation

### GHDL Simulation  
**`sim_ghdl.md`**  
Describes how to run the AXI-Full backend testbench using GHDL.

### Vivado / XSIM Simulation  
**`sim_vivado.md`**  
Explains how to run the AXI-Full backend testbench using Vivado XSIM.

---

## 3. Parser Core Dependency

The AXI-Full backend uses:

**Parser Core Version: `parser_core v1.0.0`**

Parser documentation is located in the main parser repository.

---

## 4. Documentation Philosophy

- **Modular** — each file covers one topic  
- **Backend-specific** — focused exclusively on AXI-Full behavior  
- **Parser-agnostic** — parser core is referenced but not duplicated  
- **Simulation-neutral** — supports GHDL and Vivado  
- **Readable** — diagrams, examples, and clear structure  

---

## 5. Summary

This directory contains all documentation required to understand, simulate, and
integrate the AXI-Full backend of the DexterLab command system.
