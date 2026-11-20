# DexterLab AXI-FULL Backend

(Version 1.2.0)

This document provides a high-level overview of the DexterLab AXI-FULL backend.

The AXI-FULL backend is responsible for translating protocol-independent DexterLab commands into AXI4-compliant bus transactions while preserving the command semantics defined by the DexterLab architecture.

It serves as the protocol execution layer of the AXI-FULL variant and provides support for:

- Single transfers
- Multi-beat bursts
- FIFO transactions
- WRAP transactions
- WSTRB propagation
- AXI response handling
- Deterministic command completion

This document focuses on backend responsibilities and behavior.

Detailed implementation information is provided in the architecture-specific documents referenced throughout this guide.

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

The backend is protocol-specific but command-independent.

Command semantics are defined by the DexterLab command architecture.

Protocol execution is implemented entirely inside the AXI-FULL backend.

---

# 2. Purpose

The AXI-FULL backend enables the DexterLab ecosystem to communicate with:

- AXI-based RAMs
- Memory controllers
- On-chip peripherals
- SoC subsystems
- Verification models
- Custom AXI slave devices

The backend converts protocol-independent commands into valid AXI4 transactions while maintaining deterministic execution behavior.

---

# 3. Backend Responsibilities

The AXI-FULL backend is responsible for:

```text
Command Execution

Address Generation

Burst Sequencing

AXI Protocol Handling

Response Generation

Error Reporting

Command Completion
```

The backend is not responsible for:

```text
Command Parsing

Command Validation

Ownership Management

Arbitration Decisions
```

These functions belong to the Parser and Arbiter layers.

---

# 4. Supported Features

## Basic Transfers

Supported operations:

```text
READ

WRITE

CHECK

WSTRB_WRITE
```

---

## Burst Operations

Supported operations:

```text
BURST_READ

BURST_WRITE

BURST_CHECK
```

---

## Wrap Operations

Supported operations:

```text
WRAP_READ

WRAP_WRITE

WRAP_CHECK
```

---

## FIFO Operations

Supported operations:

```text
FIFO_READ

FIFO_WRITE

FIFO_CHECK
```

---

## AXI Features

Supported AXI functionality:

```text
Multi-Beat Bursts

INCR Bursts

WRAP Bursts

Byte Enables (WSTRB)

Read Responses

Write Responses

Backpressure Handling

Protocol-Compliant Handshakes
```

---

# 5. Supported Burst Types

The backend implements the following burst modes.

---

## SINGLE

One address phase.

One data beat.

One completion response.

---

## INCR

Address increments every beat.

Example:

```text
Addr

Addr + Size

Addr + 2*Size
*``

---

## FIFO

Address remains *onstant for all beats.

Example:

*``text
Addr

*ddr

Addr
```

---

## WR*P

Address wraps inside a defined *ddress*boundary according*to AXI4 rules.

Wrap*legality is validated by the comma*d*layer.

Wrap address generation is*implemented by the backend.

---

* 6. Interfaces

The AXI-FULL backe*d communicates through the standar* DexterLab interfaces.

---

## Co*mand Interface

Commands are recei*ed through:

```text
t_cmd_out
```*
Examples*

```text
Address

*ength

Burst Type

Write Data

WST*B

Protocol Attributes

Command ID*
cmd_lock
*``

---

## Response Control Inter*ace*
Response acceptance is controlled*through:

```text
t_rsp_out
```

i*cluding:

*``text
rsp_ready

rsp_err_ready
*``

---

## Response Interface

Ex*cution results are generated throu*h:

```text
t_rsp_in
*``

including:

```text
rsp_valid
*rsp_data

rsp_last

rsp*err_valid

rsp_err_code

rsp_err_a*dr*
rsp_err_beat

rsp_err_id

*sp_end_cmd
```

---

# 7* Command Execution Model

The AXI-*ULL backend follows the standard D*xterLab execution sequence.

```te*t
Command Reception
          |
  *       v
Execution Configuration
 *        |
          v
AXI Transact*on Generation
          |
        * v
Response Processing
          |*          v
Response Publication
 *        |
          v
Command Comp*etion
```

