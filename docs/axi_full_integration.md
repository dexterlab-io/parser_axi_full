# AXI-Full Integration Guide

This document provides guidelines for integrating the AXI-Full backend into SoC
designs.

---

## 1. Clock and Reset

Requirements:

- single synchronous clock domain
- active-high synchronous reset recommended

---

## 2. AXI Bus Connection

Connect:

- AW, W, B channels for writes
- AR, R channels for reads

Ensure:

- slave supports multi-beat bursts
- slave supports FIFO and WRAP bursts if used

---

## 3. RAM and Peripheral Integration

For RAM:

- use synchronous RAM with byte-enable support
- ensure correct WSTRB handling

For peripherals:

- ensure address ranges are valid
- ensure burst types are supported

---

## 4. Arbitration

If multiple masters exist:

- use AXI arbiter
- ensure fairness and no starvation
- ensure AW/W/B and AR/R channels are arbitrated consistently

---

## 5. Parser Integration

Connect:

- `t_cmd_out` from parser core
- `t_rsp_in` to parser core

Ensure:

- parser core version matches release notes
- command interface timing is respected

---

## 6. Summary

The AXI-Full backend integrates cleanly into AXI-based SoC designs and supports
RAM, peripherals, and multi-master systems.

