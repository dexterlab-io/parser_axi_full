# AXI-Full Backend Overview

The AXI-Full backend is responsible for translating DexterLab parser commands
into AXI-Full bus transactions. It implements a complete multi-beat burst engine,
address generator, write/read channel controllers, and response handling logic.

This document provides a high-level overview of the backend behavior, supported
features, and design goals.

---

## 1. Purpose

The AXI-Full backend enables the DexterLab command system to interact with
AXI-Full peripherals, RAM blocks, and SoC subsystems. It supports:

- single transfers
- INCR bursts
- FIFO bursts
- WRAP bursts
- byte-enable propagation
- multi-beat sequencing
- AXI-compliant handshake behavior

The backend is fully synchronous and designed for deterministic execution.

---

## 2. Supported AXI Features

### Write Channel (AW/W/B)
- AWVALID/AWREADY handshake
- WVALID/WREADY handshake
- WLAST generation
- BRESP handling
- byte-enable propagation (WSTRB)
- multi-beat write bursts

### Read Channel (AR/R)
- ARVALID/ARREADY handshake
- RVALID/RREADY handshake
- RLAST detection
- read data forwarding
- multi-beat read bursts

### Burst Types
- **INCR**: incrementing address
- **FIFO**: constant address
- **WRAP**: wrap boundary enforcement
- **SINGLE**: one-beat transfer

---

## 3. Parser Integration

The backend receives commands from the parser core (`t_cmd_out`) and returns
responses through `t_rsp_in`.

Supported fields include:

- address
- data (for writes)
- burst length
- burst type
- byte-enable mask
- atomic flag

The backend is compatible with:

**Parser Core Version: `parser_core v1.0.0`**

---

## 4. Internal Architecture

The backend contains:

- command expansion engine
- address generator
- write channel controller
- read channel controller
- response handler
- burst counter
- WSTRB generator
- wrap boundary calculator

All logic is synchronous and handshake-driven.

---

## 5. Error Handling

The backend detects:

- alignment errors
- burst length errors
- wrap boundary violations
- FIFO mode violations
- AXI slave errors (SLVERR, DECERR)

Errors are mapped to parser response codes.

---

## 6. Simulation Support

Two simulation environments are provided:

- **GHDL** (fast, pure VHDL)
- **Vivado XSIM** (waveform-level AXI simulation)

Both environments validate:

- burst sequencing
- address generation
- AXI handshake behavior
- parser integration

---

## 7. Summary

The AXI-Full backend provides a complete, robust, and AXI-compliant execution
engine for DexterLab parser commands. It is suitable for RAM, peripherals,
multi-master systems, and SoC-level integration.

