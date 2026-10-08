AXI‑Full Backend Documentation Overview
DexterLab Documentation Suite — 2026 Edition

This directory contains all documentation related to the DexterLab AXI‑Full backend.
The backend translates parser commands into AXI‑Full bus transactions and provides full support for multi‑beat bursts, FIFO mode, wrap addressing, byte‑enable propagation, and AXI‑compliant handshake behavior.

The documentation is modular, consistent, and designed for clarity, simulation, and integration.

1. Core Backend Documentation
Architecture
axi_full_architecture.md  
Describes the internal structure of the AXI‑Full backend, including the burst engine, address generator, write/read controllers, and response pipeline.

Architecture Diagrams
axi_full_architecture_diagrams.md  
ASCII diagrams illustrating the backend’s internal data flow, burst engine, address generator, and response handler.

Command Mapping
axi_full_cmd_mapping.md  
Explains how parser commands (t_cmd_out) are translated into AXI‑Full transactions, including burst types, byte‑enable propagation, and response mapping.

Timing & Handshake
axi_full_timing.md  
Formal definition of AXI‑Full handshake rules, beat sequencing, address phase timing, and corner‑case behavior.

Error Model
axi_full_errors.md  
Lists backend‑specific error conditions and how they map to parser responses. Includes alignment, burst length, wrap boundary, FIFO, and AXI slave errors.

Integration Guide
axi_full_integration.md  
Guidelines for integrating the backend into RAM, peripherals, SoC subsystems, and multi‑master systems. Includes arbitration rules and atomic mode behavior.

2. Simulation Documentation
GHDL Simulation
sim_ghdl.md  
Describes how to run the AXI‑Full backend testbench using GHDL, including Makefile automation, waveform generation, and debug logging.

Vivado / XSIM Simulation
sim_vivado.md  
Explains how to run the AXI‑Full backend testbench using Vivado XSIM, including environment setup, batch simulation, GUI usage, and directory cleanup.

3. Parser Core Dependency
The AXI‑Full backend uses:

Parser Core Version: parser_core v1.1.0  
Fully backward‑compatible with parser_core v1.0.0.

Parser documentation is located in the main parser repository.

4. Documentation Philosophy
Modular — each file covers one topic

Backend‑specific — focused exclusively on AXI‑Full behavior

Parser‑agnostic — parser core is referenced but not duplicated

Simulation‑neutral — supports both GHDL and Vivado

Readable — diagrams, examples, and clear structure

Cross‑linked — documents reference each other for easy navigation

5. Summary
This directory contains all documentation required to understand, simulate, and integrate the AXI‑Full backend of the DexterLab command system.
The documentation is complete, consistent, and aligned with the DexterLab 2026 architecture and parser ecosystem.
