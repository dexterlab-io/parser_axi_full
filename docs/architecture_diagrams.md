# AXI-Full Backend Architecture Diagrams

This document provides simplified ASCII diagrams illustrating the internal
structure of the AXI-Full backend.

---

## 1. Top-Level Architecture

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

Codice

---

## 2. Write Channel Flow (AW/W/B)

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

Codice

---

## 3. Read Channel Flow (AR/R)

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

Codice

---

## 4. Burst Address Generation

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
INCR Mode                       FIFO Mode
addr += size                     addr = addr

|
v
WRAP Mode
addr = (addr & wrap_mask) | offset

Codice

---

## 5. Summary

These diagrams illustrate the internal structure and data flow of the AXI-Full
backend, including command expansion, address generation, write/read channels,
and response handling.
