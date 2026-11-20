# DexterLab AXI-FULL Backend
## Vivado / XSIM Simulation Environment

Version: 1.2.0

Repository:

```text
parser_axi_full/sim/vivado
```

Status:

```text
Stable
```

---

# Overview

This directory contains the Vivado / XSIM simulation environment used to validate the DexterLab AXI-FULL backend.

The environment provides a complete simulation flow for:

- AXI-FULL backend validation
- Parser integration testing
- Arbiter integration testing
- AXI4 protocol verification
- Burst transaction testing
- Wrap transaction testing
- FIFO transaction testing
- Error propagation verification
- Complete end-to-end command execution

The Vivado environment is primarily intended for:

- AXI protocol debugging
- Handshake verification
- Waveform-level debugging
- Integration validation
- FPGA-oriented development

For architecture and protocol documentation, refer to the AXI-FULL documentation located under:

```text
docs/
```

---

# Architecture Context

The simulation environment validates the standard DexterLab execution architecture:

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

The backend executes protocol-independent DexterLab commands and converts them into AXI4-compliant bus transactions.

---

# Requirements

Supported operating systems:

```text
Windows 10
Windows 11
```

Required tools:

```text
Vivado 2025.1
```

Recommended tools:

```text
MSYS2 / MINGW64
```

for Makefile-based execution.

Required Vivado component:

```text
settings64.bat
```

must be available from the Vivado installation.

---

# Environment Setup

Before running any simulation, the Vivado environment must be initialized.

Execute:

```cmd
xsim_env.bat
```

This script:

- Loads Vivado settings
- Configures environment variables
- Enables command-line tools
- Makes `xvhdl`, `xelab`, and `xsim` available

After successful initialization the Vivado toolchain is ready for execution.

---

# Directory Structure

| File / Directory | Description |
|----------|----------|
| Makefile | Simulation automation |
| xsim_env.bat | Vivado environment initialization |
| tb_axi.vhd | AXI-FULL top-level testbench |
| xsim.dir/ | XSIM working directory |
| tb_axi_sim.wdb | Waveform database |
| xsim.log | Simulation log |
| xelab.log | Elaboration log |
| README.md | This document |

---

# Source Dependencies

The simulation automatically imports:

```text
Parser sources
Arbiter sources
Shared packages
AXI-FULL backend sources
Testbench sources
```

according to the file lists defined by the simulation scripts and Makefile.

---

# Simulation Flow

Vivado simulation consists of three stages:

```text
Compile
    |
Elaborate
    |
Simulate
```

using:

```text
xvhdl
xelab
xsim
```

---

# Running the Simulation

## Full Flow

Compile, elaborate and run:

```bash
make xsim
```

This target performs:

1. RTL compilation
2. Testbench compilation
3. Design elaboration
4. Batch simulation

Internally:

```text
xvhdl
    ↓
xelab
    ↓
xsim
```

---

# Generated Files

After a successful run the following files are generated:

```text
xsim.dir/

tb_axi_sim.wdb

xelab.log

xsim.log
```

These files are required for waveform inspection.

---

# Opening the GUI

To open the Vivado waveform viewer:

```bash
make xsim_gui
```

or manually:

```cmd
xsim tb_axi_sim --gui
```

Requirements:

```text
xsim.dir/
tb_axi_sim.wdb
```

must exist.

---

# Recommended Signals

## Parser Interface

```text
cmd_valid
cmd_ready
cmd_out
```

---

## Arbiter

```text
state_current
state_next

parser_ready
master_ready
```

---

## Backend Responses

```text
rsp_valid
rsp_last

rsp_data

rsp_err_valid
rsp_err_code

rsp_end_cmd
```

---

## AXI Write Address Channel

```text
AWVALID
AWREADY

AWADDR
AWLEN
AWSIZE
AWBURST
```

---

## AXI Write Data Channel

```text
WVALID
WREADY

WDATA
WSTRB

WLAST
```

---

## AXI Write Response Channel

```text
BVALID
BREADY

BRESP
```

---

## AXI Read Address Channel

```text
ARVALID
ARREADY

ARADDR
ARLEN
ARSIZE
ARBURST
```

---

## AXI Read Data Channel

```text
RVALID
RREADY

RDATA
RLAST
RRESP
```

---

# Debug Logging

Debug messages are controlled through:

```vhdl
ENABLE_DEBUG_LOG
```

located in:

```text
cmd_cfg.vhd
```

Recommended settings:

```text
false  -> regression testing

true   -> protocol debugging
```

When disabled:

- Debug messages are suppressed
- Warnings remain active
- Errors remain active
- Fatal conditions remain active

Unlike some simulators, XSIM does not provide selective severity filtering for this use case, therefore control is implemented directly in the RTL.

---

# Validation Scope

The Vivado environment validates:

## Basic Commands

```text
READ
WRITE
CHECK
WSTRB_WRITE
```

---

## Burst Commands

```text
BURST_READ
BURST_WRITE
BURST_CHECK
```

---

## Wrap Commands

```text
WRAP_READ
WRAP_WRITE
WRAP_CHECK
```

---

## FIFO Commands

```text
FIFO_READ
FIFO_WRITE
FIFO_CHECK
```

---

## Protocol Behavior

Including:

```text
AXI Handshakes

VALID / READY Timing

Burst Sequencing

Wrap Addressing

Response Handling

Error Propagation
```

---

# Cleaning the Environment

To remove generated simulation files:

```bash
make clean
```

This removes:

```text
.Xil/

xsim.dir/

*.*og
*.jou
*.pb*
*.wdb
``*

and other generated artifacts.

*--

* Typical Debug*Workflow

Recommended procedure:

*``text
1* DRY_RUN Validation*
2. GHDL Functional*Verification

3. Vivado*Protocol Verification

4. Wave*orm Inspection

5. Regression Exec*tion
```

*se Viv*do whenever fine-grained AXI*protocol visibility is required.

*--

# Related Documentation

## De*terLab Core Documentation

```text
Architecture Overview

Command Interface

Command Flow

Design Principles

Versioning and Compatibility

Troubleshooting Guide

Verification Methodology
```

---

## AXI-FULL Documentation

```text
DexterLab AXI-FULL Documentation Index

DexterLab AXI-FULL Architecture

DexterLab AXI-FULL Architecture Diagrams

DexterLab AXI-FULL Backend

DexterLab AXI-FULL Command Mapping

DexterLab AXI-FULL Timing Specification

DexterLab AXI-FULL Error Model

DexterLab AXI-FULL Integration Guide
```

---

# Summary

The Vivado / XSIM environment provides the primary protocol-level verification platform for the DexterLab AXI-FULL backend.

It enables:

- AXI4 handshake verification
- Burst debugging
- Wrap debugging
- FIFO validation
- Response analysis
- Waveform inspection
- Integration testing

and serves as the reference simulation environment for AXI-FULL protocol verification and development.

---

# End of Document
