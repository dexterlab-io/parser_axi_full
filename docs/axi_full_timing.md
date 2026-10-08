AXI‑Full Timing and Handshake Rules
DexterLab Documentation Suite — 2026 Edition

This document defines the timing and handshake behavior of the AXI‑Full backend.
It describes how the backend drives and responds to AXI‑Full signals, ensuring protocol‑compliant burst sequencing and deterministic behavior.

1. Write Address Channel (AW)
1.1 Handshake Rules
AWVALID is asserted when the backend has a valid write address.

AWREADY must be high before AWVALID can be deasserted.

The handshake completes when:

Codice
AWVALID = 1 and AWREADY = 1
1.2 Timing Requirements
AWADDR must remain stable while AWVALID = 1.

AWLEN, AWSIZE, and AWBURST must remain stable during the handshake.

Address phase occurs before any write data beats.

2. Write Data Channel (W)
2.1 Handshake Rules
WVALID is asserted when write data is ready.

WREADY must be high before WVALID can be deasserted.

The handshake completes when:

Codice
WVALID = 1 and WREADY = 1
2.2 Timing Requirements
WDATA must remain stable while WVALID = 1.

WSTRB must remain stable during the handshake.

WLAST is asserted only on the final beat of the burst.

Beat sequencing is controlled by the burst engine.

3. Write Response Channel (B)
3.1 Handshake Rules
BVALID is asserted by the AXI slave.

BREADY is asserted by the backend when ready to accept the response.

The handshake completes when:

Codice
BVALID = 1 and BREADY = 1
3.2 Timing Requirements
BRESP must remain stable while BVALID = 1.

Response is forwarded to the parser through the Response Handler.

4. Read Address Channel (AR)
4.1 Handshake Rules
ARVALID is asserted when the backend has a valid read address.

ARREADY must be high before ARVALID can be deasserted.

The handshake completes when:

Codice
ARVALID = 1 and ARREADY = 1
4.2 Timing Requirements
ARADDR must remain stable while ARVALID = 1.

ARLEN, ARSIZE, and ARBURST must remain stable during the handshake.

Address phase occurs before any read data beats.

5. Read Data Channel (R)
5.1 Handshake Rules
RVALID is asserted by the AXI slave.

RREADY is asserted by the backend when ready to accept data.

The handshake completes when:

Codice
RVALID = 1 and RREADY = 1
5.2 Timing Requirements
RDATA must remain stable while RVALID = 1.

RLAST is asserted by the slave on the final beat.

Backend detects RLAST to complete the burst.

6. Burst Sequencing
The backend ensures:

correct beat count

correct WLAST / RLAST generation

correct address increment or wrap behavior

correct sequencing of AW → W → B

correct sequencing of AR → R

6.1 INCR Burst Timing
Codice
addr_next = addr + size
beat_count increments each cycle
WLAST/RLAST asserted on final beat
6.2 FIFO Burst Timing
Codice
addr_next = addr
beat_count increments each cycle
WLAST/RLAST asserted on final beat
6.3 WRAP Burst Timing
Codice
wrap_mask = burst_length * size
wrap_base = addr & ~(wrap_mask - 1)
addr_next = wrap_base + ((offset + size) % wrap_mask)
7. Corner Cases (NEW)
7.1 Backpressure
If the slave deasserts WREADY or RREADY:

backend stalls

address generator pauses

beat counter pauses

timing remains AXI‑compliant

7.2 Early RLAST
If slave asserts RLAST early:

backend terminates burst

remaining beats are discarded

parser receives truncated response

7.3 Missing RLAST
If slave never asserts RLAST:

backend times out

parser receives ERR_BACKEND

7.4 Misaligned Address
If address violates AXI alignment:

backend rejects command

parser receives ERR_ALIGN

8. Cross‑References (NEW)
This document is part of the AXI‑Full backend documentation set:

axi_full_architecture.md

axi_full_architecture_diagrams.md

axi_full_cmd_mapping.md

axi_full_errors.md

axi_full_integration.md

9. Summary
The AXI‑Full backend strictly follows AXI handshake rules and ensures correct timing for all burst types.
All address, data, and response phases are fully synchronous and handshake‑driven, guaranteeing deterministic and protocol‑compliant behavior.