Completion occurs throu*h:

```text
rsp_end_cmd
```

---

* 8. AXI Channel Support

The backe*d implements*all five AXI channels.

---

*# Write Address Channel

```text
A*VALID*
AWREADY

AWADDR*
AWLEN

AWSIZE

AWBURST*```

---

## Write Data Channel

`*`*ext
WVALID

WREADY

WDATA*
WSTRB

WLAST
```

---

*# Write Response Channel

```text
*VALID*
BREADY

BRESP
```

---

*# Read Address Channel

```text
AR*ALID*
ARREADY

ARADDR

ARLEN

*RSIZE

ARBURST
```

---

*# Read Data Channel

```text
RVALI**
RREADY

RDATA

R*ESP

RLAST
```

---

# 9. Response*Model

The backend*converts AXI responses into standa*dized DexterLab responses.

Suppor*ed*AXI responses:

```text
OKAY*
EXOKAY

SLV*RR

DECERR
```

The Response Handl*r:

- Decodes AXI*responses
-*Generates DexterLab responses
- Re*orts errors
- Generates*command completion

All responses *re delivered through:

```text
t_r*p_in
``*

---

# 10. Error Handling

The*backend supports*deterministic error reporting.

Er*or sources*include:

```text
Alignment Viol*tions

Boundary Violations

Burst *iolations

*imeout Conditions

Protocol Violat*ons

AXI Slave Errors
```

Error*information is reported through:

*``text
rsp_err*valid

rsp_err_code

rsp_err_addr
*rsp_err_beat

rsp_err_id
```

Deta*led definitions are documented in:*
```text
*exterLab AXI-FULL Error Model.md*```

---

# 11. Locked*Command Support

The command inter*ace supports:

```text
cmd_lock
``*

used for protected command seque*ces.

Important:

```text
cmd_lock*does not modify AXI protocol behav*or.
```

Ownership management is p*rformed by the Arbiter.

The backe*d remains ownership-agnostic and e*ecutes transactions normally.

---*
# 12. Simulation Support

Two sim*lation environments are provided.
*---

## GHDL

Provides:

```text
F*st Simulation

Makefile Automation*
Waveform Generation

Regression T*sting
```

Documentation:

```text*sim_ghdl.md
```

---

## Vivado / *SIM

Provides:

```text
Protocol-L*vel Debugging

Waveform Inspection*
Interactive GUI Analysis

AXI Cha*nel Verification
```

Documentatio*:

```text
sim_vivado.md
```

---
*# 13. Integration Overview

The ba*kend integrates into:

```text
RAM*Systems

Peripherals

Verification*Environments

AXI Interconnects

S*C Architectures
```

Integration*requirements include:

- Consisten* clock domain
- Proper reset handl*ng
- AX*-compliant slaves
- Correct burst *upport

Detailed integration guide*ines are documented in:

```text
D*xterLab AXI-FULL Integration Guide*md
```

---

# 14. Related Documen*ation

This document is part of th* AXI-FULL backend documentation su*te.

Technical references:

```tex*
Dex*erLab AXI-FULL Architecture.md

De*terLab AXI-FULL Architecture Diagr*ms.md

DexterLab AXI-FULL Command *apping.md

DexterLab AXI-FULL Timi*g*Specification.md

DexterLab AXI-FU*L Error Model.md

DexterLab AXI-F*LL Integration Guide.md
```

Core *exterLab references:

```text
Arch*tecture Overview

Command Interfac*

Command Flow

Arbiter Specificat*on

Design*Principles

Verification Methodolo*y
```

---

# 15. Summary

The AXI*FULL*backend provides the AXI4 protocol*execution layer of the DexterLab e*osystem.

It supports:

```*ext
Single Transfers

IN*R Bursts

FIFO Transactions*
WRAP Transactions

WSTRB Propagat*on

AXI Response Handling

Error*Reporting

Command Completion
```
*through*a deterministic,*synchronous, and standards*compliant implementation.

The bac*end integrates*seamlessly with the DexterLab comm*nd architecture and is suitable fo* simulation* verification, integration, and fu*ure system*expansion.

---

# End of Document*
