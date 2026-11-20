# DexterLab AXI-FULL Architecture

(Version 1.2.0)

This document describes the internal architecture of the DexterLab AXI-FULL backend.

The AXI-FULL backend translates protocol-independent DexterLab commands into AXI4-compliant bus transactions while preserving the command semantics defined by the DexterLab command ecosystem.

The backend implements:

- Single transfers
- INCR bursts
- WRAP bursts
- FIFO transactions
- WSTRB propagation
- AXI response handling
- Command completion reporting

The AXI-FULL backend is designed to operate within the standard DexterLab architecture and serves as the protocol execution layer responsible for AXI4 bus communication.

---

# 1. Architecture Context

The AXI-FULL backend operates within the standard DexterLab command architecture:

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

The backend receives commands through the standardized DexterLab interfaces and converts them into AXI4-compliant transactions.

Command semantics remain defined by the DexterLab architecture.

Protocol execution is implemented entirely inside the backend.

---

# 2. Overview

The AXI-FULL backend receives commands through:

```text
t_cmd_out
```

and generates responses through:

```text
t_rsp_in
```

while using:

```text
t_rsp_out
```

for response flow control.

Supported command classes include:

```text
READ
WRITE
CHECK

BURST_READ
BURST_WRITE
BURST_CHECK

WRAP_READ
WRAP_WRITE
WRAP_CHECK

FIFO_READ
FIFO_WRITE
FIFO_CHECK

WSTRB_WRITE
```

The backend is fully synchronous and operates within a single clock domain.

For diagrams and execution-flow illustrations refer to:

```text
DexterLab AXI-FULL Architecture Diagrams.md
```

---

# 3. Interface Layer

The backend interacts with the DexterLab ecosystem exclusively through the standard command interfaces.

---

## Command Interface

Input commands are received using:

```text
t_cmd_out
```

including:

```text
Address

Length

Write/Read information

Burst attributes

Wrap attributes

FIFO attributes

Lock information

Protocol attributes
```

---

## Response Control Interface

Response acceptance is controlled through:

```text
t_rsp_out
```

including:

```text
rsp_ready

rsp_err_ready
```

---

## Response Interface

Execution results are generated through:

```text
t_rsp_in
```

including:

```text
rsp_valid
rsp_last

rsp_data

rsp_err_valid
rsp_err_code

rsp_err_addr
rsp_err_beat
rsp_err_id

rsp_end_cmd
```

---

## Command Acceptance

Command acceptance uses:

```text
cmd_valid
cmd_ready
```

A command is considered accepted when:

```text
cmd_valid = '1'
AND
cmd_ready = '1'
```

---

## Command Completion

Command completion is indicated through:

```text
rsp_end_cmd
```

This mechanism is shared across all DexterLab backends.

---

# 4. Architecture Blocks

The AXI-FULL backend is organized into a set of modular execution blocks.

---

## 4.1 Command Execution Engine

The Command Execution Engine converts protocol-independent DexterLab commands into AXI4-compliant transactions.

Responsibilities:

- Determine execution mode
- Decode command attributes
- Configure burst parameters
- Select read/write path
- Initialize execution context
- Control transaction sequencing

Supported execution types:

```text
Single Transfer

INCR Burst

FIFO Transfer

WRAP Burst
```

Outputs:

```text
Burst Configuration

Initial Address

Beat Counter

Execution Mode

Read/Write Selection
```

---

## 4.2 Address Generator

The Address Generator generates the AXI address associated with each transfer beat.

Supported modes:

---

### INCR Mode

Address increments every beat.

Example:

```text
addr_next = addr + size
```

---

### FIFO Mode

Address remains constant.

Example:

```text
addr_next = addr
```

---

### WRAP Mode

Address wraps inside a configured boundary.

Example:

```text
addr_next = wrapped_address
```

The parser validates wrap legality.

The backend generates actual AXI wrap addresses.

---

### Features

The Address Generator provides:

- Address sequencing
- Alignment checking
- Wrap boundary generation
- Beat counter integration
- AXI burst address generation

---

## 4.3 Write Channel Controller

The Write Channel Controller implements the AXI write path.

Managed channels:

```text
AW

W

B
```

Responsibilities:

```text
AWVALID / AWREADY

WVALID / WREADY

WLAST generation

BVALID / BREADY

BRESP decoding
```

Supported features:

- Multi-beat writes
- FIFO writes
- Wrap writes
- WSTRB propagation
- Error handling

Internal blocks:

```text
AW Sequencer

W Data Multiplexer

WSTRB Generator

B Response Decoder
```

---

