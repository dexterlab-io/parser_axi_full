📘 DexterLab AXI‑Full Backend Documentation
(Directory: parser_axi_full/docs/)

This directory contains all documentation related to the AXI‑Full backend of the DexterLab command system.
It describes how parser commands are translated into AXI‑Full bus transactions, how burst semantics are handled, how the backend integrates with the parser core, and how to simulate and validate the design.

The documentation is modular, readable, and structured so each file can be consulted independently.

1. AXI-Full Backend Documentation
AXI-Full Backend Architecture
axi_full_architecture.md  
Describes the internal architecture of the AXI-Full backend, including the command expansion engine, burst sequencing, address generation (INCR, FIFO, WRAP), write and read channel behavior, and response handling.

AXI-Full Command Mapping
axi_full_cmd_mapping.md  
Explains how parser commands (t_cmd_out) are translated into AXI-Full transactions, including multi-beat bursts, byte-enable propagation, and timing rules.

AXI-Full Timing & Handshake
axi_full_timing.md  
Formal definition of AXI-Full handshake behavior (AW/W/B/AR/R), including ready/valid rules, multi-beat sequencing, WLAST/RLAST generation, and alignment constraints.

AXI-Full Error Model
axi_full_errors.md  
Lists backend-specific error conditions (alignment, burst length, wrap boundaries, FIFO violations) and describes how they map to parser response codes.

AXI-Full Integration Guide
axi_full_integration.md  
Provides guidelines for integrating the AXI-Full backend into SoC designs, including RAM/peripheral interfacing, arbitration, and multi-master environments.

2. Parser Core Dependency
The AXI-Full backend depends on the DexterLab parser core.
The specific parser version used in this release is:

Parser Core Version: parser_core v1.0.0
The parser core is not duplicated inside this repository.
It is included as a dependency and referenced by the simulation and backend RTL.

For parser documentation, refer to the main parser repository.

3. Simulation Documentation
GHDL Simulation
sim_ghdl.md  
Describes how to run the AXI-Full backend testbench using GHDL, including Makefile usage, waveform generation, debug logging, and directory structure.

Vivado / XSIM Simulation
sim_vivado.md  
Explains how to run the AXI-Full backend testbench using Vivado XSIM, including environment setup, compilation, elaboration, batch simulation, GUI usage, and cleanup.

Both simulation environments validate:

AXI-Full burst behavior

write/read channel correctness

parser integration

timing and handshake rules

response generation

4. Documentation Philosophy
The AXI-Full backend documentation follows these principles:

Modular — each file covers one topic

Backend-specific — focused exclusively on AXI-Full behavior

Parser-agnostic — parser core is referenced but not duplicated

Simulation-neutral — supports GHDL, Vivado, and professional simulators

Readable — diagrams, examples, and clear structure

5. How to Navigate
If you are new to the AXI-Full backend:

Start with axi_full_architecture.md

Continue with axi_full_cmd_mapping.md

Read axi_full_timing.md for handshake and sequencing

Validate your integration using sim_ghdl.md or sim_vivado.md

If you are integrating hardware:

Read axi_full_integration.md

Review axi_full_errors.md

Consult the parser core documentation for command semantics

6. Summary
The docs/ directory contains:

complete AXI-Full backend architecture

command mapping and timing rules

backend-specific error model

integration guidelines

GHDL and Vivado simulation documentation

reference to the parser core version used

This README serves as the entry point for navigating all AXI-Full backend documentation.

End of Document
