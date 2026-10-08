AXI‑Full Command Mapping
DexterLab Documentation Suite — 2026 Edition

This document explains how DexterLab parser commands (t_cmd_out) are mapped to AXI‑Full transactions.
It describes the translation of parser semantics into AXI address, burst, data, and response behavior.

1. Command Types
The AXI‑Full backend supports the following command types:

single write

single read

INCR burst

FIFO burst

WRAP burst

Each parser command contains:

base address

write data (for write commands)

burst length

burst type

byte‑enable mask (wstrb)

atomic flag

command ID (for response correlation)

The backend expands these fields into AXI‑Full compliant transactions.

2. Write Command Mapping
2.1 Single Write
Mapped to:

AWVALID = 1, AWLEN = 0

WVALID = 1, WLAST = 1

WSTRB = t_cmd_out.wstrb

BVALID returned by slave

Address behavior:

address remains constant

one data beat

2.2 INCR Burst
Mapped to:

AWLEN = burst_length - 1

WLAST asserted on final beat

address increments by data size (AWSIZE)

Address sequence:

Codice
addr_0 = base_addr
addr_1 = base_addr + size
addr_2 = base_addr + 2*size
...
2.3 FIFO Burst
Mapped to:

AWLEN = burst_length - 1

WLAST asserted on final beat

address remains constant for all beats

Address sequence:

Codice
addr_i = base_addr   (for all beats)
Used for FIFO‑style peripherals.

2.4 WRAP Burst
Mapped to:

AWLEN = burst_length - 1

wrap boundary computed using AXI rules

address wraps when boundary reached

Address sequence:

Codice
wrap_mask = burst_length * size
wrap_base = base_addr & ~(wrap_mask - 1)

addr_i = wrap_base + ((offset + i*size) % wrap_mask)
3. Read Command Mapping
3.1 Single Read
Mapped to:

ARVALID = 1, ARLEN = 0

RLAST asserted by slave

Address behavior:

address remains constant

one data beat

3.2 INCR Burst
Mapped to:

ARLEN = burst_length - 1

address increments per beat

Address sequence identical to write INCR.

3.3 FIFO Burst
Mapped to:

ARLEN = burst_length - 1

address remains constant

Used for FIFO‑style read peripherals.

3.4 WRAP Burst
Mapped to:

ARLEN = burst_length - 1

wrap boundary enforced

Address sequence identical to write WRAP.

4. Byte‑Enable Mapping
Parser byte‑enable (t_cmd_out.wstrb) maps directly to AXI WSTRB.

Rules:

WSTRB[i] = 1 → byte written

WSTRB[i] = 0 → byte preserved

width determined by AWSIZE

No transformation is applied.

5. Response Mapping
AXI responses map to parser responses as follows:

AXI Response	Parser Response
OKAY	success
SLVERR	backend error
DECERR	backend error


Additional backend‑generated errors:

Backend Error	Condition
alignment error	misaligned address or size
wrap boundary error	burst crosses 4KB boundary
invalid burst	unsupported burst type


These are documented in axi_full_errors.md.

6. Atomic Mode (NEW)
If the parser sets cmd_atomic = 1, the arbiter ensures:

no other backend can interleave transactions

AXI‑Full backend executes the command as an atomic sequence

AXI ordering rules are preserved

Atomic mode does not change AXI mapping; it changes scheduling.

7. Cross‑References (NEW)
This document is part of the AXI‑Full backend documentation set:

axi_full_architecture.md — backend architecture

axi_full_architecture_diagrams.md — structural diagrams

axi_full_timing.md — handshake and timing rules

axi_full_errors.md — error model

axi_full_integration.md — integration guidelines

8. Summary
The AXI‑Full backend provides a deterministic and protocol‑accurate mapping from parser commands to AXI‑Full transactions.
All burst types, byte‑enable semantics, and response behaviors are supported, ensuring correct integration with AXI‑compliant peripherals.
