# AXI-Full Error Model

This document lists backend-specific error conditions and how they map to parser
response codes.

---

## 1. Alignment Errors

Triggered when:

- address is not aligned to data size
- wrap boundary is misaligned

Parser response:

- `ERR_ALIGN`

---

## 2. Burst Length Errors

Triggered when:

- burst length exceeds backend limits
- burst length is zero
- WRAP burst length is not a power of two

Parser response:

- `ERR_BURST_LEN`

---

## 3. Wrap Boundary Errors

Triggered when:

- wrap boundary is outside legal AXI range
- address crosses wrap boundary incorrectly

Parser response:

- `ERR_WRAP`

---

## 4. FIFO Errors

Triggered when:

- FIFO burst length is invalid
- FIFO address is not constant

Parser response:

- `ERR_FIFO`

---

## 5. AXI Slave Errors

AXI responses:

- SLVERR
- DECERR

Parser response:

- `ERR_BACKEND`

---

## 6. Summary

The backend provides deterministic error reporting for all AXI-Full violations.

