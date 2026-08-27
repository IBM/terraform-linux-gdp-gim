# Usage

## Table of Contents

- [Basic Installation](#basic-installation)
- [Re-run an Installation](#re-run-an-installation)
- [View Terraform State](#view-terraform-state)
- [Logging](#logging)
- [Uninstalling and Cleanup](#uninstalling-and-cleanup)

---

## Basic Installation

```bash
cd examples/basic

terraform init
terraform plan
terraform apply
```

## Re-run an Installation

If a Terraform resource must be recreated:

```bash
terraform taint 'null_resource.install_gim_unix["server-name"]'

terraform apply
```

For newer Terraform workflows, resource replacement can also be requested during planning/apply when appropriate.

## View Terraform State

```bash
terraform state list
```

```bash
terraform show
```

---

## Logging

Each host receives its own installation log, for example `logs/server1.log`.

Supported log levels include:

- `INFO`
- `WARN`
- `ERROR`
- `SUCCESS`
- `DEBUG`

Example:

```text
[2026-02-12T14:30:00Z] [INFO] Starting installation on server1.example.com
[2026-02-12T14:30:01Z] [SUCCESS] SSH connection test successful
[2026-02-12T14:30:02Z] [WARN] GIM server 10.80.59.145:8446 is not reachable
[2026-02-12T14:30:45Z] [ERROR] Failed to copy installer kit to remote host
```

### Automatic Guardium Debug Log Collection

After each installation attempt, the script retrieves:

```text
<install_dir>/modules/central_logger.log
```

and the active GIM log:

```text
<install_dir>/modules/GIM/<version>/GIM.log
```

### Central Summary

Default location:

```text
logs/central-summary.csv
```

Possible statuses include:

```text
SUCCESS
FAILED
SKIPPED
WARNING
```

The default path can be overridden with `unix_central_log_path` — see [Advanced Configuration](advanced-configuration.md#central-log-path).

---

## Uninstalling and Cleanup

### Automatic Cleanup with Terraform Destroy

By default:

```hcl
uninstall_on_destroy = true
```

Running:

```bash
terraform destroy
```

causes Terraform to connect to the target and invoke the GIM uninstall workflow before removing the resource from Terraform state.

Set:

```hcl
uninstall_on_destroy = false
```

if you want Terraform to remove the resource from state without uninstalling GIM.

### Manual Uninstall

Example using password authentication:

```bash
cd examples/basic

bash ../../scripts/unix/uninstall_gim_unix.sh \
  --host "server.example.com" \
  --username "root" \
  --password "your-password" \
  --use-sudo "false" \
  --install-dir "/usr/local/guardium" \
  --log-file "./logs/uninstall-server.log"
```

Example using SSH-key authentication:

```bash
bash ../../scripts/unix/uninstall_gim_unix.sh \
  --host "server.example.com" \
  --username "admin" \
  --pem-key "/home/admin/.ssh/id_rsa" \
  --use-sudo "true" \
  --install-dir "/usr/local/guardium" \
  --log-file "./logs/uninstall-server.log"
```

### Uninstall Script Behavior

The script:

1. Detects the installed GIM instance.
2. Locates IBM's `uninstall.pl`.
3. Runs the IBM vendor uninstaller.
4. Stops/disables leftover `guard_gim` services when necessary.
5. Removes temporary installation files.
6. Preserves useful Guardium logs for troubleshooting.
7. Writes an uninstall log.

---

Next: [Troubleshooting](troubleshooting.md) · [Security Considerations](security.md)
