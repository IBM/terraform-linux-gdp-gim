# Installation Guide

This guide covers everything needed before running Terraform: prerequisites for both the machine running Terraform and the target hosts, network requirements, and how to install Terraform itself.

## Table of Contents

- [Prerequisites](#prerequisites)
  - [Terraform Runner](#terraform-runner)
  - [Target Hosts](#target-hosts)
  - [Network Requirements](#network-requirements)
  - [Optional Perl Dependencies](#optional-perl-dependencies)
- [Installing Terraform](#installing-terraform)
- [Supported Platforms](#supported-platforms)

---

## Prerequisites

### Terraform Runner

The machine that runs `terraform apply` (your workstation, CI runner, etc.) needs:

- Terraform 1.5+
- Bash
- SSH client
- SCP
- IBM Guardium GIM installer packages (see [GIM Download Guide](../GIMDownload.md))

For password authentication:

- `sshpass`

Recommended:

- `nc` or `ncat`
- `git`
- `unzip`

### Target Hosts

Each server that will receive the GIM agent needs:

- SSH server
- Perl 5.10+
- Network connectivity to the Guardium appliance
- Root privileges or passwordless sudo

### Network Requirements

#### Terraform Runner → Target Host

| Port | Protocol | Purpose |
|---|---|---|
| `22` | TCP | SSH and SCP |

The SSH port can be changed per host using the `mgmt_port` CSV field.

#### Target Host → Guardium Appliance

| Port | Requirement | Purpose |
|---|---|---|
| `8446` | Required by default | GIM communication with Guardium |
| `8445` | Optional | GIM listener when `listener_port = true` |
| `8443` | Optional | Discovery and feature-related communication |

Custom GIM server ports can be configured globally using `gim_server_port` (see [Configuration Reference](configuration.md#gim-ports)).

### Optional Perl Dependencies

On minimal RHEL/CentOS/Amazon Linux installations, GIM may require additional Perl modules. Examples include:

```text
perl-lib
perl-Sys-Hostname
perl-File-Copy
perl-File-Find
perl-Data-Dumper
perl-core
```

> [!IMPORTANT]
> By default, this project **does not install these optional Perl packages automatically**. To enable automatic installation, set `install_optional_perl_packages = true` in `examples/basic/terraform.tfvars`. This is recommended unless the required Perl dependencies are already installed and managed separately on the target servers.

---

## Installing Terraform

### Ubuntu / Debian

Using the HashiCorp repository:

```bash
sudo apt-get update
sudo apt-get install -y gnupg software-properties-common

wget -O- https://apt.releases.hashicorp.com/gpg | \
  gpg --dearmor | \
  sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update
sudo apt-get install -y terraform

terraform version
```

Install optional deployment tools:

```bash
sudo apt-get install -y sshpass netcat-openbsd
```

### RHEL / CentOS / Fedora

```bash
sudo yum install -y yum-utils

sudo yum-config-manager \
  --add-repo \
  https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

sudo yum install -y terraform

terraform version
```

Install optional deployment tools:

```bash
sudo dnf install -y sshpass nmap-ncat
```

### Direct Download

Example:

```bash
TERRAFORM_VERSION="1.6.0"

wget \
  https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip

unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip

sudo mv terraform /usr/local/bin/

terraform version
```

Check the official Terraform website for the version appropriate for your environment.

---

## Supported Platforms

### Target Hosts

Supported Linux/Unix targets include:

- RHEL 7 / 8 / 9 / 10
- CentOS 7 / 8 / 9
- Oracle Linux 7 / 8 / 9 / 10
- Rocky Linux
- AlmaLinux
- Ubuntu 16.04 / 18.04 / 20.04 / 22.04 / 24.04
- Debian 11 / 12
- SUSE Linux Enterprise Server 12 / 15
- Amazon Linux 2
- Amazon Linux 2023

### Terraform Runner

The Terraform runner requires a Unix-like environment with Bash and SSH tools.

Examples:

- Ubuntu
- RHEL
- CentOS
- Fedora
- macOS

---

Next: [Quick Start](../README.md#quick-start) · [Configuration Reference](configuration.md)
