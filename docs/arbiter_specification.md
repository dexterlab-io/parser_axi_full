markdown
# AXI‑Full Arbiter Specification  
**DexterLab Documentation Suite — 2026 Edition**

This document defines arbitration rules for multi‑master systems using the AXI‑Full backend.

---

## 1. Arbitration Requirements

- fair scheduling  
- no starvation  
- consistent arbitration across AW/W/B and AR/R  
- support for atomic commands  

---

## 2. Atomic Mode

If the parser sets `cmd_atomic = 1`:

- arbiter must prevent interleaving  
- backend must receive exclusive access  
- AXI ordering rules must be preserved  

Atomic mode affects scheduling, not AXI protocol behavior.

---

## 3. Channel Consistency

Arbiter must ensure:

- AW and W channels are not separated  
- AR and R channels are not separated  
- B and R responses are delivered without reordering  

---

## 4. Recommended Arbitration Policies

- round‑robin  
- weighted round‑robin  
- fixed priority (with starvation protection)  

---

## 5. Summary

The arbiter ensures correct multi‑master behavior and preserves atomic command semantics for the AXI‑Full backend.
