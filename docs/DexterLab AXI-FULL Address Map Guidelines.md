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

- fixed addresses for FIFO peripherals  # DexterLab AXI-FULL Address Map Guidelines

Version: 1.2.0

This document provides recommended guidelines for defining AXI4 address maps used with the DexterLab AXI-FULL backend.

The AXI-FULL backend itself does not impose any address-map restrictions.

Address mapping is defined entirely by the system integrator.

These recommendations help ensure correct behavior for:

- Single transfers
- Burst operations
- WRAP bursts
- FIFO transactions

---

# 1. General Principles

Recommended address maps should provide:

- Deterministic address decoding
- Clear separation between memory and peripherals
- Proper AXI alignment
- Safe burst execution

Recommended address space organization:

```text
Memory Regions

Peripheral Regions

FIFO Regions
```

---

# 2. RAM Regions

Recommended characteristics:

- Contiguous address ranges
- 4KB boundary alignment
- Support for INCR bursts
- Support for WRAP bursts
- Support for WSTRB semantics

Example:

```text
0x0000_0000 - 0x0000_FFFF   RAM0

0x0001_0000 - 0x0001_FFFF   RAM1
```

---

# 3. Peripheral Regions

Recommended characteristics:

- Deterministic decoding
- Fixed base addresses
- Clear region boundaries

Example:

```text
0x4000_0000   UART

0x4000_1000   SPI

0x4000_2000   GPIO
```

---

# 4. FIFO Regions

FIFO-style peripherals should expose fixed addresses.

Example:

```text
0x5000_0000   UART TX FIFO

0x5000_0010   UART RX FIFO
```

Recommended access mode:

```text
FIFO_READ

FIFO_WRITE
```

Address remains constant throughout the transaction.

---

# 5. WRAP Burst Guidelines

WRAP bursts should remain entirely within a legal AXI wrapping region.

Recommended constraints:

- Do not cross 4KB boundaries
- Do not cross RAM-region boundaries
- Do not cross peripheral-region boundaries

The parser validates WRAP legality.

The AXI-FULL backend generates AXI-compliant wrap addresses.

---

# 6. Burst-Friendly Layout

For optimal burst performance:

- Group related memory regions
- Avoid fragmented address spaces
- Align memory windows appropriately
- Keep burst traffic inside contiguous regions

Example:

```text
Good

0x0000_0000 - 0x000F_FFFF Memory

Bad

Memory blocks fragmented every few kilobytes
```

---

# 7. Reserved Regions

Recommended:

```text
Memory Region

Peripheral Region

FIFO Region

Reserved Region
```

for future expansion.

This simplifies long-term SoC maintenance.

---

# 8. Related Documentation

See:

```text
DexterLab AXI-FULL Integration Guide.md

DexterLab AXI-FULL Command Mapping.md

DexterLab AXI-FULL Timing Specification.md

DexterLab AXI-FULL Architecture.md
```

---

# 9. Summary

The AXI-FULL backend places no restrictions on the address map itself.

However, following these guidelines improves:

- Burst efficiency
- WRAP behavior
- FIFO operation
- Address decoding
- Long-term maintainability

and helps ensure reliable AXI4 system integration.

---

# End of Document
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
