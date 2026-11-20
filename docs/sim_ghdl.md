# DexterLab AXI-FULL Backend
## GHDL Simulation Environment

Version: 1.2.0

Repository:

```text
parser_axi_full/sim/ghdl
```

Status:

```text
Stable
```

---

# Overview

This directory contains the GHDL simulation environment used to validate the DexterLab AXI-FULL backend.

The environment provides a complete simulation flow for:

- AXI-FULL backend validation
- Parser integration testing
- Arbiter integration testing
- Burst transaction verification
- Wrap transaction verification
- FIFO operation verification
- AXI protocol validation
- Error propagation testing

The simulation environment is intended for development, debugging, regression testing, and continuous integration.

For protocol-specific implementation details, refer to the AXI-FULL documentation provided under:

```text
docs/
```

---

# Architecture Context

The simulation environment exercises the standard DexterLab execution architecture:

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

The testbench validates the AXI4 protocol implementation while preserving the protocol-independent command semantics defined by the DexterLab architecture.

---

# Directory Structure

| File / Directory | Description |
|----------|----------|
| Makefile | Build, elaborate, simulation and waveform automation |
| tb_axi.vhd | AXI-FULL top-level testbench |
| workdir/ | GHDL working directory |
| wave.ghw | GHW waveform output |
| wave.vcd | VCD waveform output |
| wave.fst | FST waveform output |
| README.md | This document |

---

# Source Dependencies

The simulation environment automatically imports:

```text
Parser sources
Arbiter sources
Shared packages
AXI-FULL backend sources
Testbench sources
```

from the repository structure.

The exact file list is defined inside the Makefile.

---

# Requirements

Recommended tools:

```text
GHDL (LLVM backend)

GTKWave
```

Supported environments:

```text
Linux

MSYS2 / MINGW64

WSL
```

Recommended language standard:

```text
VHDL-2008
```

Older standards may work depending on the local environment and source configuration.

---

# Makefile Overview

The Makefile provides automation for:

- RTL compilation
- Testbench compilation
- Elaboration
- Simulation
- Waveform generation
- Waveform viewing
- Cleanup

Supported waveform formats:

```text
GHW
VCD
FST
```

Default top-level entity:

```text
tb_axi
```

Default waveform format:

```text
ghw
```

---

# Build Flow

## Full Flow

Compile, elaborate and run:

```bash
make all
```

This target performs:

1. Cleanup
2. RTL compilation
3. Testbench compilation
4. Elaboration
5. Simulation

---

## Compile Only

```bash
make compile
```

Compiles sources without running simulation.

---

## Elaborate

```bash
make elaborate
```

Builds the simulation executable.

---

## Simulation

```bash
make sim
```

Typical execution:

```bash
ghdl -r tb_axi --wave=wave.ghw --stop-time=200us
```

Simulation stop time may be configured inside the Makefile.

---

# Interactive Debug Session

For graphical debugging:

```bash
make simwave
```

This target:

- Removes existing waveform files
- Runs simulation
- Generates waveform output
- Launches GTKWave automatically

Recommended during backend development and protocol debugging.

---

# Waveform Viewing

## Automatic

```bash
make wave
```

---

## Manual

```bash
gtkwave wave.ghw &
```

or:

```bash
gtkwave wave.fst &
```

depending on the selected waveform format.

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

## AXI-FULL Backend

```text
rsp_valid
rsp_last
rsp_data

rsp_err_valid
rsp_err_code

rsp_end_cmd
```

---

## AXI Write Channel

```text
awvalid
awready
awaddr
awlen

wvalid
wready
wdata
wlast

bvalid
bready
bresp
```

---

## AXI Read Channel

```text
arvalid
arready
araddr
arlen

rvalid
rready
rdata
rlast
rresp
```

---

# Debug Logging

Debug messages are controlled through:

```vhdl
ENABLE_DEBUG_LOG
```

defined in:

```text
cmd_cfg.vhd
```

Recommended settings:

```text
false  -> regression testing

true   -> interactive debugging
```

When disabled:

- Debug messages are suppressed
- Warnings remain enabled
- Errors remain enabled
- Fatal conditions remain enabled

---

# Validation Scope

The simulation environment is intended to validate:

## Command Layer

```text
READ
WRITE
CHECK
WSTRB_WRITE
```

---

## Burst Operations

```text
BURST_READ
BURST_WRITE
BURST_CHECK
```

---

## Wrap Operations

```text
WRAP_READ
WRAP_WRITE
WRAP_CHECK
```

---

## FIFO Operations

```text
FIFO_READ
FIFO_WRITE
FIFO_CHECK
```

---

## Error Propagation

Including:

```text
SLVERR
DECERR
TIMEOUT
BOUNDARY_ERR
BURST_ERR
```

and backend-specific conditions.

---

# Cleaning

Remove generated files:

```bash
make clean
```

This target removes:

```text
workdir/*.o
*orkdir/*.cf

wave.ghw
wave.vcd
wave.fst

temporary build artifacts
```

---

# Continuous Integration Usage

Recommended CI flow:

```text
Compile
    ↓
DRY_RUN
    ↓
Simulation
    ↓
Regression Tests
```

GHDL is the preferred simulation environment for:

- Automated testing
- Regression execution
- Command validation
- Backend verification

because of its fast compile-and-run cycle.

---

# Related Documentation

## DexterLab Core Documentation

```text
Architecture Overview

Design Principles

Command Interface

Command Flow

Error Model

Verification Methodology

Troubleshooting Guide
```

---

## AXI-FULL Documentation

```text
DexterLab AXI-FULL Documentation Index

DexterLab AXI-FULL Architecture

DexterLab AXI-FULL Backend

DexterLab AXI-FULL Timing Specification

DexterLab AXI-FULL Error Model

DexterLab AXI-FULL Integration Guide
```

---

# Summary

This simulation environment provides a complete validation platform for the DexterLab AXI-FULL backend.

It supports:

- Protocol verification
- Parser integration
- Arbiter integration
- Regression testing
- Waveform debugging
- Continuous integration

and serves as the primary open-source verification environment for the AXI-FULL backend.

---

# End of Document
