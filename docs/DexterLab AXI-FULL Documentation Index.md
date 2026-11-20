# DexterLab AXI-FULL Documentation Index

(Version 1.2.0)

This document provides a structured overview of the complete documentation available for the DexterLab AXI-FULL backend.

It serves as the primary entry point for:

- Verification engineers
- Hardware integrators
- FPGA developers
- AXI users
- Contributors

The AXI-FULL backend implements the standard DexterLab execution architecture while providing protocol-specific AXI4 transaction handling.

---

# AXI-FULL Architecture Position

The AXI-FULL backend operates within the standard DexterLab architecture:

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

The backend is responsible for translating protocol-independent DexterLab commands into AXI4-compliant bus transactions.

Command semantics remain defined by the core DexterLab architecture.

---

# 1. Core Backend Documentation

## AXI-FULL Architecture

### `DexterLab AXI-FULL Architecture.md`

Describes the internal structure of the AXI-FULL backend.

Topics include:

- Backend organization
- Burst engine
- Address generation
- Read controller
- Write controller
- Response handling
- Execution flow

---

## AXI-FULL Architecture Diagrams

### `DexterLab AXI-FULL Architecture Diagrams.md`

Collection of architecture and data-flow diagrams.

Topics include:

- Backend hierarchy
- AXI channels
- Burst flow
- Read/write state machines
- Response pipeline

---

## AXI-FULL Command Mapping

### `DexterLab AXI-FULL Command Mapping.md`

Describes how DexterLab commands are translated into AXI4 transactions.

Coverage includes:

- READ
- WRITE
- CHECK
- BURST operations
- WRAP operations
- FIFO operations
- WSTRB propagation

---

## AXI-FULL Timing Specification

### `DexterLab AXI-FULL Timing Specification.md`

Defines AXI protocol timing behavior.

Topics include:

- VALID/READY handshakes
- Burst sequencing
- Channel interactions
- Corner cases
- Response timing

---

## AXI-FULL Error Model

### `DexterLab AXI-FULL Error Model.md`

Backend-specific error documentation.

Coverage includes:

- AXI response handling
- SLVERR mapping
- DECERR mapping
- Timeout handling
- Boundary validation
- Command-level error reporting

---

## AXI-FULL Integration Guide

### `DexterLab AXI-FULL Integration Guide.md`

Guidelines for integrating the backend into:

- RAM systems
- Peripherals
- SoCs
- Verification environments
- Multi-source command systems

---

## AXI-FULL Backend Reference

### `DexterLab AXI-FULL Backend.md`

Complete backend reference document.

Describes:

- Interfaces
- Command execution
- AXI translation
- Response generation
- Backend responsibilities

---

# 2. Simulation Documentation

## GHDL Simulation Environment

### `sim_ghdl.md`

Documentation for the GHDL simulation environment.

Topics include:

- Environment setup
- Build flow
- Simulation flow
- Waveform generation
- Debug logging
- Regression testing

---

## Vivado / XSIM Simulation Environment

### `sim_vivado.md`

Documentation for the Vivado simulation environment.

Topics include:

- Environment setup
- Compilation
- Elaboration
- GUI debugging
- Waveform inspection
- Cleanup procedures

---

# 3. Dependency on DexterLab Core Documentation

The AXI-FULL backend inherits its command semantics from the DexterLab core architecture.

Core functionality is documented separately.

Recommended core documents:

```text
Architecture Overview

Design Principles

Command Set

Command Interface

Command Flow

Error Model

Arbiter Specification

Verification Methodology

Troubleshooting Guide
```

The AXI-FULL repository documents only protocol-specific AXI4 behavior.

Parser functionality, command syntax, arbitration rules, and command semantics are inherited from the main DexterLab documentation suite.

---

# 4. Documentation Philosophy

The AXI-FULL documentation follows the same principles as the DexterLab core documentation.

### Modular

Each document focuses on a single subsystem.

---

### Backend-Specific

Documentation describes AXI4 execution details without duplicating parser documentation.

---

### Protocol Accurate

Documentation reflects actual AXI4 behavior and RTL implementation.

---

### Simulation Neutral

Supports:

- GHDL
- Vivado / XSIM

and other compatible verification environments.

---

### Cross-Linked

Documents reference related material to simplify navigation.

---

### Consistent

Terminology follows the DexterLab v1.1.0 architecture and command model.

---

# 5. Recommended Reading Order

New users should follow this order:

```text
DexterLab AXI-FULL Backend

DexterLab AXI-FULL Architecture

DexterLab AXI-FULL Command Mapping

DexterLab AXI-FULL Timing Specification

DexterLab AXI-FULL Error Model

DexterLab AXI-FULL Integration Guide
```

Simulation-specific documentation can then be consulted as needed.

---

# 6. Summary

This documentation suite contains all information required to:

- Understand the AXI-FULL backend
- Integrate the backend
- Simulate the backend
- Debug AXI4 transactions
- Validate command execution
- Extend the backend implementation

The documentation is aligned with:

```text
DexterLab Parser v1.1.0

AXI-FULL Backend v1.2.0
```

and follows the standard DexterLab architecture and documentation model.

---

# End of Document
