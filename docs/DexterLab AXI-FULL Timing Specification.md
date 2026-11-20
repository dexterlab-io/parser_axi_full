# DexterLab AXI-FULL Error Model

(Version 1.2.0)

This document defines the error model implemented by the DexterLab AXI-FULL backend.

The AXI-FULL backend translates protocol-specific AXI4 failures and internal execution failures into the standardized DexterLab response model.

Error information is reported through:

```text
t_rsp_in
```

using:

```text
rsp_err_valid
rsp_err_code

rsp_err_addr
rsp_err_beat
rsp_err_id

rsp_end_cmd
```

The goal of the error model is to provide deterministic, traceable, and protocol-independent error reporting.

---

# 1. Architecture Context

The AXI-FULL backend operates within the standard DexterLab architecture:

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

Error detection may originate from:

```text
Parser Validation

Backend Validation

Backend Execution

AXI Slave Responses
```

All runtime errors are ultimately reported through the standardized DexterLab response interface.

---

# 2. Error Reporting Interface

Errors are reported using:

```text
rsp_err_valid
```

to indicate an error response.

Additional error information may include:

```text
rsp_err_code
rsp_err_addr
rsp_err_beat
rsp_err_id
```

---

## rsp_err_code

Identifies the error category.

Example:

```text
SLVERR
DECERR
TIMEOUT
BOUNDARY_ERR
BURST_ERR
PROT_ERR
```

---

## rsp_err_addr

Address associated with the reported failure.

Example:

```text
0x1000
```

---

## rsp_err_beat

Beat number associated with the failure.

Example:

```text
Beat 0

Beat 3

Beat 15
```

---

## rsp_err_id

Associated command identifier.

Used for command-response correlation.

---

# 3. Error Categories

The AXI-FULL backend follows the standardized DexterLab error architecture.

Common categories include:

```text
OKAY

SLVERR

DECERR

TIMEOUT

BOUNDARY_ERR

BURST_ERR

PROT_ERR

ID_ERR

WSTRB_ERR
```

Detailed system-level definitions are provided in:

```text
cmd_errors.md
```

This document focuses on AXI-FULL backend behavior.

---

# 4. Alignment Errors

Alignment errors occur when a transaction violates AXI alignment rules.

Examples:

```text
Misaligned transfer address

Misaligned wrap boundary

Size/address mismatch
```

Detection point:

```text
Backend Validation
```

Reported as:

```text
PROT_ERR
```

Additional information:

```text
rsp_err_addr
```

may contain the offending address.

---

# 5. Burst Errors

Burst errors occur when burst configuration violates backend constraints.

Examples:

```text
Zero-length bursts

Illegal burst configuration

Unsupported burst attributes

Invalid wrap configuration
```

Detection point:

```text
Command Execution Engine
```

Reported as:

```text
BURST_ERR
```

---

# 6. Boundary Errors

Boundary errors occur when a transaction violates address-boundary rules.

Examples:

```text
4KB boundary crossing

Illegal wrap boundary

Address range violation
```

Detection point:

```text
Address Generator
```

Reported as:

```text
BOUNDARY_ERR
```

Error information may include:

```text
rsp_err_addr
```

and:

```text
rsp_err_beat
```

---

# 7. FIFO Errors

FIFO-oriented commands may generate backend-specific errors.

Examples:

```text
Illegal FIFO parameters

Invalid FIFO configuration

Unsupported FIFO access pattern
```

Reported as:

```text
BURST_ERR

or

PROT_ERR
```

depending on the detected condition.

---

# 8. WSTRB Errors

Partial write operations may generate write-mask errors.

Examples:

```text
Invalid mask configuration

Unsupported byte enables

Illegal write-mask usage
```

Detection point:

```text
Write Controller
```

Reported as:

```text
WSTRB_ERR
```

---

# 9. Timeout Errors

Timeout errors occur when AXI transactions fail to complete within the configured limit.

Possible causes:

```text
Missing BRESP

Missing RLAST

Slave never responding

Permanent backpressure
```

Detection point:

```text
Transaction Execution
```

