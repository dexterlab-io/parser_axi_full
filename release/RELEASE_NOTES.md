# DexterLab AXI-FULL Backend — Release Notes

Version: 1.2.0

Release Date: 2026-11-16

Status: Stable

---

# Overview

Release 1.2.0 aligns the AXI-FULL backend with the DexterLab v1.1.0 core architecture and command ecosystem.

This release introduces updated interfaces, command execution semantics, response handling, arbitration integration, and a complete documentation refresh.

The AXI-FULL backend remains protocol-compatible with previous versions while adopting the new DexterLab architecture:

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

This release supersedes version 1.1.0.

---

# Major Changes

## Architecture Alignment

The backend has been aligned with the current DexterLab command architecture.

Standard execution flow:

```text
Parser
   |
Arbiter
   |
AXI-FULL Backend
   |
AXI Bus
```

All command execution now follows the unified DexterLab command lifecycle.

---

## Interface Update

The AXI-FULL backend now uses the standardized interfaces defined by the DexterLab core architecture:

```text
t_cmd_out
t_rsp_out
t_rsp_in
```

The interface model has been updated to match the current parser and arbiter implementation.

---

## Locked Command Support

Support for:

```text
cmd_lock
```

has been aligned with the current arbiter ownership model.

Protected command sequences generated through:

```text
SET_ATOMIC
```

are now managed through the standardized DexterLab ownership-retention mechanism.

---

## Command Completion Model

The backend now implements the unified command completion mechanism based on:

```text
rsp_end_cmd
```

This provides deterministic command completion behavior consistent with:

- Generic Backend
- AXI-LITE Backend
- AHB-FULL Backend
- AHB-LITE Backend

---

## Error Model Alignment

Error reporting has been aligned with the unified DexterLab error architecture.

Supported categories include:

```text
OKAY
SLVERR
DECERR
TIMEOUT
PROT_ERR
BOUNDARY_ERR
BURST_ERR
ID_ERR
WSTRB_ERR
```

Error reporting now uses the current response structure:

```text
rsp_err_valid
rsp_err_code
rsp_err_addr
rsp_err_beat
rsp_err_id
```

---

# Documentation Updates

The AXI-FULL documentation suite has been fully refreshed and aligned with the DexterLab 2026 documentation model.

Updated documentation includes:

```text
AXI-FULL Architecture

AXI-FULL Architecture Diagrams

AXI-FULL Command Mapping

AXI-FULL Timing Specification

AXI-FULL Error Model

AXI-FULL Integration Guide

AXI-FULL Backend

Documentation Index

Quickstart Guide
```

Documentation now references the DexterLab core documentation where appropriate instead of duplicating architecture definitions.

---

# Simulation Environment Updates

## GHDL

Updated documentation includes:

- Improved directory structure documentation
- Updated execution flow
- Improved waveform guidance
- Unified debugging recommendations

Supported waveform formats:

```text
ghw
vcd
fst
```

---

## Vivado / XSIM

Updated documentation includes:

- Improved setup procedures
- Updated project structure
- Improved waveform documentation
- Revised cleanup procedures
- Updated simulation workflow descriptions

---

# Validation Status

The backend has been validated using:

- GHDL simulation
- Vivado / XSIM simulation
- Multi-beat burst transfers
- Wrap burst operations
- FIFO operations
- Read channel stress testing
- Write channel stress testing
- Parser integration testing
- Arbiter integration testing

---

# Compatibility

Compatible with:

```text
DexterLab Parser v1.1.0
```

Recommended with:

```text
DexterLab Core Architecture v1.1.0
```

Backward compatibility with existing command files has been preserved.

No command language migration is required.

---

# Known Limitations

The following limitations remain unchanged.

### AXI User Signals

The following optional AXI signals are not currently implemented:

```text
AWUSER
WUSER
BUSER

ARUSER
RUSER
```

---

### AXI QoS Support

The following optional AXI features are not currently implemented:

```text
AWQOS
ARQOS
```

---

### AXI Region Support

The following optional AXI features are not currently implemented:

```text
AWREGION
ARREGION
```

---

### Multi-Master AXI IDs

Current implementation targets a single-master command model.

Advanced AXI interconnect scenarios are not currently supported.

---

### Narrow Bursts

AXI narrow burst support is not implemented.

---

# Future Work

Planned future areas include:

- Extended AXI attribute support
- Enhanced AXI ID management
- Multi-master AXI operation
- Additional protocol bridges
- Performance optimizations
- Extended monitoring and diagnostics

---

# Summary

Version 1.2.0 modernizes the AXI-FULL backend and aligns it with the DexterLab v1.1.0 architecture.

Key improvements include:

- Updated parser integration
- Unified interface model
- Standardized command completion
- Unified error reporting
- Locked command support
- Complete documentation refresh
- Updated simulation workflows

The AXI-FULL backend remains stable, validated, and fully ready for integration, simulation, verification, and future expansion.

---

# Previous Release

Version: 1.1.0

Release Date: 2026-10-07

Status: Stable

See previous release notes for historical details.

---

# End of Document
