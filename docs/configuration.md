# Configuration Reference

Configuration is split between two files under `examples/linux-gdp-gim/`:

- **`terraform.tfvars`** — global deployment configuration
- **`inventory/servers.csv`** — per-host configuration

## Table of Contents

- [Terraform Variables](#terraform-variables)
- [Inventory CSV Format](#inventory-csv-format)
- [Authentication](#authentication)
- [GIM Ports](#gim-ports)

---

## Terraform Variables

Defined in `examples/linux-gdp-gim/variables.tf` and set in `examples/linux-gdp-gim/terraform.tfvars`.

### Required Variables

| Variable | Description | Example |
|---|---|---|
| `servers_csv_path` | Path to the host inventory | `"./inventory/servers.csv"` |
| `unix_packages_root` | Root directory containing GIM packages | `"./packages/unix"` |

### Optional Variables

| Variable | Description | Default |
|---|---|---|
| `gim_server_port` | Guardium GIM communication port | `8446` |
| `listener_port` | Enable listener port `8445` | `false` |
| `install_optional_perl_packages` | Install optional Perl dependencies | `true` |
| `runner_log_dir` | Directory for local deployment logs | `"./logs"` |
| `unix_central_log_path` | Central CSV deployment log | `<runner_log_dir>/central-summary.csv` |
| `uninstall_on_destroy` | Run GIM uninstall before Terraform removes the resource | `true` |
| `unix_gim_installer_sh_path` | Explicit path to a `.gim.sh` installer, bypassing auto-selection | Auto-selected from `unix_packages_root` |
| `unix_gim_installer_gim_path` | Explicit path to the matching `.gim` bundle | Auto-selected from `unix_packages_root` |
| `unix_perl_path` | Explicit Perl path on the target host (the module never installs Perl itself) | Auto-detected |

---

## Inventory CSV Format

Each row in `servers.csv` represents one target host.

### Complete Header

```csv
name,os,host,mgmt_port,username,password,use_sudo,pem_key_path,gim_server_host,local_ip,install_dir,perl_path,shared_secret,failover_gim_server_host,gim_ca_file,gim_key_file,gim_cert_file,gim_ca_file_local,gim_key_file_local,gim_cert_file_local,auto_assign_ip,check_8443,allow_tls_fallback,gim_kit_version
```

### Required Host Fields

| Column | Description | Example |
|---|---|---|
| `name` | Unique server identifier | `prod-db-01` |
| `os` | `linux` or `unix` | `linux` |
| `host` | Target hostname or IP | `server.example.com` |
| `mgmt_port` | SSH port | `22` |
| `username` | SSH username | `root` |
| `gim_server_host` | Guardium server hostname/IP | `10.80.59.145` |

### Authentication Fields

At least one SSH authentication method must be configured. Leave the unused field empty.

| Column | Description |
|---|---|
| `password` | SSH password |
| `pem_key_path` | Path to SSH private key on the Terraform runner |

See [Authentication](#authentication) below for full examples.

### Optional Host Fields

| Column | Description | Default / Behavior |
|---|---|---|
| `use_sudo` | Use sudo for privileged operations | `FALSE` |
| `local_ip` | IPv4 address for `CLIENT_IP` / `--tapip` | Auto-detected |
| `install_dir` | GIM installation directory | `/usr/local/guardium` |
| `perl_path` | Custom Perl executable | Auto-detected |
| `failover_gim_server_host` | Secondary Guardium server | Not configured |
| `shared_secret` | Shared secret for GIM authentication | Not configured |
| `gim_ca_file` | CA certificate already on target | Not configured |
| `gim_key_file` | Private key already on target | Not configured |
| `gim_cert_file` | Certificate already on target | Not configured |
| `gim_ca_file_local` | CA certificate on Terraform runner | Not configured |
| `gim_key_file_local` | Private key on Terraform runner | Not configured |
| `gim_cert_file_local` | Certificate on Terraform runner | Not configured |
| `gim_kit_version` | Kit-version selector | Automatic selection |

See [Advanced Configuration](advanced-configuration.md) for TLS certificate setup and kit-version pinning details.

### Reserved Columns

The following fields are currently retained for compatibility/future functionality:

- `auto_assign_ip`
- `check_8443`
- `allow_tls_fallback`

They can remain empty unless your implementation adds support for them.

---

## Authentication

### Password Authentication

Example:

```csv
server1,linux,server1.example.com,22,root,MyPassword123,FALSE,,10.80.59.145,...
```

### SSH Key Authentication

Example:

```csv
server1,linux,server1.example.com,22,admin,,TRUE,/home/admin/.ssh/id_rsa,10.80.59.145,...
```

Recommended private-key permissions:

```bash
chmod 600 /home/admin/.ssh/id_rsa
```

### Sudo Users

If the SSH account is not root:

```text
use_sudo = TRUE
```

Passwordless sudo must be configured on the target server. See [Advanced Configuration](advanced-configuration.md#passwordless-sudo) for setup and testing steps.

---

## GIM Ports

GIM port configuration is global and belongs in `terraform.tfvars`.

| Setting | Default | Purpose |
|---|---:|---|
| `gim_server_port` | `8446` | Communication with the Guardium appliance |
| `listener_port` | `false` | Enables GIM listener port `8445` when set to `true` |

Example:

```hcl
gim_server_port = 8446
listener_port   = false
```

When `listener_port = true`, the installer receives:

```text
--listener-port 8445
```

When `listener_port = false`, the listener-port argument is not passed.

---

Next: [Advanced Configuration](advanced-configuration.md) · [Usage](usage.md)
