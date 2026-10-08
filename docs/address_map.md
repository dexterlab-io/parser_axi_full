markdown
# AXI‑Full Address Map Guidelines  
**DexterLab Documentation Suite — 2026 Edition**

This document provides recommended guidelines for defining the address map used with the AXI‑Full backend.

---

## 1. RAM Regions

Recommended:

- contiguous regions  
- aligned to 4KB boundaries  
- support for INCR and WRAP bursts  
- support for WSTRB  

Example:

0x0000_0000 – 0x0000_FFFF   RAM0
0x0001_0000 – 0x0001_FFFF   RAM1

Codice

---

## 2. Peripheral Regions

Recommended:

- fixed addresses for FIFO peripherals  
- avoid WRAP bursts unless supported  
- ensure address decode is deterministic  

Example:

0x4000_0000   UART FIFO
0x4000_1000   SPI FIFO

Codice

---

## 3. WRAP Burst Constraints

WRAP bursts must not cross:

- 4KB boundaries  
- peripheral boundaries  
- RAM region boundaries  

---

## 4. FIFO Burst Constraints

FIFO bursts require:

- constant address  
- peripheral must support FIFO semantics  

---

## 5. Summary

The AXI‑Full backend does not impose an address map; these guidelines ensure correct burst behavior and integration with RAM and peripherals.
