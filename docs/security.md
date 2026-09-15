# Security Considerations

## Never Commit Credentials

Do not commit real:

- Passwords
- Shared secrets
- Private keys
- Production certificates
- Terraform state containing credentials

Recommended `.gitignore` entries:

```gitignore
terraform.tfvars
*.tfstate
*.tfstate.*
examples/linux-gdp-gim/inventory/servers.csv
examples/linux-gdp-gim/logs/
examples/linux-gdp-gim/gim-certs/*.pem
```

Keep `.example` templates under version control instead.

## Prefer SSH Keys

Generate a key:

```bash
ssh-keygen -t ed25519
```

Protect the private key:

```bash
chmod 600 ~/.ssh/id_ed25519
```

See [SSH Key Authentication](configuration.md#ssh-key-authentication) for how to reference the key in `servers.csv`.

## Network Security

Recommended:

- Prefer private networking.
- Restrict SSH to trusted source IP addresses.
- Avoid `0.0.0.0/0` SSH rules.
- Restrict Guardium ports to required destinations.
- Use VPN/private connectivity where possible.

---

Next: [Troubleshooting](troubleshooting.md) · [Advanced Configuration](advanced-configuration.md)
