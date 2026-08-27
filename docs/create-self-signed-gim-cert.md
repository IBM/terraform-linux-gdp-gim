# Creating Self-Signed Certificates for GIM

Use these steps to create a self-signed certificate and private key for GIM custom/listener TLS. For GIM you only need **key** and **cert** (no separate CA file).

**Two ways to provide certs:**

- **Copy from Terraform runner (recommended):** Put the PEM files on the machine where you run `terraform apply` (e.g. `./gim-certs/gim-key.pem` and `./gim-certs/gim-cert.pem` under `examples/basic/gim-certs/`). In `servers.csv` set **`gim_key_file_local`** and **`gim_cert_file_local`** to those paths (e.g. `./gim-certs/gim-key.pem`, `./gim-certs/gim-cert.pem`). The install script will copy them to each remote host under `/tmp/gim-certs/` before running the GIM installer. No manual copy to targets needed.
- **Paths on target host:** Place the PEM files on each target host yourself. In `servers.csv` set **`gim_key_file`** and **`gim_cert_file`** to the paths on the target (e.g. `/tmp/gim-certs/gim-key.pem`). Leave `gim_*_file_local` empty.

## Prerequisites

- `openssl` (available on RHEL, Ubuntu, and most Linux/macOS).

## 1. Create a directory (on your machine or on the target)

```bash
mkdir -p /tmp/gim-certs
cd /tmp/gim-certs
```

## 2. Generate a private key (2048-bit RSA)

```bash
openssl genrsa -out gim-key.pem 2048
chmod 600 gim-key.pem
```

## 3. Create a self-signed certificate

GIM mTLS expects certificates that support both **server** and **client** authentication. Use one of the following.

### Option A: Certificate with serverAuth + clientAuth (recommended)

```bash
openssl req -new -x509 -key gim-key.pem -out gim-cert.pem -days 825 -sha256 \
  -subj "/CN=GIM-SelfSigned/O=MyOrg/OU=GIM/L=City/ST=State/C=US" \
  -addext "extendedKeyUsage=serverAuth,clientAuth" \
  -addext "keyUsage=digitalSignature,keyEncipherment,keyAgreement"
```

- **CN** (Common Name): Use a descriptive name (e.g. hostname or `GIM-SelfSigned`).
- **O, OU, L, ST, C**: Adjust or keep as-is.
- **-days 825**: ~2.25 years; change as needed.
- **extendedKeyUsage=serverAuth,clientAuth**: Matches [IBM’s recommendation](https://www.ibm.com/docs/en/gdp/11.5.0?topic=management-creating-managing-custom-gim-certificates) for GIM certs when EKU is used.

### Option B: Minimal (no EKU; some older GIM versions)

```bash
openssl req -new -x509 -key gim-key.pem -out gim-cert.pem -days 825 -sha256 \
  -subj "/CN=GIM-SelfSigned/O=MyOrg/OU=GIM/L=City/ST=State/C=US"
```

## 4. Verify the files

```bash
# Check key
openssl rsa -in gim-key.pem -check -noout

# Check cert and EKU (Option A)
openssl x509 -in gim-cert.pem -noout -text | grep -A1 "Key Usage\|Extended Key Usage"
```

You should see:
- **Key Usage**: Digital Signature, Key Encipherment, Key Agreement (if Option A).
- **Extended Key Usage**: TLS Web Server Authentication, TLS Web Client Authentication (if Option A).

## 5a. Option A – Copy from Terraform runner (script copies to remote)

1. Create a `gim-certs` directory where you run Terraform (e.g. `examples/basic/gim-certs/`).
2. Copy `gim-key.pem` and `gim-cert.pem` there (e.g. `cp gim-key.pem gim-cert.pem /path/to/terraform-guardium-gim-linux-main/examples/basic/gim-certs/`).
3. In `servers.csv` set **gim_key_file_local** and **gim_cert_file_local** to those paths (relative to the Terraform run), and leave **gim_ca_file**, **gim_key_file**, **gim_cert_file** empty for that row:

```csv
...,gim_ca_file,gim_key_file,gim_cert_file,gim_ca_file_local,gim_key_file_local,gim_cert_file_local,...
,,,,,./gim-certs/gim-key.pem,./gim-certs/gim-cert.pem,...
```

The install script will copy the files to each target at `/tmp/gim-certs/` and pass those paths to the GIM installer. No manual copy to targets needed.

## 5b. Option B – Place files on the target host yourself

Copy the PEM files to each target host and set permissions.

**Example: one Red Hat 9 host**

```bash
TARGET_USER=root
TARGET_HOST=your-rhel9-host.example.com
REMOTE_DIR=/etc/guardium

ssh $TARGET_USER@$TARGET_HOST "sudo mkdir -p $REMOTE_DIR && sudo chmod 755 $REMOTE_DIR"
scp gim-key.pem gim-cert.pem $TARGET_USER@$TARGET_HOST:/tmp/
ssh $TARGET_USER@$TARGET_HOST "sudo mv /tmp/gim-key.pem /tmp/gim-cert.pem $REMOTE_DIR/ && sudo chmod 600 $REMOTE_DIR/gim-key.pem && sudo chmod 644 $REMOTE_DIR/gim-cert.pem"
```

After this, on the target you have:
- `$REMOTE_DIR/gim-key.pem` → use as `gim_key_file`
- `$REMOTE_DIR/gim-cert.pem` → use as `gim_cert_file`

## 6. Set paths in `servers.csv`

**Option A (copy from runner):** Use `gim_key_file_local` and `gim_cert_file_local` (paths on the Terraform runner), e.g. `./gim-certs/gim-key.pem`, `./gim-certs/gim-cert.pem`. Leave `gim_ca_file`, `gim_key_file`, `gim_cert_file` empty for that row.

**Option B (paths on target):** For **self-signed**, leave `gim_ca_file` empty and set only key and cert (paths on the target):

```csv
name,os,host,...,gim_ca_file,gim_key_file,gim_cert_file,gim_ca_file_local,gim_key_file_local,gim_cert_file_local,...
rhel9-test,linux,your-rhel9-host.example.com,...,,/etc/guardium/gim-key.pem,/etc/guardium/gim-cert.pem,,,,...
```

So for Option B:
- **gim_ca_file** = empty  
- **gim_key_file** = `/etc/guardium/gim-key.pem` (or whatever path you used)  
- **gim_cert_file** = `/etc/guardium/gim-cert.pem`  
- **gim_*_file_local** = empty

## 7. (Optional) Use the same cert on multiple hosts

- Copy `gim-key.pem` and `gim-cert.pem` to the same path on each host (e.g. `/etc/guardium/`), or
- Use different paths per host and set those paths in each row of `servers.csv`.

## Security notes

- Keep `gim-key.pem` private (e.g. `chmod 600`) and only on hosts that need it.
- Self-signed certs are not trusted by default; they are suitable for testing or controlled environments. For production, consider a private or public CA (see [Creating and managing custom GIM certificates](https://www.ibm.com/docs/en/gdp/11.5.0?topic=management-creating-managing-custom-gim-certificates)).
- Do not commit private keys to git; add `*.pem` or the cert directory to `.gitignore` if storing under the repo.

## Troubleshooting

- **Install fails with cert error**: Ensure both files exist on the target at the exact paths in the CSV and that the GIM installer can read them (e.g. run as root or correct ownership).
- **OpenSSL “unknown option -addext”**: Use Option B, or upgrade OpenSSL to 1.1.1+.
- **Permission denied on key**: On the target, `chmod 600 gim-key.pem` and ensure the user running the GIM install can read the key and cert.
