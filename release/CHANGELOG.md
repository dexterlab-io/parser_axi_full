# DexterLab AXI-Full Backend — Change Log

This file documents all notable changes introduced in public releases of the
DexterLab AXI-Full backend. Entries are listed from newest to oldest.

---

## [1.0.0] – 2026-09-10
### Added
- Initial public release of the AXI-Full backend.
- Complete AXI-Full RTL implementation:
  - Multi-beat burst engine (INCR, FIFO, WRAP).
  - AXI write and read channel logic (AW, W, B, AR, R).
  - Address generation and wrap boundary handling.
  - Byte-enable propagation and WSTRB support.
- Integration with DexterLab parser core (version: `parser_core v1.0.0`).
- Full AXI testbench (`tb_axi.vhd`) including:
  - AXI monitor
  - simple AXI slave model
  - FIFO generators
  - synchronous RAM models
- GHDL simulation environment (Makefile, waveform generation, debug logging).
- Vivado/XSIM simulation environment (xvhdl/xelab/xsim flow).
- Complete documentation under `docs/`:
  - AXI-Full architecture
  - command mapping
  - timing and handshake rules
  - error model
  - integration guidelines
  - simulation guides (GHDL and Vivado)

### Notes
This is the first standalone release of the AXI-Full backend.  
The backend is stable and fully validated through both GHDL and Vivado simulations.

---
