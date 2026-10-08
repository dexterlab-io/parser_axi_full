AXI‑Full Backend Architecture
DexterLab Documentation Suite — 2026 Edition

The AXI‑Full backend translates DexterLab parser commands into AXI‑Full bus transactions.
It implements a multi‑beat burst engine, an address generator, write/read channel controllers, and a response handling pipeline.

This document describes the internal architecture of the backend and how each block contributes to AXI‑Full protocol execution.

1. Overview
The AXI‑Full backend receives commands from the parser core (t_cmd_out) and executes them on an AXI‑Full bus.
Supported operations include:

single transfers

INCR bursts

FIFO bursts

WRAP bursts

The backend is fully synchronous and operates in a single clock domain.

For diagrams, refer to:

axi_full_architecture_diagrams.md

2. Architecture Blocks
2.1 Command Expansion Engine
The Command Expansion Engine converts parser commands into AXI‑Full transactions.

Responsibilities:

determines burst type (single, INCR, FIFO, WRAP)

computes burst length and beat count

selects write or read path

expands parser semantics into AXI‑compliant sequences

controls transaction sequencing

Outputs:

burst configuration

initial address

beat counter

write/read mode selection

2.2 Address Generator
Generates the address for each beat of the burst.

Supported modes:

INCR:

Codice
addr_next = addr + size
FIFO:

Codice
addr_next = addr
WRAP:  
AXI wrap boundary enforced using:

Codice
addr_next = (addr & wrap_mask) | offset
Features:

32‑bit address space

configurable data width

alignment checking

wrap boundary calculator

beat counter integration

2.3 Write Channel Controller (AW / W / B)
Implements the AXI write channel:

AWVALID/AWREADY handshake

WVALID/WREADY handshake

WLAST generation

BVALID/BREADY response handling

Supports:

byte‑enable propagation (WSTRB)

multi‑beat write bursts

FIFO write mode

error propagation through BRESP

Internal components:

AW sequencer

W data multiplexer

WSTRB generator

B response decoder

2.4 Read Channel Controller (AR / R)
Implements the AXI read channel:

ARVALID/ARREADY handshake

RVALID/RREADY handshake

RLAST detection

response propagation to parser

Supports:

multi‑beat read bursts

FIFO read mode

error propagation through RRESP

Internal components:

AR sequencer

R data capture

RLAST detector

response formatter

2.5 Response Handler
Maps AXI responses to parser response codes.

Mapping:

OKAY → success

SLVERR → backend error

DECERR → backend error

alignment errors → parser error

wrap boundary violations → parser error

Responsibilities:

AXI → parser error translation

response formatting

ID propagation

final response delivery to parser core

3. Internal FSM
The backend uses a deterministic multi‑stage FSM:

IDLE  
Waiting for a valid parser command.

ISSUE_AW / ISSUE_AR  
Address phase for write/read.

WRITE_BEATS / READ_BEATS  
Data phase for write/read.

WAIT_BRESP / WAIT_RLAST  
Response phase.

COMPLETE  
Transaction finished; response sent to parser.

FSM transitions are handshake‑driven and fully synchronous.

4. Data Path
The data path includes:

write data multiplexer

read data capture registers

WSTRB generator

burst counter

address incrementer

wrap boundary calculator

All logic uses registered outputs to ensure timing stability and AXI protocol compliance.

5. Cross‑References (NEW)
This document is part of the AXI‑Full backend documentation set:

axi_full_architecture_diagrams.md — structural diagrams

axi_full_cmd_mapping.md — parser → AXI command mapping

axi_full_timing.md — handshake and timing rules

axi_full_errors.md — error model

axi_full_integration.md — integration guidelines

backend_axi_full.md — backend overview

6. Summary
The AXI‑Full backend provides a complete, robust, and fully synchronous implementation of AXI‑Full burst behavior, tightly integrated with the DexterLab parser core.
Its architecture is composed of modular, deterministic blocks designed for clarity, correctness, and simulation‑friendly behavior.
