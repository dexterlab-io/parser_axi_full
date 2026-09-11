# DexterLab AXI-Full Backend — Release Notes
Version: 1.0.0  
Date: 2026-09-10

---

## Overview

This release introduces the first standalone version of the DexterLab AXI-Full
backend. It provides a complete hardware backend capable of translating parser
commands into AXI-Full bus transactions, supporting multi-beat bursts, FIFO
operations, wrap addressing, and full AXI channel behavior.

The backend integrates with the DexterLab parser core (`parser_core v1.0.0`)
and includes full simulation support for both GHDL and Vivado/XSIM.

---

## Key Features

### AXI-Full RTL Backend
- Multi-beat burst engine (INCR, FIFO, WRAP).
- AXI write channel (AW, W, B) with WLAST generation.
- AXI read channel (AR, R) with RLAST generation.
- Address generator with wrap boundary enforcement.
- Byte-enable propagation (WSTRB).
- Response handling and error propagation.

### Parser Integration
- Fully compatible with the DexterLab command interface.
- Uses parser core version `parser_core v1.0.0`.
- No wrapper required; backend connects directly to the parser output.

### Testbench and Simulation
- Complete AXI testbench (`tb_axi.vhd`).
- AXI monitor and simple AXI slave model.
- FIFO generators and synchronous RAM models.
- GHDL simulation environment:
  - Makefile automation
  - waveform generation (ghw/vcd/fst)
  - debug logging support
- Vivado/XSIM simulation environment:
  - xvhdl/xelab/xsim flow
  - batch and GUI simulation
  - waveform database (`.wdb`)

### Documentation
- AXI-Full architecture
- command mapping
- timing and handshake rules
- error model
- integration guidelines
- simulation guides (GHDL and Vivado)

---

## Stability and Validation

The AXI-Full backend has been validated through:

- full GHDL simulation (waveform-level)
- full Vivado/XSIM simulation (waveform-level)
- multi-beat burst tests
- FIFO and wrap addressing tests
- read/write channel stress tests
- parser integration tests

The backend is considered **stable** for educational, research, and
non-commercial use.

---

## Known Limitations

- AXI-Full QoS, region, and user signals are not implemented.
- AXI-Full ID fields are fixed to a single master configuration.
- No support for AXI narrow bursts (byte-lane shifting).
- Error reporting is limited to parser response codes.

---

## Future Work

- AXI-Lite backend (separate repository).
- AHB-Full and AHB-Lite backends.
- TileLink bridge.
- Multi-master arbitration.
- Extended AXI-Full features (QoS, region, user signals).

---

## Summary

Version 1.0.0 delivers a complete, stable, and fully documented AXI-Full backend
for the DexterLab parser system. It is ready for integration, simulation, and
further development.

---
