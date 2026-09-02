# Terraform: IBM Guardium GIM Installation Automation

This project automates the installation of IBM Guardium **GIM (Guardium Installation Manager)** agents on remote Linux/Unix servers using Terraform and SSH.

It supports multi-host deployments, automatic operating-system detection, installer-kit selection, password or SSH-key authentication, sudo users, custom TLS certificates, centralized logging, preflight network validation, and automated cleanup during `terraform destroy`.

> [!IMPORTANT]
> ### Perl Module Dependencies
>
> The IBM Guardium GIM Agent requires additional **Perl module dependencies** on the target system. By default, this project **does not install the optional Perl packages automatically**.
>
> To enable automatic installation, edit `examples/linux-gdp-gim/terraform.tfvars` and set:
>
> ```hcl
> install_optional_perl_packages = true
> ```
>
> **Recommended** unless the required Perl dependencies are already installed and managed separately on the target servers.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Basic Configuration](#basic-configuration)
- [Basic Usage](#basic-usage)
- [Documentation](#documentation)
- [Contributing](#contributing)
- [Support](#support)
- [License](#license)
- [Authors](#authors)

---

## Overview

This Terraform module automates deployment of IBM Guardium GIM agents across multiple Linux and Unix servers. For each target host it:

1. Reads target-host configuration from a CSV inventory.
2. Establishes an SSH connection to each target.
3. Detects the target operating system and architecture.
4. Selects the appropriate IBM Guardium GIM installer kit.
5. Performs connectivity and dependency checks.
6. Copies the installer to the target.
7. Runs the IBM installer in unattended mode.
8. Starts and verifies the GIM service.
9. Collects installation and Guardium debug logs.
10. Records deployment results in a central summary.

See [Architecture](docs/architecture.md) for the full installation flow and component diagram.

### What Gets Installed

**GIM — Guardium Installation Manager**, the Guardium agent-management component that communicates with the configured Guardium appliance.

---

## Features

- ✅ **Automatic OS detection** — detects supported Linux distributions and architecture automatically.
- ✅ **Automatic installer-kit selection** — selects the matching GIM kit for the detected OS and architecture.
- ✅ **GIM kit version pinning** — use `gim_kit_version` to select a specific kit when multiple compatible kits exist.
- ✅ **Preflight connectivity checks** — checks connectivity from the target server to the configured Guardium server before installation.
- ✅ **IPv4-aware target detection** — automatically determines an appropriate IPv4 address for `CLIENT_IP` and `--tapip`, with manual override via `local_ip`.
- ✅ **Cloud-host support** — handles AWS EC2, Azure, GCP, and complex cloud hostnames.
- ✅ **SSH deployment** — uses SSH and SCP for remote installation, with password or SSH-key authentication and sudo support.
- ✅ **Optional Perl dependency installation**
- ✅ **Idempotent execution** — already-installed GIM agents are detected and skipped.
- ✅ **GIM service management** — starts the service automatically when GIM is installed but not running.
- ✅ **Structured logging** — per-host logs plus automatic collection of `central_logger.log` and `GIM.log`.
- ✅ **Central CSV deployment summary**
- ✅ **Custom TLS certificate support**
- ✅ **Failover Guardium server support**
- ✅ **Shared-secret support**
- ✅ **Automatic uninstall on `terraform destroy`**

Full details for each capability live in [docs/](docs/) — see the [Documentation](#documentation) section below.

---

## Prerequisites

- **Terraform runner:** Terraform 1.5+, Bash, SSH client, SCP, and the IBM Guardium GIM installer packages (`sshpass` for password auth).
- **Target hosts:** SSH server, Perl 5.10+, network connectivity to the Guardium appliance, and root or passwordless sudo access.

Supported target platforms include RHEL, CentOS, Oracle Linux, Rocky Linux, AlmaLinux, Ubuntu, Debian, SUSE, and Amazon Linux.

For the full prerequisite list, network port requirements, and Terraform installation instructions, see the **[Installation Guide](docs/installation.md)**.

---

## Quick Start

### 1. Clone the Repository

```bash
git clone <repository-url>

cd terraform-linux-gdp-gim
```

### 2. Download GIM Installer Packages

Download the IBM Guardium GIM installer packages required for your target operating systems. For detailed instructions, see the **[GIM Download Guide](GIMDownload.md)**.

Place the extracted packages under:

```text
examples/linux-gdp-gim/packages/
└── unix/
    ├── Guardium_12.2.1.0_GIM_RedHat_r122289/
    ├── Guardium_12.2.1.0_GIM_Ubuntu_r122289/
    └── ...
```

### 3. Configure the Server Inventory

Edit `examples/linux-gdp-gim/inventory/servers.csv`:

```csv
name,os,host,mgmt_port,username,password,use_sudo,pem_key_path,gim_server_host,local_ip,install_dir,perl_path,shared_secret,failover_gim_server_host,gim_ca_file,gim_key_file,gim_cert_file,gim_ca_file_local,gim_key_file_local,gim_cert_file_local,auto_assign_ip,check_8443,allow_tls_fallback,gim_kit_version
poc-centos-v9a,linux,poc-centos-v9a.dev.my.domain.com,22,root,MyPassword,FALSE,,10.80.59.145,10.60.239.90,/usr/local/guardium,,,,,,,,,,0,TRUE,FALSE,r122289
poc-redhat-v9,linux,poc-redhat-v9.dev.my.domain.com,22,danny,MyPassword,TRUE,,10.80.59.145,10.60.217.149,/usr/local/guardium,,,,,,,,,,0,TRUE,FALSE,r122289
```

For a complete description of every column, see [Inventory CSV Format](docs/configuration.md#inventory-csv-format).

### 4. Configure Terraform Variables

Edit `examples/linux-gdp-gim/terraform.tfvars`:

```hcl
# Copy to terraform.tfvars and adjust. Inventory (relative to examples/linux-gdp-gim)
servers_csv_path = "./inventory/servers.csv"

# Logs written locally (relative to examples/linux-gdp-gim)
runner_log_dir = "./logs"

# Guardium ports (global settings - apply to all servers)
gim_server_port = 8446  # Guardium server port (default: 8446)
listener_port   = false # GIM listener port (true = use port 8445, false = don't use listener port)

# Packages root on the runner (relative to examples/linux-gdp-gim)
unix_packages_root = "./packages/unix"

# Leave empty to AUTO-SELECT correct kit based on target OS and arch.
unix_gim_installer_sh_path  = ""
unix_gim_installer_gim_path = ""

# Optional: custom perl path on the target. We do NOT install Perl itself.
unix_perl_path = ""

# Optional Perl packages on RHEL/CentOS targets before GIM install:
#   true  = install perl-lib, perl-Sys-Hostname, and perl-File-Copy (fixes missing Perl modules on minimal CentOS/RHEL)
#   false = do not install; use when hosts already have these or you manage packages elsewhere
install_optional_perl_packages = false

# Optional central summary log (empty = <runner_log_dir>/central-summary.csv)
unix_central_log_path = ""
```

See [Basic Configuration](#basic-configuration) below for the key points to know before you apply.

### 5. Initialize, Plan, and Apply

```bash
cd examples/linux-gdp-gim

terraform init
terraform plan   # Review all intended changes before applying them
terraform apply  # Connects to every configured target and runs the GIM deployment workflow
```

### 6. Check Logs

Logs are written under `examples/linux-gdp-gim/logs/`:

```text
logs/
├── server1.log
├── server1_central_logger.log
├── server1_GIM.log
├── server2.log
├── server2_central_logger.log
├── server2_GIM.log
└── central-summary.csv
```

See [Logging](docs/usage.md#logging) for details on log levels and the central summary.

---

## Basic Configuration

Configuration is split between two files:

- **`servers.csv`** — per-host configuration (host, credentials, Guardium server, TLS certs, etc.)
- **`terraform.tfvars`** — global deployment configuration (packages root, ports, logging)

Key points:

- `gim_server_host` is configured **per server** in `servers.csv`; `gim_server_port` is configured **globally** in `terraform.tfvars`.
- At least one SSH authentication method (`password` or `pem_key_path`) must be set per host.
- Non-root SSH users need `use_sudo = TRUE` and passwordless sudo on the target.

For the full variable reference, CSV column reference, and authentication examples, see the **[Configuration Reference](docs/configuration.md)**. For TLS certificates, kit-version pinning, and platform-specific notes, see **[Advanced Configuration](docs/advanced-configuration.md)**.

---

## Basic Usage

```bash
cd examples/linux-gdp-gim

terraform init
terraform plan
terraform apply
```

To remove GIM from a host, run `terraform destroy` — by default this uninstalls GIM from the target before removing it from Terraform state. See the **[Usage Guide](docs/usage.md)** for re-running installations, inspecting Terraform state, and manual uninstall/cleanup steps.

---

## Documentation

| Guide | Description |
|---|---|
| [Installation Guide](docs/installation.md) | Prerequisites, network requirements, and installing Terraform |
| [Configuration Reference](docs/configuration.md) | Terraform variables, CSV inventory format, authentication, GIM ports |
| [Advanced Configuration](docs/advanced-configuration.md) | Custom TLS certificates, kit-version pinning, sudo setup, platform-specific notes |
| [Architecture](docs/architecture.md) | Component overview, installation flow, and file structure |
| [Usage Guide](docs/usage.md) | Running, re-running, logging, uninstalling, and cleanup |
| [Troubleshooting](docs/troubleshooting.md) | Common errors and how to resolve them |
| [Security Considerations](docs/security.md) | Credential handling, SSH keys, and network security |
| [Creating Self-Signed GIM Certificates](docs/create-self-signed-gim-cert.md) | Step-by-step TLS certificate generation |
| [GIM Download Guide](GIMDownload.md) | Downloading GIM/S-TAP installer packages from IBM |

### References

- [IBM Guardium Documentation](https://www.ibm.com/docs/en/gdp)
- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before submitting pull requests.

---

## Support

Before opening an issue, see the [Troubleshooting Guide](docs/troubleshooting.md). Maintainer information is available in [MAINTAINERS.md](MAINTAINERS.md).

---

## License

This project is licensed under the **Apache License 2.0**. See [LICENSE](LICENSE).

```text
#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#
```

---

## Authors

This module is maintained by IBM with contributions from the community. See the repository's contributors page for the complete contributor history.
