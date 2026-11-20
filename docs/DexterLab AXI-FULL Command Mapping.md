# DexterLab AXI-FULL Command Mapping

Version: 1.2.0

This document describes how protocol-independent DexterLab commands are translated into AXI4-compliant transactions by the AXI-FULL backend.

The AXI-FULL backend receives commands through the standard DexterLab command interface:

```text
t_cmd_out
```

and converts them into AXI4 channel transactions:

```text
AW
W
B

AR
R
```

The mapping is deterministic and preserves the command semantics defined by the DexterLab architecture.

---

# 1. Architecture Context

The AXI-FULL backend operates within the standard DexterLab execution architecture:

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

The backend is responsible for protocol execution.

Command semantics remain defined by the DexterLab command layer.

---

# 2. Command Interface

The AXI-FULL backend receives commands through:

```text
t_cmd_out
```

Important fields include:

```text
cmd_write
cmd_burst
cmd_wrap
cmd_fifo

cmd_addr
cmd_len

cmd_data
cmd_wstrb

cmd_id

cmd_size
cmd_prot
cmd_cache
cmd_qos

cmd_lock
```

These attributes are translated into AXI4 protocol signals.

---

# 3. Supported Command Classes

The AXI-FULL backend supports:

## Single Operations

```text
READ
WRITE
CHECK
WSTRB_WRITE
```

## Burst Operations

```text
BURST_READ
BURST_WRITE
BURST_CHECK
```

## Wrap Operations

```text
WRAP_READ
WRAP_WRITE
WRAP_CHECK
```

## FIFO Operations

```text
FIFO_READ
FIFO_WRITE
FIFO_CHECK
```

---

# 4. Write Command Mapping

The AXI-FULL backend executes write commands through:

```text
AW Channel
W Channel
B Channel
```

---

# 5. Single Write Mapping

Logical command:

```text
WRITE
```

AXI mapping:

```text
AWVALID = 1

AWLEN   = 0

AWBURST = INCR

WVALID  = 1

WLAST   = 1
```

Response path:

```text
BRESP
    |
    v
t_rsp_in
```

Characteristics:

- One address transaction
- One data beat
- One write response

---

# 6. INCR Burst Write Mapping

Logical command:

```text
BURST_WRITE
```

AXI mapping:

```text
AWLEN   = cmd_len - 1

AWBURST = INCR
```

Address sequence:

```text
addr_0 = base_addr

addr_1 = base_addr + size

addr_2 = base_addr + 2 * size

...
```

Final beat:

```text
WLAST = 1
```

on the last transfer.

---

# 7. FIFO Write Mapping

Logical command:

```text
FIFO_WRITE
```

AXI mapping:

```text
AWLEN = cmd_len - 1
```

Address generation:

```text
addr_n = base_addr
```

for every beat.

Example:

```text
Beat 0 -> 0x3000

Beat 1 -> 0x3000

Beat 2 -> 0x3000
```

This behavior is intended for FIFO-style peripherals.

---

# 8. WRAP Write Mapping

Logical command:

```text
WRAP_WRITE
```

AXI mapping:

```text
AWLEN   = cmd_len - 1

AWBURST = WRAP
```

The parser validates:

```text
Alignment

Wrap Legality

Length Legality
```

The backend generates:

```text
AXI wrap addresses
```

according to AXI4 rules.

Example:

```text
Wrap Boundary
       |
       v

addr_0

addr_1

addr_2

...

Wrap

addr_0
```

---

# 9. Read Command Mapping

The AXI-FULL backend executes read commands through:

```text
AR Channel

R Channel
```

---

# 10. Single Read Mapping

Logical command:

```text
READ
```

AXI mapping:

```text
ARVALID = 1

ARLEN   = 0

ARBURST = INCR
```

Expected response:

```text
RVALID

RDATA

RLAST
```

Characteristics:

- One address phase
- One read beat

---

# 11. INCR Burst Read Mapping

Logical command:

```text
BURST_READ
```

AXI mapping:

```text
ARLEN   = cmd_len - 1

ARBURST = INCR
```

Address sequence:

```text
addr_0

addr_1

addr_2

...
```

generated through sequential address increments.

---

# 12. FIFO Read Mapping

Logical command:

```text
FIFO_READ
```

