DexterLab AXI‑Full Backend — Change Log
This file documents all notable changes introduced in public releases of the
DexterLab AXI‑Full backend. Entries are listed from newest to oldest.

[1.1.0] – 2026‑10‑07
Updated
Updated AXI‑Full backend documentation to match the 2026 DexterLab Documentation Suite.

Updated GHDL simulation README:

clarified directory structure

improved instructions for batch and interactive simulation

added details on debug logging and waveform formats

Updated Vivado/XSIM simulation README:

improved environment setup instructions

clarified GUI requirements

added details on generated files and directory cleanup

Updated integration notes to align with the new parser documentation structure.

Added
New documentation pages under docs/:

AXI‑Full Backend Overview

Testbench Architecture

Glossary

Documentation Index

Quickstart Guide

Parser Engine Internals

Address Map

Arbiter Specification

New VERSION.md file describing backend versioning.

New release packaging structure aligned with DexterLab 2026 standards.

Removed
Legacy wrapper documentation:

cmd_wrapper_ahb_full.md

cmd_wrapper_ahb_lite.md

cmd_wrapper_axi_full.md

cmd_wrapper_axi_lite.md

Deprecated integration notes replaced by updated backend documentation.

Notes
This release aligns the AXI‑Full backend with the updated DexterLab documentation ecosystem.
All simulation environments (GHDL and Vivado/XSIM) have been refreshed and validated.
The backend RTL remains stable and fully compatible with the DexterLab Parser v1.1.0.

[1.0.0] – 2026‑09‑10
Added
Initial public release of the AXI‑Full backend.

Complete AXI‑Full RTL implementation:

Multi‑beat burst engine (INCR, FIFO, WRAP).

AXI write and read channel logic (AW, W, B, AR, R).

Address generation and wrap boundary handling.

Byte‑enable propagation and WSTRB support.

Integration with DexterLab parser core (version: parser_core v1.0.0).

Full AXI testbench (tb_axi.vhd) including:

AXI monitor

simple AXI slave model

FIFO generators

synchronous RAM models

GHDL simulation environment (Makefile, waveform generation, debug logging).

Vivado/XSIM simulation environment (xvhdl/xelab/xsim flow).

Complete documentation under docs/:

AXI‑Full architecture

command mapping

timing and handshake rules

error model

integration guidelines

simulation guides (GHDL and Vivado)

Notes
This is the first standalone release of the AXI‑Full backend.
The backend is stable and fully validated through both GHDL and Vivado simulations.
