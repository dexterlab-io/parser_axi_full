DexterLab AXI‑Full Backend — Release Notes
Version: 1.1.0  
Date: 2026‑10‑07

Overview
Release 1.1.0 updates the AXI‑Full backend to align with the 2026 DexterLab Documentation Suite.
The RTL backend remains stable and unchanged, but the documentation, simulation environments, and release packaging have been significantly improved.

This release introduces new documentation pages, updated simulation guides, and a refreshed structure consistent with the DexterLab Parser v1.1.0 ecosystem.

Key Improvements
Documentation Updates
Updated AXI‑Full backend documentation to match the new DexterLab 2026 structure.

Improved clarity and consistency across all backend documents.

Added new documentation pages:

AXI‑Full Backend Overview

Testbench Architecture

Glossary

Documentation Index

Quickstart Guide

Parser Engine Internals

Address Map

Arbiter Specification

Simulation Environment Updates
GHDL
Updated README with:

clearer directory structure

improved simulation instructions

expanded debug logging section

waveform format details (ghw/vcd/fst)

Vivado/XSIM
Updated README with:

improved environment setup

clearer GUI instructions

detailed list of generated files

updated cleanup section

Release Packaging
Introduced VERSION.md for backend version tracking.

Updated release ZIP structure to match DexterLab 2026 standards.

Removed deprecated wrapper documentation:

cmd_wrapper_ahb_full.md

cmd_wrapper_ahb_lite.md

cmd_wrapper_axi_full.md

cmd_wrapper_axi_lite.md

Stability and Validation
The AXI‑Full backend RTL remains stable and fully validated through:

complete GHDL simulation

complete Vivado/XSIM simulation

multi‑beat burst tests

FIFO and wrap addressing tests

read/write channel stress tests

parser integration tests

No RTL changes were introduced in this release.

Known Limitations (unchanged)
AXI‑Full QoS, region, and user signals are not implemented.

AXI‑Full ID fields support a single master configuration.

Narrow bursts (byte‑lane shifting) are not supported.

Error reporting is limited to parser response codes.

Future Work
AXI‑Lite backend (separate repository).

AHB‑Full and AHB‑Lite backends.

TileLink bridge.

Multi‑master arbitration.

Extended AXI‑Full features (QoS, region, user signals).

Summary
Release 1.1.0 modernizes the AXI‑Full backend documentation and simulation environments, bringing them in line with the DexterLab 2026 architecture and parser ecosystem.
The backend RTL remains stable, validated, and ready for integration, simulation, and further development.

Previous Release
Version: 1.0.0
Date: 2026‑09‑10
(Full details preserved below)

Overview
This release introduces the first standalone version of the DexterLab AXI‑Full backend. It provides a complete hardware backend capable of translating parser commands into AXI‑Full bus transactions, supporting multi‑beat bursts, FIFO operations, wrap addressing, and full AXI channel behavior.

The backend integrates with the DexterLab parser core (parser_core v1.0.0) and includes full simulation support for both GHDL and Vivado/XSIM.

Key Features
AXI‑Full RTL Backend
Multi‑beat burst engine (INCR, FIFO, WRAP).

AXI write channel (AW, W, B) with WLAST generation.

AXI read channel (AR, R) with RLAST generation.

Address generator with wrap boundary enforcement.

Byte‑enable propagation (WSTRB).

Response handling and error propagation.

Parser Integration
Fully compatible with the DexterLab command interface.

Uses parser core version parser_core v1.0.0.

No wrapper required; backend connects directly to the parser output.

Testbench and Simulation
Complete AXI testbench (tb_axi.vhd).

AXI monitor and simple AXI slave model.

FIFO generators and synchronous RAM models.

GHDL simulation environment:

Makefile automation

waveform generation (ghw/vcd/fst)

debug logging support

Vivado/XSIM simulation environment:

xvhdl/xelab/xsim flow

batch and GUI simulation

waveform database (.wdb)

Documentation
AXI‑Full architecture

command mapping

timing and handshake rules

error model

integration guidelines

simulation guides (GHDL and Vivado)

Stability and Validation
Validated through:

full GHDL simulation

full Vivado/XSIM simulation

multi‑beat burst tests

FIFO and wrap addressing tests

read/write channel stress tests

parser integration tests

Backend considered stable for educational, research, and non‑commercial use.

Known Limitations
AXI‑Full QoS, region, and user signals are not implemented.

AXI‑Full ID fields are fixed to a single master configuration.

No support for AXI narrow bursts.

Error reporting limited to parser response codes.

Future Work
AXI‑Lite backend

AHB‑Full and AHB‑Lite backends

TileLink bridge

Multi‑master arbitration

Extended AXI‑Full features

Summary
Version 1.0.0 delivers a complete, stable, and fully documented AXI‑Full backend for the DexterLab parser system.
It is ready for integration, simulation, and further development.
