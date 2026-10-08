AXI‑Full Backend Overview
DexterLab Documentation Suite — 2026 Edition

The AXI‑Full backend is responsible for translating DexterLab parser commands into AXI‑Full bus transactions.
It implements a complete multi‑beat burst engine, address generator, write/read channel controllers, and a response handling pipeline.

This document provides a high‑level overview of backend behavior, supported features, and design goals.

1. Purpose
The AXI‑Full backend enables the DexterLab command system to interact with AXI‑Full peripherals, RAM blocks, and SoC subsystems.

Supported operations:

single transfers

INCR bursts

FIFO bursts

WRAP bursts

byte‑enable propagation

multi‑beat sequencing

AXI‑compliant handshake behavior

Design goals:

fully synchronous execution

deterministic sequencing

protocol‑accurate AXI behavior

clean integration with parser core and SoC subsystems

2. Supported AXI Features
2.1 Write Channel (AW / W / B)
AWVALID/AWREADY handshake

WVALID/WREADY handshake

WLAST generation

BRESP handling

byte‑enable propagation (WSTRB)

multi‑beat write bursts

FIFO and WRAP burst support

2.2 Read Channel (AR / R)
ARVALID/ARREADY handshake

RVALID/RREADY handshake

RLAST detection

read data forwarding

multi‑beat read bursts

FIFO and WRAP burst support

2.3 Burst Types
INCR: incrementing address

FIFO: constant address

WRAP: wrap boundary enforcement

SINGLE: one‑beat transfer

3. Parser Integration
The backend receives commands from the parser core (t_cmd_out) and returns responses through t_rsp_in.

Supported fields:

address

write data

burst length

burst type

byte‑enable mask

atomic flag

command ID

Version compatibility:

Parser Core Version: parser_core v1.1.0 (2026 release)

Fully backward‑compatible with parser_core v1.0.0

4. Internal Architecture
The backend contains:

Command Expansion Engine  
Expands parser commands into AXI‑Full transactions.

Address Generator  
Computes next address for INCR, FIFO, and WRAP bursts.

Write Channel Controller  
Drives AW/W/B channels and generates WLAST.

Read Channel Controller  
Drives AR/R channels and detects RLAST.

Response Handler  
Maps AXI responses to parser response codes.

Burst Counter  
Tracks beat count for multi‑beat bursts.

WSTRB Generator  
Propagates byte‑enable semantics.

Wrap Boundary Calculator  
Ensures AXI‑compliant wrap behavior.

All logic is synchronous and handshake‑driven.

For diagrams, refer to:

axi_full_architecture_diagrams.md

5. Error Handling
The backend detects:

alignment errors

burst length errors

wrap boundary violations

FIFO mode violations

AXI slave errors (SLVERR, DECERR)

invalid burst types

unsupported sizes

atomic mode violations

Errors are mapped to parser response codes as documented in:

axi_full_errors.md

6. Simulation Support
Two simulation environments are provided:

6.1 GHDL
fast, pure VHDL simulation

Makefile automation

waveform generation (ghw, vcd, fst)

debug logging support

6.2 Vivado XSIM
waveform‑level AXI simulation

xvhdl/xelab/xsim flow

batch and GUI simulation

waveform database (.wdb)

Both environments validate:

burst sequencing

address generation

AXI handshake behavior

parser integration

7. Integration Guidelines
The backend integrates cleanly into AXI‑based SoC designs.

Key requirements:

single synchronous clock domain

AXI‑compliant slave

correct handling of WSTRB

correct support for burst types

proper arbitration for multi‑master systems

atomic mode support in arbiter

For detailed integration rules, refer to:

axi_full_integration.md

8. Cross‑References (NEW)
This document is part of the AXI‑Full backend documentation set:

axi_full_architecture.md

axi_full_architecture_diagrams.md

axi_full_cmd_mapping.md

axi_full_timing.md

axi_full_errors.md

axi_full_integration.md

9. Summary
The AXI‑Full backend provides a complete, robust, and AXI‑compliant execution engine for DexterLab parser commands.
It is suitable for RAM, peripherals, multi‑master systems, and SoC‑level integration, offering deterministic behavior and full protocol compliance.
