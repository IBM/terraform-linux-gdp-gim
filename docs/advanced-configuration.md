# Advanced Configuration

This page covers configuration that goes beyond the basics in the [Configuration Reference](configuration.md): custom TLS certificates, pinning a specific GIM kit version, passwordless sudo setup, overriding the central log path, and platform-specific notes.

## Table of Contents

- [Custom TLS Certificates](#custom-tls-certificates)
- [GIM Kit Version Pinning](#gim-kit-version-pinning)
- [Passwordless Sudo](#passwordless-sudo)
- [Central Log Path](#central-log-path)
- [Platform-Specific Notes](#platform-specific-notes)

---

## Custom TLS Certificates

Two certificate-deployment methods are supported. Do **not** configure both approaches for the same server.

### Option 1 — Certificates Already Exist on the Target Host

Use:

```text
gim_ca_file
gim_key_file
gim_cert_file
```

The files must exist before Terraform starts the installation.

`gim_key_file` and `gim_cert_file` should be provided together. `gim_ca_file` can be omitted when appropriate for self-signed configurations.

### Option 2 — Certificates Stored on the Terraform Runner

Use:

```text
gim_ca_file_local
gim_key_file_local
gim_cert_file_local
```

Recommended directory:

```text
examples/basic/gim-certs/
├── gim-key.pem
├── gim-cert.pem
└── gim-ca.pem
```

The script stages the files through the SSH user's home directory and copies them into:

```text
<install_dir>/.gim-certs/
```

Example:

```text
/usr/local/guardium/.gim-certs/
```

See [Creating self-signed certificates](create-self-signed-gim-cert.md) for step-by-step instructions, and the IBM documentation for GIM server allocation.

---

## GIM Kit Version Pinning

If `packages/unix` contains multiple compatible GIM kits, automatic alphabetical selection may not correspond to the newest release.

Use the `gim_kit_version` CSV column to explicitly select a kit:

```text
gim_kit_version
```

Example values:

```text
r123489
12.2.2.0
```

The value is matched against the installer directory or filename. If no matching kit is found, installation fails with a clear error.

---

## Passwordless Sudo

For non-root users, set `use_sudo = TRUE` in `servers.csv` (see [Authentication](configuration.md#authentication)).

Example sudoers rule:

```text
username ALL=(ALL) NOPASSWD: ALL
```

Test:

```bash
ssh username@hostname "sudo whoami"
```

Expected:

```text
root
```

---

## Central Log Path

Override the default central-summary location:

```hcl
unix_central_log_path = "./logs/central-summary.csv"
```

See [Logging](usage.md#logging) for details on what the central summary contains.

---

## Platform-Specific Notes

### AWS EC2

#### Authentication

SSH-key authentication is recommended.

Example:

```csv
poc-redhat-v8,linux,poc-redhat-v8.dev.my.domain.com,22,danny,,TRUE,/home/danny/.ssh/dan.pem,10.80.59.145,10.60.193.231,/usr/local/guardium,,,,,,,,,,0,TRUE,FALSE,r123268
```

Use either:

```text
~/.ssh/dan.pem
```

or:

```text
/home/danny/.ssh/dan.pem
```

Do not combine `~` with `/home/...`.

#### Security Groups

**Inbound** — Allow SSH from the Terraform runner:

```text
TCP 22
Source: <Terraform-Runner-IP>/32
```

**Outbound** — Allow target-host connectivity to Guardium:

```text
TCP 8446 → <Guardium-IP>/32
```

If listener mode is enabled:

```text
TCP 8445 → <Guardium-IP>/32
```

If required by your Guardium configuration:

```text
TCP 8443 → <Guardium-IP>/32
```

Test:

```bash
nc -zv <guardium-ip> 8446
```

### Amazon Linux

Amazon Linux 2 and Amazon Linux 2023 are supported.

Typical username:

```text
ec2-user
```

Recommended:

```text
use_sudo = TRUE
```

with SSH-key authentication.

### RHEL / CentOS

When:

```hcl
install_optional_perl_packages = true
```

the script can install required modules automatically.

### Ubuntu / Debian

Install required Perl dependencies manually if necessary:

```bash
sudo apt-get update
sudo apt-get install -y perl perl-modules
```

### SLES

SLES 12 and 15 can use supported SUSE GIM kits.

#### SLES 16

SLES 16 is not currently supported. A `suse-15` kit cannot be used as a replacement because the IBM installer validates the distribution vendor version and rejects the mismatch.

---

Next: [Architecture](architecture.md) · [Troubleshooting](troubleshooting.md)
