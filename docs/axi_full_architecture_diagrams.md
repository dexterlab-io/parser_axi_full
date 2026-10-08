AXI‑Full Backend Architecture Diagrams
DexterLab Documentation Suite — 2026 Edition

This document provides updated ASCII diagrams illustrating the internal structure, data flow, and burst/address behavior of the AXI‑Full backend.
It complements the architectural description in:

axi_full_architecture.md

backend_axi_full.md

axi_full_timing.md

axi_full_cmd_mapping.md

1. Top‑Level Architecture
Codice
+---------------------------------------------------------------+
|                        AXI-Full Backend                       |
+---------------------------------------------------------------+
|                                                               |
|  +-------------------+     +-------------------------------+  |
|  | Command Expansion | --> | Address Generator             |  |
|  | Engine            |     | (INCR / FIFO / WRAP)          |  |
|  +-------------------+     +-------------------------------+  |
|            |                                 |               |
|            v                                 v               |
|  +-------------------+     +-------------------------------+  |
|  | Write Controller  | --> | Read Controller               |  |
|  | (AW/W/B)          |     | (AR/R)                        |  |
|  +-------------------+     +-------------------------------+  |
|            |                                 |               |
|            v                                 v               |
|                     +-------------------------+               |
|                     | Response Handler        |               |
|                     +-------------------------+               |
|                                                               |
+---------------------------------------------------------------+
2. Write Channel Flow (AW / W / B)
Codice
Parser Cmd
    |
    v
+------------------+
| Expansion Engine |
+------------------+
    |
    v
+------------------+      +------------------+
| AW Controller    | ---> | W Controller     |
+------------------+      +------------------+
    |
    v
+------------------+
| B Response Logic |
+------------------+
Notes:

AW generates address, burst length, size, and burst type.

W handles data beats, WSTRB, and WLAST generation.

B collects BRESP and propagates errors to the parser.

3. Read Channel Flow (AR / R)
Codice
Parser Cmd
    |
    v
+------------------+
| Expansion Engine |
+------------------+
    |
    v
+------------------+
| AR Controller    |
+------------------+
    |
    v
+------------------+
| R Controller     |
+------------------+
    |
    v
+------------------+
| Response Handler |
+------------------+
Notes:

AR generates address, burst length, size, and burst type.

R handles data beats, RRESP, and RLAST.

Response Handler merges AXI responses with parser semantics.

4. Burst Address Generation
Codice
Initial Address
    |
    v
+------------------+
| Address Generator |
+------------------+
    |
    +-------------------------------+
    |                               |
    v                               v
INCR Mode                           FIFO Mode
addr += size                        addr = addr

    |
    v
WRAP Mode
addr = (addr & wrap_mask) | offset
Notes:

wrap_mask defines the boundary of the wrapping region.

offset increments within the wrap window.

FIFO mode keeps the same address for all beats.

5. Burst Engine Internal Structure (NEW)
Codice
+---------------------------------------------------+
|                 Burst Engine                      |
+---------------------------------------------------+
|  Burst Type (INCR/FIFO/WRAP)                      |
|  Beat Counter                                     |
|  Wrap Boundary Calculator                         |
|  Address Incrementer                              |
|  Size Decoder (byte/halfword/word)                |
+---------------------------------------------------+
Notes:

The burst engine is shared by both read and write controllers.

Beat counter drives WLAST/RLAST generation.

Wrap boundary calculator ensures AXI‑compliant wrap behavior.

6. Response Handler Pipeline (NEW)
Codice
+---------------------------+
| AXI Response (BRESP/RRESP)|
+---------------------------+
              |
              v
+---------------------------+
| Error Decoder             |
+---------------------------+
              |
              v
+---------------------------+
| Parser Response Formatter |
+---------------------------+
              |
              v
+---------------------------+
| Output to Parser Core     |
+---------------------------+
Notes:

AXI errors are mapped to parser error codes.

Response formatting ensures consistent command‑response semantics.

7. Signal‑Level Notes (NEW)
Detailed signal timing and handshake rules are documented in:

axi_full_timing.md

axi_full_cmd_mapping.md

This diagram document focuses on structural flow, not signal‑level detail.

8. Summary
These diagrams illustrate the internal structure and data flow of the AXI‑Full backend, including:

command expansion

burst engine

address generation

write/read channel controllers

response handling pipeline

They complement the architectural, timing, and integration documents in the AXI‑Full backend documentation set.
