# DexterLab AXI-FULL Quickstart Guide

Version: 1.2.0

This guide provides a rapid introduction to integrating, simulating, and validating the DexterLab AXI-FULL backend.

It is intended for:

- FPGA developers
- Verification engineers
- Hardware integrators
- First-time users of the AXI-FULL backend

For detailed information, refer to the complete documentation suite.

---

# 1. What the Backend Does

The AXI-FULL backend converts protocol-independent DexterLab commands into AXI4-compliant bus transactions.

Supported features include:

```text
Single Transfers

INCR Bursts

FIFO Transactions

WRAP Transactions

WSTRB Propagation

AXI Response Handling

Command Completion Reporting
```

The backend operates within the standard DexterLab architecture:

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

---

# 2. Minimal Integration

## Required Interfaces

Connect the standard DexterLab interfaces:

```text
t_cmd_out
t_rsp_out
t_rsp_in
```

and connect the AXI4 interface:

```text
AW Channel

W Channel

B Channel

AR Channel

R Channel
```

---

## Clock and Reset

Recommended configuration:

```text
Single Clock Domain

Active-High Synchronous Reset
```

Requirements:

- All backend logic uses the same clock
- AXI slave should use the same clock
- Reset must clear all backend state machines

---

# 3. Command Flow

A typical command execution sequence is:

```text
Command Accepted
        |
        v
AXI Transaction Generated
        |
        v
Response Received
        |
        v
Response Published
        |
        v
rsp_end_cmd
```

A command is not considered complete until:

```text
rsp_end_cmd
```

has been generated.

---

# 4. Running GHDL Simulation

Simulation directory:

```text
parser_axi_full/sim/ghdl
```

Typical workflow:

```bash
make all
```

Compile, elaborate, and run the simulation.

```bash
make sim
```

Run the simulation.

```bash
make simwave
```

Run the simulation and automatically open GTKWave.

```bash
make wave
```

Open the generated waveform manually.

---

# 5. Running Vivado / XSIM Simulation

Simulation directory:

```text
parser_axi_full/sim/vivado
```

Initialize the Vivado environment:

```cmd
xsim_env.bat
```

Run the simulation:

```bash
make xsim
```

Open the GUI:

```bash
make xsim_gui
```

This launches the Vivado waveform viewer for protocol-level debugging.

---

# 6. Recommended First Tests

Verify basic functionality before attempting full integration.

Recommended sequence:

```text
READ

WRITE

BURST_READ

BURST_WRITE

FIFO_READ

FIFO_WRITE

WRAP_READ

WRAP_WRITE
```

Then verify:

```text
Error Handling

Timeout Behavior

WSTRB Operations

rsp_end_cmd Generation
```

---

# 7. Debug Logging

Debug messages are controlled through:

```vhdl
ENABLE_DEBUG_LOG
```

defined in:

```text
cmd_cfg.vhd
```

Enable debug logging:

```vhdl
constant ENABLE_DEBUG_LOG : boolean := true;
```

Recommended usage:

```text
true  -> Interactive Debugging

false -> Regression Testing
```

---

# 8. Waveform Signals to Monitor

Recommended signals:

## Command Interface

```text
cmd_valid
cmd_ready
```

---

## Response Interface

```text
rsp_valid

rsp_data

rsp_err_valid

rsp_err_code

rsp_end_cmd
```

---

## AXI Write Channels

```text
AWVALID
AWREADY

WVALID
WREADY

WLAST

BVALID
BREADY
```

---

## AXI Read Channels

```text
ARVALID
ARREADY

RVALID
RREADY

RLAST
```

---

# 9. Recommended Reading Order

After completing the quickstart, continue with:

```text
DexterLab AXI-FULL Backend.md

DexterLab AXI-FULL Architecture.md

DexterLab AXI-FULL Architecture Diagrams.md

DexterLab AXI-FULL Command Mapping.md

DexterLab AXI-FULL Timing Specification.md

DexterLab AXI-FULL Error Model.md

DexterLab AXI-FULL Integration Guide.md
```

---

# 10. Troubleshooting

If simulation does not behave as expected:

Verify:

```text
Clock Configuration

Reset Behavior

AXI Slave Connections

Burst Parameters

WSTRB Generation

Response Routing

rsp_end_cmd Generation
```

Review:

```text
DexterLab AXI-FULL Error Model.md

DexterLab AXI-FULL Timing Specification.md
```

for protocol-specific details.

---

# 11. Summary

This quickstart provides the essential steps needed to:

- Integrate the AXI-FULL backend
- Run simulations
- Debug AXI transactions
- Validate command execution
- Verify response handling

The backend provides a complete AXI4 execution layer for the DexterLab architecture and supports deterministic, protocol-compliant operation across simulation and hardware environments.

---

# End of Document
