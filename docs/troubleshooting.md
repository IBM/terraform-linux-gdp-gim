# Troubleshooting

## No Matching GIM Kit Found

Verify that the package directory contains a kit compatible with the target operating system and architecture.

## Multiple GIM Kits Match the Same Host

Set `gim_kit_version` explicitly to select the intended kit. See [GIM Kit Version Pinning](advanced-configuration.md#gim-kit-version-pinning).

## sshpass: command not found

Ubuntu / Debian:

```bash
sudo apt-get install -y sshpass
```

RHEL / CentOS:

```bash
sudo dnf install -y sshpass
```

macOS:

```bash
brew install sshpass
```

## Missing Perl Modules

Enable:

```hcl
install_optional_perl_packages = true
```

or install the required Perl packages manually. See [Optional Perl Dependencies](installation.md#optional-perl-dependencies).

## Failed Sending REGISTER Message / Cannot Connect to sqlguard

Test:

```bash
nc -zv <guardium-ip> 8446
```

Check:

1. Host firewall.
2. Cloud security groups.
3. Network ACLs.
4. Routing.
5. VPN/private-network paths.
6. Guardium-side firewall.
7. Guardium service availability.
8. Correct `gim_server_host`.
9. Correct `gim_server_port`.

## Before Opening an Issue

1. Review the sections above.
2. Review the host-specific log (`logs/<host>.log`).
3. Review `<host>_central_logger.log`.
4. Review `<host>_GIM.log`.
5. Test SSH connectivity manually.
6. Test Guardium port connectivity manually.

See [Logging](usage.md#logging) for where these files are written. Maintainer information is available in [MAINTAINERS.md](../MAINTAINERS.md).

---

Next: [Security Considerations](security.md) · [Architecture](architecture.md)