AXI mapping:

```text
ARLEN = cmd_len - 1
```

Address sequence:

```text
addr_n = base_addr
```

for every beat.

Used for FIFO-style read peripherals.

---

# 13. WRAP Read Mapping

Logical command:

```text
WRAP_READ
```

AXI mapping:

```text
ARLEN   = cmd_len - 1

ARBURST = WRAP
```

Address generation follows AXI4 wrap rules.

The parser validates the requested operation.

The backend generates actual wrap addresses.

---

# 14. Byte Enable Mapping

The DexterLab write-mask field:

```text
cmd_wstrb
```

maps directly to:

```text
WSTRB
```

No transformation is performed.

Rules:

```text
WSTRB[i] = 1
    -> byte written

WSTRB[i] = 0
    -> byte preserved
```

Example:

```text
cmd_wstrb = 4'b0011
        |
        v
WSTRB     = 4'b0011
```

---

# 15. Protocol Attribute Mapping

Several AXI attributes are propagated directly from the command interface.

## Transfer Size

```text
cmd_size
         |
         v
AWSIZE

ARSIZE
```

## Protection Attributes

```text
cmd_prot
         |
         v
AWPROT

ARPROT
```

## Cache Attributes

```text
cmd_cache
          |
          v
AWCACHE

ARCACHE
```

## QoS Attributes

```text
cmd_qos
        |
        v
AWQOS

ARQOS
```

Backend implementation may choose to ignore unsupported optional fields.

---

# 16. ID Mapping

Command correlation uses:

```text
cmd_id
```

The AXI-FULL backend preserves command identity throughout execution.

The generated response contains:

```text
rsp_id
```

allowing command-response correlation.

---

# 17. Response Mapping

AXI responses are translated into standard DexterLab responses.

## Write Responses

```text
BRESP
```

maps to:

```text
t_rsp_in
```

## Read Responses

```text
RRESP
```

maps to:

```text
t_rsp_in
```

---

# 18. AXI Response Translation

| AXI Response | DexterLab Result |
|--------------|------------------|
| OKAY | Success |
| EXOKAY | Success (treated as OKAY) |
| SLVERR | Error |
| DECERR | Error |

Backend-specific error details are generated when required.

---

# 19. Backend Generated Errors

Additional validation may generate:

```text
Alignment Errors

Boundary Errors

Burst Errors

Protocol Errors

Timeout Errors
```

Error reporting uses:

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

# 20. Command Completion Mapping

The AXI-FULL backend uses the standard DexterLab completion model.

## Write Completion

```text
Final BRESP Accepted
        |
        v
rsp_end_cmd
```

## Read Completion

```text
Final RLAST Accepted
        |
        v
rsp_end_cmd
```

Command execution is not considered complete until:

```text
rsp_end_cmd = '1'
```

---

# 21. Locked Command Sequences

The command interface supports:

```text
cmd_lock
```

used for protected command execution.

Important:

```text
cmd_lock is interpreted by the Arbiter.
```

The AXI-FULL backend itself does not implement ownership management.

The backend executes commands normally while the Arbiter retains ownership.

Thus:

```text
cmd_lock
        |
        v
Arbiter Behavior

NOT

AXI Protocol Behavior
```

---

# 22. Cross References

This document is part of the AXI-FULL backend documentation suite.

Related documents:

```text
DexterLab AXI-FULL Architecture.md

DexterLab AXI-FULL Architecture Diagrams.md

DexterLab AXI-FULL Timing Specification.md

DexterLab AXI-FULL Error Model.md

DexterLab AXI-FULL Integration Guide.md

DexterLab AXI-FULL Backend.md
```

Core DexterLab references:

```text
Command Interface

Command Flow

Arbiter Specification

Design Principles
```

---

# 23. Summary

The AXI-FULL backend provides a deterministic and protocol-accurate translation of DexterLab commands into AXI4 transactions.

Supported mapping includes:

```text
Single Transfers

INCR Bursts

FIFO Operations

WRAP Bursts

WSTRB Propagation

Protocol Attributes

Response Handling

Command Completion
```

while preserving the protocol-independent command semantics defined by the DexterLab architecture.

The backend therefore acts as the AXI4 execution layer of the DexterLab command ecosystem.

---

# End of Document
