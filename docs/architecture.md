# Architecture

## Table of Contents

- [Component Overview](#component-overview)
- [Installation Flow](#installation-flow)
- [File Structure](#file-structure)

---

## Component Overview

```text
┌────────────────────┐
│ Terraform Runner   │
│                    │
│ Terraform + Bash   │
│ SSH / SCP          │
└─────────┬──────────┘
          │
          │ SSH
          │
          ▼
┌────────────────────┐
│ Target Linux Host  │
│                    │
│ GIM Installer      │
│ GIM Agent          │
└─────────┬──────────┘
          │
          │ TCP 8446
          │
          ▼
┌────────────────────┐
│ IBM Guardium       │
│ Central Manager    │
└────────────────────┘
```

---

## Installation Flow

The Unix installer workflow (`scripts/unix/install_gim_unix.sh`) contains eight primary phases:

1. **SSH connectivity** and Guardium reachability checks.
2. **OS and architecture detection**.
3. **Existing installation detection**.
4. **Installer-kit selection**.
5. **Installer transfer** to `/tmp/guardium_gim/`.
6. **Perl dependency validation/installation**.
7. **IPv4 resolution and GIM configuration**.
8. **Installation, service verification, summary logging, and debug-log collection**.

---

## File Structure

```text
terraform-guardium-gim-linux/
├── README.md
├── GIMDownload.md
├── CONTRIBUTING.md
├── MAINTAINERS.md
├── LICENSE
├── main.tf
├── variables.tf
├── outputs.tf
│
├── docs/
│   ├── installation.md
│   ├── configuration.md
│   ├── advanced-configuration.md
│   ├── architecture.md
│   ├── usage.md
│   ├── troubleshooting.md
│   ├── security.md
│   └── create-self-signed-gim-cert.md
│
├── scripts/
│   └── unix/
│       ├── common_guardium_lib.sh
│       ├── install_gim_unix.sh
│       ├── uninstall_gim_unix.sh
│       └── install_stap_unix.sh
│
└── examples/
    └── basic/
        ├── main.tf
        ├── variables.tf
        ├── terraform.tfvars
        │
        ├── inventory/
        │   ├── servers.csv
        │   └── servers.example.csv
        │
        ├── gim-certs/
        │   ├── gim-key.pem
        │   ├── gim-cert.pem
        │   └── gim-ca.pem
        │
        ├── packages/
        │   └── unix/
        │
        └── logs/
            ├── <host>.log
            ├── <host>_central_logger.log
            ├── <host>_GIM.log
            ├── <host>-uninstall.log
            └── central-summary.csv
```

`examples/basic/` is the working example driven by the [Quick Start](../README.md#quick-start): its `main.tf` reads `inventory/servers.csv` and invokes `scripts/unix/install_gim_unix.sh` (and, on `terraform destroy`, `scripts/unix/uninstall_gim_unix.sh`) over SSH for each target host.

---

Next: [Usage](usage.md) · [Troubleshooting](troubleshooting.md)
