# AXI-Full Timing and Handshake Rules

This document defines the timing and handshake behavior of the AXI-Full backend.

---

## 1. Write Address Channel (AW)

Handshake:

- AWVALID asserted when address is ready
- AWREADY must be high before AWVALID can be deasserted

Timing:

- AWADDR stable while AWVALID = 1
- AWLEN, AWSIZE, AWBURST stable during handshake

---

## 2. Write Data Channel (W)

Handshake:

- WVALID asserted when write data is ready
- WREADY must be high before WVALID can be deasserted

Timing:

- WDATA stable while WVALID = 1
- WSTRB stable during handshake
- WLAST asserted on final beat

---

## 3. Write Response Channel (B)

Handshake:

- BVALID asserted by slave
- BREADY asserted by backend

Timing:

- BRESP stable while BVALID = 1

---

## 4. Read Address Channel (AR)

Handshake:

- ARVALID asserted when address is ready
- ARREADY must be high before ARVALID can be deasserted

Timing:

- ARADDR stable while ARVALID = 1
- ARLEN, ARSIZE, ARBURST stable during handshake

---

## 5. Read Data Channel (R)

Handshake:

- RVALID asserted by slave
- RREADY asserted by backend

Timing:

- RDATA stable while RVALID = 1
- RLAST asserted on final beat

---

## 6. Burst Sequencing

The backend ensures:

- correct beat count
- correct WLAST/RLAST generation
- correct address increment/wrap behavior

---

## 7. Summary

The AXI-Full backend strictly follows AXI handshake rules and ensures correct
timing for all burst types.

