# AXI-Full Backend Architecture

The AXI-Full backend translates DexterLab parser commands into AXI-Full bus
transactions. It implements a multi-beat burst engine, address generator,
write/read channel controllers, and response handling logic.

This document describes the internal architecture of the backend.

---

## 1. Overview

The AXI-Full backend receives commands from the parser core (`t_cmd_out`) and
executes them on an AXI-Full bus. Supported operations include:

- single transfers
- INCR bursts
- FIFO bursts
- WRAP bursts

The backend is fully synchronous and uses a single clock domain.

---

## 2. Architecture Blocks

### 2.1 Command Expansion Engine

Expands parser commands into AXI-Full transactions:

- determines burst type (single, INCR, FIFO, WRAP)
- computes burst length
- generates beat count
- selects write or read path
- controls sequencing

### 2.2 Address Generator

Generates addresses for each beat:

- INCR: `addr_next = addr + size`
- FIFO: `addr_next = addr`
- WRAP: wrap boundary enforced using AXI rules

Supports:

- 32-bit address space
- configurable data width
- alignment checking

### 2.3 Write Channel Controller (AW/W/B)

Implements:

- AWVALID/AWREADY handshake
- WVALID/WREADY handshake
- WLAST generation
- BVALID/BREADY response handling

Supports:

- byte-enable propagation (WSTRB)
- multi-beat write bursts
- FIFO write mode

### 2.4 Read Channel Controller (AR/R)

Implements:

- ARVALID/ARREADY handshake
- RVALID/RREADY handshake
- RLAST detection
- response propagation to parser

Supports:

- multi-beat read bursts
- FIFO read mode

### 2.5 Response Handler

Maps AXI responses to parser response codes:

- OKAY → success
- SLVERR → backend error
- DECERR → backend error
- alignment errors → parser error
- wrap boundary errors → parser error

---

## 3. Internal FSM

The backend uses a multi-stage FSM:

1. IDLE  
2. ISSUE_AW / ISSUE_AR  
3. WRITE_BEATS / READ_BEATS  
4. WAIT_BRESP / WAIT_RLAST  
5. COMPLETE  

Each stage is fully deterministic and handshake-driven.

---

## 4. Data Path

The data path includes:

- write data multiplexer
- read data capture
- WSTRB generator
- burst counter
- address incrementer

All logic is synchronous and uses registered outputs.

---

## 5. Summary

The AXI-Full backend provides a complete, robust, and fully synchronous
implementation of AXI-Full burst behavior, tightly integrated with the
DexterLab parser core.