Reported as:

```text
TIMEOUT
```

Error information may include:

```text
rsp_err_addr

rsp_err_beat
```

---

# 10. AXI Slave Errors

AXI slaves may return protocol-defined error responses.

The AXI-FULL backend does not modify AXI semantics.

Instead, it translates AXI responses into the DexterLab error model.

---

## SLVERR

AXI response:

```text
SLVERR
```

Meaning:

```text
Slave-reported execution failure
```

Reported as:

```text
SLVERR
```

Typical causes:

```text
Peripheral failure

Illegal access

Device-specific error
```

---

## DECERR

AXI response:

```text
DECERR
```

Meaning:

```text
Decode failure
```

Reported as:

```text
DECERR
```

Typical causes:

```text
Unmapped address

Address decode failure

Missing peripheral
```

---

# 11. Protocol Errors

Protocol errors are generated internally when AXI protocol expectations are violated.

Examples:

```text
Unexpected response sequence

Illegal handshake sequence

Invalid channel behavior
```

Detection point:

```text
Protocol Monitoring Logic
```

Reported as:

```text
PROT_ERR
```

---

# 12. ID Errors

ID-related errors occur when command-response correlation cannot be maintained.

Examples:

```text
Invalid command identifier

Unexpected response identifier

Internal ID mismatch
```

Reported as:

```text
ID_ERR
```

---

# 13. Error Response Generation

Error generation follows a deterministic sequence.

```text
Error Detection
        |
        v
Error Classification
        |
        v
Response Formatting
        |
        v
Error Publication
```

Published information may include:

```text
rsp_err_valid

rsp_err_code

rsp_err_addr

rsp_err_beat

rsp_err_id
```

---

# 14. Error Completion Model

Errors do not bypass the standard DexterLab completion mechanism.

Error flow:

```text
Error Detected
        |
        v
Error Report Generated
        |
        v
rsp_err_valid
        |
        v
rsp_end_cmd
```

The command is not considered complete until:

```text
rsp_end_cmd
```

has been generated.

---

# 15. Error Priority

When multiple failures are detected simultaneously, the backend resolves them in the following order:

```text
PROT_ERR

BOUNDARY_ERR

BURST_ERR

WSTRB_ERR

TIMEOUT

SLVERR

DECERR
```

This ordering guarantees deterministic reporting.

Only the highest-priority error is reported for a given failure event.

---

# 16. Error Source Classification

Errors may originate from different parts of the system.

---

## Parser Validation

Examples:

```text
Illegal syntax

Illegal command semantics

Invalid wrap requests
```

These are typically detected before backend execution.

---

## Arbiter

Examples:

```text
Ownership violations

Routing errors
```

These are outside AXI-FULL backend responsibility.

---

## Backend

Examples:

```text
Boundary errors

Burst errors

Timeouts

Protocol errors
```

Generated directly by the backend.

---

## AXI Slave

Examples:

```text
SLVERR

DECERR
```

Generated externally and propagated by the backend.

---

# 17. Cross References

This document is part of the AXI-FULL backend documentation suite.

Related documents:

```text
DexterLab AXI-FULL Architecture.md

DexterLab AXI-FULL Architecture Diagrams.md

DexterLab AXI-FULL Command Mapping.md

DexterLab AXI-FULL Timing Specification.md

DexterLab AXI-FULL Integration Guide.md

DexterLab AXI-FULL Backend.md
```

Core DexterLab references:

```text
Command Interface

Command Flow

cmd_errors.md

Troubleshooting Guide
```

---

# 18. Summary

The AXI-FULL backend provides deterministic and protocol-aware error reporting for:

```text
AXI Slave Responses

Alignment Violations

Boundary Violations

Burst Failures

Timeout Conditions

Protocol Violations

Write-Mask Errors
```

All error reporting is performed through the standardized DexterLab response model:

```text
rsp_err_valid
rsp_err_code

rsp_err_addr
rsp_err_beat
rsp_err_id

rsp_end_cmd
```

ensuring consistent behavior across the entire DexterLab ecosystem.

---

# End of Document
