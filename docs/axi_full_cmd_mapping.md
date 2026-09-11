# AXI-Full Command Mapping

This document explains how DexterLab parser commands (`t_cmd_out`) are mapped
to AXI-Full transactions.

---

## 1. Command Types

The backend supports:

- single write
- single read
- INCR burst
- FIFO burst
- WRAP burst

Each command contains:

- address
- data (for writes)
- burst length
- burst type
- byte-enable mask
- atomic flag

---

## 2. Write Command Mapping

### 2.1 Single Write

Mapped to:

- AWVALID with `AWLEN = 0`
- WVALID with `WLAST = 1`
- BVALID response

### 2.2 INCR Burst

Mapped to:

- AWLEN = burst_length - 1
- WLAST asserted on final beat
- address increments by data size

### 2.3 FIFO Burst

Mapped to:

- AWLEN = burst_length - 1
- address remains constant
- WLAST asserted on final beat

### 2.4 WRAP Burst

Mapped to:

- AWLEN = burst_length - 1
- wrap boundary computed using AXI rules
- address wraps when boundary reached

---

## 3. Read Command Mapping

### 3.1 Single Read

Mapped to:

- ARVALID with `ARLEN = 0`
- RLAST asserted by slave

### 3.2 INCR Burst

Mapped to:

- ARLEN = burst_length - 1
- address increments per beat

### 3.3 FIFO Burst

Mapped to:

- ARLEN = burst_length - 1
- address remains constant

### 3.4 WRAP Burst

Mapped to:

- ARLEN = burst_length - 1
- wrap boundary enforced

---

## 4. Byte-Enable Mapping

Parser byte-enable (`t_cmd_out.wstrb`) maps directly to AXI `WSTRB`.

---

## 5. Response Mapping

AXI responses map to parser responses:

| AXI Response | Parser Response |
|--------------|-----------------|
| OKAY         | success          |
| SLVERR       | backend error    |
| DECERR       | backend error    |

---

## 6. Summary

The AXI-Full backend provides a deterministic mapping from parser commands to
AXI-Full transactions, supporting all burst types and byte-enable semantics.

