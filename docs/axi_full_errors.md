AXI‑Full Error Model
DexterLab Documentation Suite — 2026 Edition

This document describes all backend‑specific error conditions and how they map to parser response codes.
It complements the AXI response mapping described in:

axi_full_cmd_mapping.md

axi_full_architecture.md

backend_axi_full.md

1. Alignment Errors
Triggered when:

the address is not aligned to the AXI data size (AWSIZE)

the burst start address violates AXI alignment rules

WRAP burst boundary is misaligned

Parser response:

Codice
ERR_ALIGN
Notes:

Alignment is checked before issuing AW/AR.

Misalignment prevents the transaction from starting.

2. Burst Length Errors
Triggered when:

burst length exceeds backend limits

burst length is zero

WRAP burst length is not a power of two

burst length violates AXI constraints (e.g., >256 beats)

Parser response:

Codice
ERR_BURST_LEN
Notes:

Burst length validation occurs during command expansion.

WRAP bursts must have lengths of 2, 4, 8, 16, 32, 64, 128, or 256.

3. Wrap Boundary Errors
Triggered when:

wrap boundary is outside legal AXI range

burst crosses a 4KB boundary (AXI violation)

address wraps incorrectly due to miscalculated offset

wrap mask does not match burst length × data size

Parser response:

Codice
ERR_WRAP
Notes:

AXI requires WRAP bursts to remain within a single wrap region.

Violations are detected by the address generator.

4. FIFO Errors
Triggered when:

FIFO burst length is invalid

FIFO address changes during the burst

FIFO mode used with unsupported data width

FIFO burst exceeds backend FIFO constraints

Parser response:

Codice
ERR_FIFO
Notes:

FIFO bursts require constant address for all beats.

FIFO mode is typically used for peripheral FIFOs or streaming interfaces.

5. AXI Slave Errors
AXI responses:

SLVERR

DECERR

Parser response:

Codice
ERR_BACKEND
Notes:

These errors originate from the AXI slave.

The backend does not modify AXI error semantics.

The Response Handler maps AXI errors to parser error codes.

6. Backend‑Generated Errors (NEW)
These errors are generated internally by the backend, not by AXI:

6.1 Invalid Burst Type
Triggered when:

parser requests unsupported burst type

burst type is inconsistent with command parameters

Parser response:

Codice
ERR_INVALID_BURST
6.2 Unsupported Size
Triggered when:

data size (AWSIZE) is not supported by the backend

size does not match configured data width

Parser response:

Codice
ERR_SIZE
6.3 Atomic Mode Violation
Triggered when:

atomic command is interrupted by arbiter

backend detects illegal interleaving

Parser response:

Codice
ERR_ATOMIC
7. Error Priority (NEW)
Errors are resolved in the following priority order:

Alignment errors

Burst length errors

Wrap boundary errors

FIFO errors

Backend‑generated errors

AXI slave errors

This ensures deterministic behavior across all backend operations.

8. Summary
The AXI‑Full backend provides deterministic error reporting for all AXI‑Full violations and backend‑specific constraints.
Errors are detected early (during command expansion) or during execution (address generation, burst sequencing, response handling), ensuring robust and predictable behavior.
