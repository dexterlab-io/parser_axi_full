# DexterLab AXI-FULL Backend — Change Log

This file documents all notable changes introduced in public releases of the DexterLab AXI-FULL backend.

Entries are listed from newest to oldest.

---

# [1.2.0] - 2026-11-16

## Changed

### Parser Integration

Updated backend interfaces to align with the DexterLab Parser v1.1.0 architecture.

Updated integration model:

```text
t_cmd_out
t_rsp_out
t_rsp_in
```

Updated command completion handling through:

```text
rsp_end_cmd
```

Updated ownership retention support through:

```text
cmd_lock
```

---

### Arbiter Integration

Aligned backend behavior with the current DexterLab arbiter ownership model.

Updated support for:

- Pending command execution
- Locked command sequences
- Deterministic command completion
- Response routing semantics

---

### Error Reporting

Aligned backend responses with the unified DexterLab error model.

Updated response structure:

```text
rsp_err_valid
rsp_err_code
rsp_err_addr
rsp_err_beat
rsp_err_id
```

---

### Documentation

Complete documentation refresh.

Updated:

```text
Architecture documentation

Backend documentation

Integration documentation

Timing documentation

Error model documentation

Simulation documentation
```

Documentation aligned with:

```text
DexterLab v1.1.0 Core Architecture
```

---

### Naming and Structure

Documentation reorganized to follow the DexterLab 2026 documentation model.

Added references to core documentation instead of duplicating parser architecture and command semantics.

---

## Added

### Architecture Alignment

Support for the standardized execution model:

```text
Parser / Master
        |
        v
     Arbiter
        |
        v
 AXI-FULL Backend
        |
        v
      AXI4 Bus
```

---

### Documentation References

Added integration references to:

```text
Architecture Overview

Design Principles

Versioning and Compatibility

Troubleshooting Guide

Verification Methodology
```

from the main DexterLab documentation suite.

---

## Validation

Validated through:

- GHDL simulation
- Vivado / XSIM simulation
- Burst transfers
- Wrap transfers
- FIFO transactions
- Parser integration tests
- Arbiter integration tests
- Error propagation tests

---

## Compatibility

Compatible with:

```text
DexterLab Parser v1.1.0
```

No command-file migration required.

---

# [1.1.0] - 2026-10-07

## Updated

Updated AXI-FULL backend documentation to match the DexterLab 2026 Documentation Suite.

Updated GHDL simulation documentation:

- Clarified directory structure
- Improved batch simulation instructions
- Extended waveform documentation
- Added debug logging information

Updated Vivado / XSIM documentation:

- Improved environment setup instructions
- Clarified GUI usage
- Added generated-file documentation
- Improved cleanup procedures

Updated backend integration notes.

---

## Added

New documentation pages:

```text
AXI-FULL Backend Overview

Testbench Architecture

Glossary

Documentation Index

Quickstart Guide

Parser Engine Internals

Address Map

Arbiter Specification
```

Added:

```text
VERSION.md
```

Added standardized release packaging structure.

---

## Removed

Removed deprecated wrapper documentation:

```text
cmd_wrapper_ahb_full.md

cmd_wrapper_ahb_lite.md

cmd_wrapper_axi_full.md

cmd_wrapper_axi_lite.md
```

Removed legacy integration notes.

---

## Notes

RTL remained unchanged.

Validated using:

- GHDL
- Vivado / XSIM
- Burst tests
- FIFO tests
- Wrap tests
- Parser integration tests

Compatible with:

```text
DexterLab Parser v1.1.0
```

---

# [1.0.0] - 2026-09-10

## Added

Initial public release of the AXI-FULL backend.

Implemented:

```text
AXI Write Channel

AXI Read Channel

Burst Engine

Wrap Addressing

FIFO Transactions

WSTRB Propagation

Response Handling
```

---

### Parser Integration

Integrated with:

```text
parser_core v1.0.0
```

Direct parser-to-backend connection.

No wrapper layer required.

---

### Testbench Environment

Added:

```text
tb_axi.vhd

AXI Monitor

AXI Slave Model

FIFO Generators

RAM Models
```

---

### Simulation Support

GHDL environment:

- Makefile workflow
- Waveform generation
- Debug logging

Vivado / XSIM environment:

- xvhdl
- xelab
- xsim
- GUI support

---

### Documentation

Initial documentation set:

```text
AXI-FULL Architecture

Command Mapping

Timing Specification

Error Model

Integration Guide

Simulation Guides
```

---

## Validation

Validated through:

- GHDL simulation
- Vivado / XSIM simulation
- Burst testing
- FIFO testing
- Wrap testing
- Parser integration testing

---

## Notes

First standalone release of the AXI-FULL backend.

Backend considered stable for simulation, verification and integration activities.

---

# End of File
