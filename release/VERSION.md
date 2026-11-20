# DexterLab AXI-FULL Backend

Version: 1.2.0

Release Date: 2026-11-16

Compatible With:

```text
DexterLab Parser v1.1.0
```

Status:

```text
Stable
```

---

# Overview

The AXI-FULL backend provides full AXI4 command execution support for the DexterLab command ecosystem.

It translates protocol-independent DexterLab commands into AXI4-compliant transactions while preserving command semantics defined by the parser and arbiter layers.

Supported features include:

- Multi-beat bursts
- Wrap bursts
- WSTRB support
- Multi-ID operation
- AXI response handling
- Timeout detection
- Error reporting
- Full compatibility with the DexterLab command model

---

# Release Summary

Version 1.2.0 aligns the AXI-FULL backend with the updated DexterLab v1.1.0 architecture and command interface.

This release introduces interface-level updates required by the new parser and arbiter infrastructure while preserving AXI transaction behavior.

---

# Major Changes

## Parser Interface Alignment

Updated integration with:

```text
t_cmd_out
t_rsp_out
t_rsp_in
```

and the current DexterLab command execution model.

---

## Command Completion Model

Updated support for:

```text
rsp_end_cmd
```

as the standard command completion mechanism.

---

## Lock Support

Updated support for:

```text
cmd_lock
```

used for protected command sequences and arbiter ownership retention.

---

## Documentation Refresh

Documentation structure updated to align with:

```text
DexterLab Architecture Overview
Design Principles
Troubleshooting Guide
Versioning and Compatibility Guide
Verification Methodology
```

from the main DexterLab documentation suite.

---

# Compatibility

Compatible with:

```text
DexterLab Parser v1.1.0
```

Recommended parser version:

```text
v1.1.0 or later
```

---

# Previous Release

Version:

```text
1.1.0
```

Release Date:

```text
2026-10-07
```

Status:

```text
Stable
```

---

# End of Document