## 4.4 Read Channel Controller

The Read Channel Controller implements the AXI read path.

Managed channels:

```text
AR

R
```

Responsibilities:

```text
ARVALID / ARREADY

RVALID / RREADY

RLAST detection

Response formatting
```

Supported features:

- Single reads
- Burst reads
- FIFO reads
- Wrap reads
- Error handling

Internal blocks:

```text
AR Sequencer

R Data Capture

RLAST Detector

Response Formatter
```

---

## 4.5 Response Handler

The Response Handler converts protocol responses into DexterLab responses.

Responsibilities:

- AXI response decoding
- Error translation
- Response formatting
- ID propagation
- Command completion generation
- Final response publication

---

### AXI Response Mapping

| AXI Response | DexterLab Result |
|--------------|------------------|
| OKAY | Success |
| SLVERR | Error |
| DECERR | Error |

---

### Generated Information

The Response Handler may generate:

```text
rsp_valid

rsp_data

rsp_err_valid
rsp_err_code

rsp_err_addr
rsp_err_beat
rsp_err_id

rsp_end_cmd
```

---

# 5. Internal FSM

The backend operates using a deterministic multi-stage FSM.

---

## IDLE

Waiting for a valid command.

Command acceptance occurs through:

```text
cmd_valid
cmd_ready
```

---

## ISSUE_AW

Write address phase.

The backend issues:

```text
AWVALID
```

and waits for:

```text
AWREADY
```

---

## ISSUE_AR

Read address phase.

The backend issues:

```text
ARVALID
```

and waits for:

```text
ARREADY
```

---

## WRITE_BEATS

Write data phase.

Operations:

```text
WVALID

WDATA

WSTRB

WLAST
```

are generated.

---

## READ_BEATS

Read data phase.

Operations:

```text
RVALID

RDATA

RLAST
```

are processed.

---

## WAIT_BRESP

Waiting for AXI write response.

Expected:

```text
BVALID
```

---

## WAIT_RLAST

Waiting for final AXI read beat.

Completion occurs when:

```text
RLAST = '1'
```

---

## COMPLETE

Transaction execution complete.

The backend:

- Generates final response information
- Generates `rsp_end_cmd`
- Releases command ownership
- Returns to IDLE

FSM transitions are fully synchronous and handshake driven.

---

# 6. Data Path

The AXI-FULL backend data path contains:

```text
Write Data Multiplexer

Read Data Capture Registers

WSTRB Generator

Burst Counter

Address Incrementer

Wrap Address Generator

Response Formatter
```

All externally visible outputs are registered to ensure:

- Timing stability
- AXI protocol compliance
- Deterministic operation

---

# 7. Error Handling

The backend performs protocol-level error detection.

Examples include:

```text
AXI Slave Errors

Decode Errors

Protocol Errors

Boundary Violations

Burst Violations

Timeout Conditions
```

Error information is reported through:

```text
rsp_err_valid
rsp_err_code

rsp_err_addr
rsp_err_beat
rsp_err_id
```

Detailed definitions are documented in:

```text
DexterLab AXI-FULL Error Model.md
```

---

# 8. Locked Command Support

The backend supports protected command sequences through:

```text
cmd_lock
```

generated by the DexterLab command architecture.

When ownership is retained by the arbiter:

```text
Backend execution continues normally.

Ownership switching is prevented externally by the arbiter.
```

The backend itself remains ownership-agnostic.

---

# 9. Cross References

This document is part of the AXI-FULL backend documentation suite.

Related documents:

```text
DexterLab AXI-FULL Architecture Diagrams.md

DexterLab AXI-FULL Command Mapping.md

DexterLab AXI-FULL Timing Specification.md

DexterLab AXI-FULL Error Model.md

DexterLab AXI-FULL Integration Guide.md

DexterLab AXI-FULL Backend.md
```

Core DexterLab references:

```text
Architecture Overview

Command Interface

Command Flow

Arbiter Specification

Design Principles
```

---

# 10. Summary

The AXI-FULL backend is the AXI4 protocol execution layer of the DexterLab ecosystem.

It converts protocol-independent commands into AXI4-compliant transactions while preserving the standardized DexterLab command model.

The architecture is composed of:

```text
Command Execution Engine

Address Generator

Write Channel Controller

Read Channel Controller

Response Handler
```

and provides:

- Deterministic execution
- Multi-beat burst support
- Wrap addressing support
- FIFO transaction support
- AXI protocol compliance
- Unified response generation
- Standardized command completion through `rsp_end_cmd`

making it suitable for verification, simulation, integration, and future system expansion.

---

# End of Document
