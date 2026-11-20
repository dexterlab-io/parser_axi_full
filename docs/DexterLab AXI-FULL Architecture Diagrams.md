# DexterLab AXI-FULL Architecture Diagrams

(Version 1.2.0)

This document provides structural and execution-flow diagrams for the DexterLab AXI-FULL backend.

The diagrams complement:

```text
DexterLab AXI-FULL Architecture.md

DexterLab AXI-FULL Backend.md

DexterLab AXI-FULL Timing Specification.md

DexterLab AXI-FULL Command Mapping.md
```

The purpose of this document is to illustrate:

- Backend organization
- Internal data flow
- Command execution flow
- Burst generation
- Address generation
- AXI channel interaction
- Response generation

The diagrams focus on architectural structure rather than signal-level timing.

---

# 1. DexterLab AXI-FULL System Architecture

The AXI-FULL backend operates within the standard DexterLab execution model.

```text
Parser / Master
        |
        v
     Arbiter
        |
        v
+---------------------------------------------------+
|                 AXI-FULL Backend                  |
+---------------------------------------------------+
|                                                   |
| Command Execution Engine                          |
| Address Generator                                 |
| Write Controller (AW/W/B)                         |
| Read Controller  (AR/R)                           |
| Response Handler                                  |
|                                                   |
+---------------------------------------------------+
        |
        v
      AXI4 Bus
```

Command semantics are defined by the DexterLab command architecture.

Protocol execution is performed entirely inside the AXI-FULL backend.

---

# 2. AXI-FULL Backend Internal Architecture

```text
+---------------------------------------------------------------+
|                      AXI-FULL Backend                         |
+---------------------------------------------------------------+
|                                                               |
|  +------------------------+     +--------------------------+  |
|  | Command Execution      | --> | Address Generator        |  |
|  | Engine                 |     | (INCR / FIFO / WRAP)    |  |
|  +------------------------+     +--------------------------+  |
|               |                               |              |
|               v                               v              |
|  +------------------------+     +--------------------------+  |
|  | Write Controller       |     | Read Controller          |  |
|  | (AW / W / B)           |     | (AR / R)                |  |
|  +------------------------+     +--------------------------+  |
|               |                               |              |
|               +---------------+---------------+              |
|                               |                              |
|                               v                              |
|                    +----------------------+                 |
|                    | Response Handler     |                 |
|                    +----------------------+                 |
|                               |                              |
|                               v                              |
|                          t_rsp_in                            |
|                                                               |
+---------------------------------------------------------------+
```

---

# 3. Command Execution Flow

```text
t_cmd_out
     |
     v
+--------------------------+
| Command Execution Engine |
+--------------------------+
            |
            v
+--------------------------+
| Transaction Descriptor   |
+--------------------------+
            |
            v
+--------------------------+
| Read / Write Selection   |
+--------------------------+
            |
            +--------------------+
            |                    |
            v                    v

      Write Flow            Read Flow
```

The Command Execution Engine converts protocol-independent DexterLab commands into AXI4-compliant execution sequences.

---

# 4. Write Channel Flow (AW / W / B)

```text
DexterLab Command
          |
          v
+--------------------------+
| Command Execution Engine |
+--------------------------+
          |
          v
+--------------------------+
| Address Generator        |
+--------------------------+
          |
          v
+--------------------------+
| AW Controller            |
+--------------------------+
          |
          v
+--------------------------+
| W Controller             |
+--------------------------+
          |
          v
+--------------------------+
| B Response Decoder       |
+--------------------------+
          |
          v
+--------------------------+
| Response Handler         |
+--------------------------+
          |
          v
        t_rsp_in
```

### Notes

AW Controller generates:

```text
AWADDR
AWLEN
AWSIZE
AWBURST
```

W Controller generates:

```text
WDATA
WSTRB
WLAST
```

B Response Decoder processes:

```text
BRESP
```

and forwards results to the response handler.

---

# 5. Read Channel Flow (AR / R)

```text
DexterLab Command
          |
          v
+--------------------------+
| Command Execution Engine |
+--------------------------+
          |
          v
+--------------------------+
| Address Generator        |
+--------------------------+
          |
          v
+--------------------------+
| AR Controller            |
+--------------------------+
          |
          v
+--------------------------+
| R Controller             |
+--------------------------+
          |
          v
+--------------------------+
| Response Handler         |
+--------------------------+
          |
          v
        t_rsp_in
```

### Notes

AR Controller generates:

```text
ARADDR
ARLEN
ARSIZE
ARBURST
```

R Controller processes:

```text
RDATA
RRESP
RLAST
```

