AXI‑Full Integration Guide
DexterLab Documentation Suite — 2026 Edition

This document provides guidelines for integrating the AXI‑Full backend into AXI‑based SoC designs.
It covers clocking, reset, bus connection, RAM/peripheral integration, arbitration, and parser interface requirements.

1. Clock and Reset
1.1 Clock Domain
The AXI‑Full backend operates in a single synchronous clock domain.

Requirements:

one system clock (clk)

no asynchronous clock crossings

AXI slave must share the same clock or use proper CDC logic

1.2 Reset
Recommended reset scheme:

active‑high synchronous reset

reset must be asserted long enough to clear internal FSMs

AXI slave must follow the same reset domain

2. AXI Bus Connection
The backend exposes the full AXI‑Full interface:

Write Address Channel: AW

Write Data Channel: W

Write Response Channel: B

Read Address Channel: AR

Read Data Channel: R

2.1 Requirements for AXI Slave
The AXI slave must support:

multi‑beat bursts

INCR bursts

FIFO bursts (constant address)

WRAP bursts (AXI‑compliant wrap boundaries)

byte‑enable (WSTRB) semantics

synchronous behavior

Optional but recommended:

support for all AXI burst lengths (1–256 beats)

support for all AXI sizes (byte, halfword, word)

2.2 Unsupported AXI Features
The backend does not use:

AXI QoS

AXI Region

AXI User signals

AXI IDs (single master configuration)

These signals must be tied off or ignored by the slave.

3. RAM and Peripheral Integration
3.1 RAM Integration
For RAM‑based slaves:

use synchronous RAM

support byte‑enable (WSTRB)

ensure correct handling of partial writes

ensure address alignment rules are respected

ensure wrap bursts do not cross memory boundaries

Recommended:

implement RAM with registered outputs

support all AXI sizes (8/16/32‑bit)

3.2 Peripheral Integration
For peripherals:

ensure address ranges are valid

ensure burst types are supported

FIFO mode must be explicitly supported

WRAP bursts may be unsupported (slave may return DECERR)

Peripheral examples:

UART FIFOs

SPI FIFOs

DMA engines

streaming interfaces

4. Arbitration
If multiple masters exist in the system:

4.1 AXI Arbiter Requirements
fair scheduling

no starvation

consistent arbitration across AW/W/B and AR/R

atomic commands must not be interrupted

4.2 Atomic Mode
If the parser issues an atomic command, the arbiter must:

prevent interleaving

guarantee exclusive access

preserve AXI ordering rules

Atomic mode does not change AXI behavior; it changes scheduling.

5. Parser Integration
The AXI‑Full backend connects directly to the DexterLab parser core.

5.1 Required Signals
Connect:

t_cmd_out (parser → backend)

t_rsp_in (backend → parser)

5.2 Timing Requirements
parser must hold command valid until backend acknowledges

backend guarantees deterministic response timing

command interface is fully synchronous

5.3 Version Compatibility
Ensure:

parser core version matches release notes

backend version matches parser command semantics

6. Address Map (NEW)
The AXI‑Full backend does not impose an address map.
Address mapping is defined by the SoC integrator.

Recommended:

group RAM regions

group peripheral regions

avoid crossing 4KB boundaries for WRAP bursts

ensure FIFO peripherals have fixed addresses

A dedicated document (address_map.md) is recommended.

7. Integration Checklist (NEW)
Before integrating the backend, verify:

[ ] AXI slave supports required burst types

[ ] AXI slave supports WSTRB

[ ] address alignment rules are respected

[ ] wrap boundaries are AXI‑compliant

[ ] arbiter supports atomic mode

[ ] parser version matches backend version

[ ] reset domain is consistent

[ ] clock domain is consistent

[ ] RAM/peripheral address map is valid

8. Cross‑References (NEW)
This document is part of the AXI‑Full backend documentation set:

axi_full_architecture.md

axi_full_architecture_diagrams.md

axi_full_cmd_mapping.md

axi_full_timing.md

axi_full_errors.md

backend_axi_full.md

9. Summary
The AXI‑Full backend integrates cleanly into AXI‑based SoC designs, supporting RAM, peripherals, and multi‑master systems.
With proper arbitration, address mapping, and AXI‑compliant slaves, the backend provides deterministic, robust, and fully synchronous AXI‑Full behavior.
