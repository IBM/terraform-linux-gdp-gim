# Downloading the Guardium Installation Manager (GIM) and S-TAP Agent Packages

*Based on [IBM Documentation — Downloading GIM and S-TAP packages](https://www.ibm.com/docs/en/gdp/12.x?topic=dicgti-downloading-guardium-installation-manager-gim-s-tap-agent-packages) (GDP 12.x).*

You can use the **Guardium® Installation Manager (GIM)** to install and maintain Guardium components on managed servers. The **S-TAP®** agent monitors activity between the client and the database and forwards that information to the Guardium collector.

---

## Before you begin

### Trial users

- This special trial (ISO file) is available for current and potential Db2® customers. **It cannot be used for production purposes.**
- The trial license expires in **90 days** from the point of installation of the license.
- Trial clients can extend their trial for one more period of 90 days by applying for another trial license (with the approval of your IBM representative).
- Previously accepted trial licenses that have expired continue to appear on the license page as accepted licenses.
- **You cannot use a regular Guardium license in addition to this trial appliance.**

---

## Where to get the files

- **Trial:** The files needed for installation are available on the **IBM Guardium Data Protection Trial** page after [signing up for the trial](https://www.ibm.com/docs/en/SSMPHH_12.x/com-ibm-guardium-doc/db2_trial/install/install_download_trial_and_license.html). From that page, download the Guardium Installation Manager (GIM) and S-TAP for your operating system.
- **Other environments:** If you have special requirements, all packages are available at **[IBM Fix Central](https://www.ibm.com/support/fixcentral)**.

---

## Procedure: Download from IBM Fix Central

1. Go to [IBM Fix Central](https://www.ibm.com/support/fixcentral).
2. In the **Find product** tab’s **Product selector** field, enter **IBM Security Guardium**.
3. Click the **Installed Version** menu and select **12.1**.
4. Click the **Platform** menu and select your platform.
5. Click **Continue**.
6. Select **Text** and enter **GIM** in the field, then click **Continue**.
7. In the resulting list of fixes, select the fix pack for your platform and download it.
8. Repeat steps 1 through 5 to return to the same product/version/platform selection.
9. Select **Text** and enter **S-TAP** in the field, then click **Continue**.
10. In the resulting list of fixes, select the S-TAP fix pack for your platform and download it.

---

## Example folder structure

After downloading and extracting the GIM and S-TAP fix packs from IBM Fix Central (or the trial page), place them under `examples/linux-gdp-gim/packages` so the layout matches what the examples expect. Below is the target structure for **Guardium 12.2.1.0** (build `r122289`); version and build numbers may differ for your fix pack.

- **GIM packages** — One directory per platform (Amazon, Debian, RedHat, Suse, Ubuntu). Each contains `GIM_Agents/` (GIM and GUC `.gim`/`.gim.sh` bundles), `MD5SUMS`, and `consolidated_installer.sh`.
- **S-TAP packages** — One directory per platform. Each contains `GIM_Packages/` (S-TAP `.gim`/`.gim.sh`), `Kernel_Signing/`, `Native_Installers/` (e.g. `.rpm` where applicable), `Shell_Installers/`, `Unified_Shell_Installer/`, `MD5SUMS`, and `ktaposmatch.csv`.

```text
examples/linux-gdp-gim/packages
└── unix
    ├── Guardium_12.2.1.0_GIM_Amazon_r122289
    │   ├── GIM_Agents
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2-linux-aarch64.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2-linux-aarch64.gim.sh
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2-linux-aarch64_transitional.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2-linux-aarch64_transitional.gim.sh
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2-linux-x86_64.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2-linux-x86_64.gim.sh
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2-linux-x86_64_transitional.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2-linux-x86_64_transitional.gim.sh
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-aarch64.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-aarch64.gim.sh
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-aarch64_transitional.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-aarch64_transitional.gim.sh
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-x86_64.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-x86_64.gim.sh
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-x86_64_transitional.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-x86_64_transitional.gim.sh
    │   │   ├── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-amzn-2-linux-aarch64.gim
    │   │   ├── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-amzn-2-linux-aarch64.gim.sh
    │   │   ├── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-amzn-2-linux-x86_64.gim
    │   │   ├── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-amzn-2-linux-x86_64.gim.sh
    │   │   ├── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-aarch64.gim
    │   │   ├── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-aarch64.gim.sh
    │   │   ├── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-x86_64.gim
    │   │   └── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-x86_64.gim.sh
    │   ├── MD5SUMS
    │   └── consolidated_installer.sh
    ├── Guardium_12.2.1.0_GIM_Debian_r122289
    │   ├── GIM_Agents
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-debian-11-linux-x86_64.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-debian-11-linux-x86_64.gim.sh
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-debian-11-linux-x86_64_transitional.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-debian-11-linux-x86_64_transitional.gim.sh
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-debian-12-linux-x86_64.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-debian-12-linux-x86_64.gim.sh
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-debian-12-linux-x86_64_transitional.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-debian-12-linux-x86_64_transitional.gim.sh
    │   │   ├── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-debian-11-linux-x86_64.gim
    │   │   ├── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-debian-11-linux-x86_64.gim.sh
    │   │   ├── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-debian-12-linux-x86_64.gim
    │   │   └── guard-bundle-GUC-12.2.1.0_r122289_v12_x_1-debian-12-linux-x86_64.gim.sh
    │   ├── MD5SUMS
    │   └── consolidated_installer.sh
    ├── Guardium_12.2.1.0_GIM_RedHat_r122289
    │   ├── GIM_Agents
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-rhel-10-linux-x86_64.gim
    │   │   ├── guard-bundle-GIM-12.2.1.0_r122289_v12_x_1-rhel-10-linux-x86_64.gim.sh
    │   │   ├── ... (rhel-7/8/9, ppc64/ppc64le/x86_64 GIM and GUC bundles)
    │   ├── MD5SUMS
    │   └── consolidated_installer.sh
    ├── Guardium_12.2.1.0_GIM_Suse_r122289
    │   ├── GIM_Agents
    │   │   ├── ... (suse-12/15, ppc64le/x86_64 GIM and GUC bundles)
    │   ├── MD5SUMS
    │   └── consolidated_installer.sh
    ├── Guardium_12.2.1.0_GIM_Ubuntu_r122289
    │   ├── GIM_Agents
    │   │   ├── ... (ubuntu-16.04 through 24.04, x86_64 GIM and GUC bundles)
    │   ├── MD5SUMS
    │   └── consolidated_installer.sh
    ├── Guardium_12.2.1.0_S-TAP_Amazon_r122289
    │   ├── GIM_Packages
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-amzn-2-linux-aarch64.gim
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-amzn-2-linux-aarch64.gim.sh
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-amzn-2-linux-x86_64.gim
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-amzn-2-linux-x86_64.gim.sh
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-aarch64.gim
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-aarch64.gim.sh
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-x86_64.gim
    │   │   └── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-x86_64.gim.sh
    │   ├── Kernel_Signing
    │   │   └── guardium_module_signing.der
    │   ├── MD5SUMS
    │   ├── Native_Installers
    │   │   ├── guard-stap-12.2.1.0.122289-1-amzn-2-linux-aarch64.aarch64.rpm
    │   │   ├── guard-stap-12.2.1.0.122289-1-amzn-2-linux-x86_64.x86_64.rpm
    │   │   ├── guard-stap-12.2.1.0.122289-1-amzn-2023-linux-aarch64.aarch64.rpm
    │   │   └── guard-stap-12.2.1.0.122289-1-amzn-2023-linux-x86_64.x86_64.rpm
    │   ├── Shell_Installers
    │   │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-amzn-2-linux-aarch64.sh
    │   │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-amzn-2-linux-x86_64.sh
    │   │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-aarch64.sh
    │   │   └── guard-stap-12.2.1.0_r122289_v12_x_1-amzn-2023-linux-x86_64.sh
    │   ├── Unified_Shell_Installer
    │   │   └── guard-stap-12.2.1.0_r122289_v12_x_1-amzn.sh
    │   └── ktaposmatch.csv
    ├── Guardium_12.2.1.0_S-TAP_Debian_r122289
    │   ├── GIM_Packages
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-debian-11-linux-x86_64.gim
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-debian-11-linux-x86_64.gim.sh
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-debian-12-linux-x86_64.gim
    │   │   └── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-debian-12-linux-x86_64.gim.sh
    │   ├── Kernel_Signing
    │   │   └── guardium_module_signing.der
    │   ├── MD5SUMS
    │   ├── Shell_Installers
    │   │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-debian-11-linux-x86_64.sh
    │   │   └── guard-stap-12.2.1.0_r122289_v12_x_1-debian-12-linux-x86_64.sh
    │   ├── Unified_Shell_Installer
    │   │   └── guard-stap-12.2.1.0_r122289_v12_x_1-debian.sh
    │   └── ktaposmatch.csv
    ├── Guardium_12.2.1.0_S-TAP_RedHat_r122289
    │   ├── GIM_Packages
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-rhel-10-linux-x86_64.gim
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-rhel-10-linux-x86_64.gim.sh
    │   │   ├── ... (rhel-7/8/9, ppc64/ppc64le/x86_64)
    │   ├── Kernel_Signing
    │   │   └── guardium_module_signing.der
    │   ├── MD5SUMS
    │   ├── Native_Installers
    │   │   ├── guard-stap-12.2.1.0.122289-1-rhel-10-linux-x86_64.x86_64.rpm
    │   │   ├── ... (rhel-7/8/9 .rpm)
    │   ├── Shell_Installers
    │   │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-rhel-10-linux-x86_64.sh
    │   │   ├── ... (rhel-7/8/9 .sh)
    │   ├── Unified_Shell_Installer
    │   │   └── guard-stap-12.2.1.0_r122289_v12_x_1-rhel.sh
    │   └── ktaposmatch.csv
    ├── Guardium_12.2.1.0_S-TAP_Suse_r122289
    │   ├── GIM_Packages
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-suse-12-linux-ppc64le.gim
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-suse-12-linux-ppc64le.gim.sh
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-suse-12-linux-x86_64.gim
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-suse-12-linux-x86_64.gim.sh
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-suse-15-linux-ppc64le.gim
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-suse-15-linux-ppc64le.gim.sh
    │   │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-suse-15-linux-x86_64.gim
    │   │   └── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-suse-15-linux-x86_64.gim.sh
    │   ├── Kernel_Signing
    │   │   ├── guardium_module_signing.der
    │   │   └── guardium_module_signing_suse15.der
    │   ├── MD5SUMS
    │   ├── Native_Installers
    │   │   ├── guard-stap-12.2.1.0.122289-1-suse-12-linux-ppc64le.ppc64le.rpm
    │   │   ├── guard-stap-12.2.1.0.122289-1-suse-12-linux-x86_64.x86_64.rpm
    │   │   ├── guard-stap-12.2.1.0.122289-1-suse-15-linux-ppc64le.ppc64le.rpm
    │   │   └── guard-stap-12.2.1.0.122289-1-suse-15-linux-x86_64.x86_64.rpm
    │   ├── Shell_Installers
    │   │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-suse-12-linux-ppc64le.sh
    │   │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-suse-12-linux-x86_64.sh
    │   │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-suse-15-linux-ppc64le.sh
    │   │   └── guard-stap-12.2.1.0_r122289_v12_x_1-suse-15-linux-x86_64.sh
    │   ├── Unified_Shell_Installer
    │   │   └── guard-stap-12.2.1.0_r122289_v12_x_1-suse.sh
    │   └── ktaposmatch.csv
    └── Guardium_12.2.1.0_S-TAP_Ubuntu_r122289
        ├── GIM_Packages
        │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-ubuntu-16.04-linux-x86_64.gim
        │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-ubuntu-16.04-linux-x86_64.gim.sh
        │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-ubuntu-18.04-linux-x86_64.gim
        │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-ubuntu-18.04-linux-x86_64.gim.sh
        │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-ubuntu-20.04-linux-x86_64.gim
        │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-ubuntu-20.04-linux-x86_64.gim.sh
        │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-ubuntu-22.04-linux-x86_64.gim
        │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-ubuntu-22.04-linux-x86_64.gim.sh
        │   ├── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-ubuntu-24.04-linux-x86_64.gim
        │   └── guard-bundle-STAP-12.2.1.0_r122289_v12_x_1-ubuntu-24.04-linux-x86_64.gim.sh
        ├── Kernel_Signing
        │   └── guardium_module_signing.der
        ├── MD5SUMS
        ├── Shell_Installers
        │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-ubuntu-16.04-linux-x86_64.sh
        │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-ubuntu-18.04-linux-x86_64.sh
        │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-ubuntu-20.04-linux-x86_64.sh
        │   ├── guard-stap-12.2.1.0_r122289_v12_x_1-ubuntu-22.04-linux-x86_64.sh
        │   └── guard-stap-12.2.1.0_r122289_v12_x_1-ubuntu-24.04-linux-x86_64.sh
        ├── Unified_Shell_Installer
        │   └── guard-stap-12.2.1.0_r122289_v12_x_1-ubuntu.sh
        └── ktaposmatch.csv
```

For a given OS (e.g. Red Hat or Ubuntu), download and extract the matching **GIM** and **S-TAP** fix packs from Fix Central, then place their extracted folders under `examples/linux-gdp-gim/packages/unix/` so the path matches the structure above. You only need the platforms you use; the basic example may reference a specific path such as `Guardium_12.2.1.0_GIM_RedHat_r122289` or the corresponding S-TAP folder.

---

## Related tasks

- **Installing the GIM client and S-TAP agent** — Use the consolidated installer to install the GIM client and S-TAP agent on the database server in a one-step process.
- **Configuring the inspection engine for Db2** — The Db2 inspection engine extracts SQL from network packets, compiles parse trees, and logs detailed information about traffic to the internal database.
- **Configuring Db2 Exit** — The Db2 Exit module enables S-TAP to monitor Db2 database activities (encrypted or not, local or remote).
- **Testing the agents** — Follow IBM’s instructions to verify connectivity to a sample database and run an SQL query.

---

*Last updated: 2026-02-19. Documentation version: 12.x.*