Response Handler converts AXI responses into DexterLab responses.

---

# 6. Burst Address Generation

```text
Initial Address
        |
        v
+--------------------------+
| Address Generator        |
+--------------------------+
        |
        +---------------------------+
        |                           |
        v                           v

    INCR Mode                  FIFO Mode

 addr += size                 addr = addr

        |
        v

     WRAP Mode

 wrapped address
 generation
```

---

## INCR Burst

```text
Beat 0  -> Addr + 0

Beat 1  -> Addr + Size

Beat 2  -> Addr + 2*Size

*eat N  -> Addr + N*Size
```

---

## FIFO Burst

```text
Beat 0  -> Addr

Beat 1  -> Addr

Beat 2  -> Addr

Beat N  -> Addr
```

---

## WRAP Burst

```text
Wrap Boundary
        |
        v
+--------------------------+
| Wrap Address Generator   |
+--------------------------+
        |
        v
Wrapped Address
```

The parser validates wrap legality.

The backend generates actual AXI wrap addresses.

---

# 7. Burst Engine Internal Structure

```text
+------------------------------------------------------+
|                    Burst Engine                      |
+------------------------------------------------------+
|                                                      |
| Burst Type Decoder                                  |
|                                                      |
| Beat Counter                                         |
|                                                      |
| Address Incrementer                                 |
|                                                      |
| Wrap Boundary Generator                             |
|                                                      |
| Size Decoder                                         |
|                                                      |
+------------------------------------------------------+
```

### Notes

The Burst Engine is shared between:

```text
Read Controller

Write Controller
```

Responsibilities:

- Burst sequencing
- Beat tracking
- Address generation
- WLAST generation
- RLAST expectation management

---

# 8. Write Data Path

```text
Command Data Array
          |
          v
+------------------------+
| Beat Selector          |
+------------------------+
          |
          v
+------------------------+
| WSTRB Generator        |
+------------------------+
          |
          v
+------------------------+
| AXI W Channel Output   |
+------------------------+
```

Responsibilities:

- Beat selection
- WDATA generation
- WSTRB propagation
- WLAST generation

---

# 9. Read Data Path

```text
AXI RDATA
      |
      v
+------------------------+
| Data Capture           |
+------------------------+
      |
      v
+------------------------+
| Response Formatter     |
+------------------------+
      |
      v
      t_rsp_in
```

Responsibilities:

- Data capture
- Beat tracking
- Response formatting
- Response publication

---

# 10. Response Handler Pipeline

```text
+---------------------------+
| AXI Response              |
| (BRESP / RRESP)           |
+---------------------------+
              |
              v
+---------------------------+
| Error Decoder             |
+---------------------------+
              |
              v
+---------------------------+
| Response Formatter        |
+---------------------------+
              |
              v
+---------------------------+
| rsp_end_cmd Generator     |
+---------------------------+
              |
              v
+---------------------------+
| Output (t_rsp_in)         |
+---------------------------+
```

### Responsibilities

The Response Handler performs:

- AXI response decoding
- Error translation
- Response formatting
- ID propagation
- Command completion generation
- Final response publication

---

# 11. Command Completion Flow

```text
Command Accepted
        |
        v
Transaction Executed
        |
        v
Response Generated
        |
        v
rsp_end_cmd
        |
        v
Command Complete
```

Command completion is standardized across all DexterLab backends.

---

# 12. Error Handling Flow

```text
AXI Error
     |
     v
+-----------------------+
| Error Decoder         |
+-----------------------+
     |
     v
+-----------------------+
| Error Translation     |
+-----------------------+
     |
     v
+-----------------------+
| t_rsp_in Error Fields |
+-----------------------+
```

Generated information may include:

```text
rsp_err_valid

rsp_err_code

rsp_err_addr

rsp_err_beat

rsp_err_id
```

---

# 13. Signal-Level References

Detailed signal timing is documented separately.

Refer to:

```text
DexterLab AXI-FULL Timing Specification.md

DexterLab AXI-FULL Command Mapping.md
```

This document focuses on backend structure and execution flow rather than cycle-accurate timing.

---

# 14. Summary

These diagrams illustrate the internal organization of the AXI-FULL backend, including:

```text
Command Execution Engine

Address Generator

Burst Engine

Write Controller

Read Controller

Response Handler
```

and the complete execution flow from:

```text
t_cmd_out
```

to:

```text
t_rsp_in
```

within the standard DexterLab architecture.

The diagrams complement the architectural, timing, error-model, and integration documentation that make up the AXI-FULL backend documentation suite.

---

# End of Document
