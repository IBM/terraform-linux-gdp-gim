#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

variable "servers_csv_path" {
  description = "Path to CSV inventory file describing servers to onboard."
  type        = string
}

variable "runner_log_dir" {
  description = "Directory on the Terraform runner (local machine) where per-host logs are written."
  type        = string
  default     = "./logs"
}

variable "unix_packages_root" {
  description = "Path (on the Terraform runner) to the Guardium UNIX packages root, e.g. ./packages/unix"
  type        = string
  default     = "./packages/unix"
}

# Optional explicit kit overrides (recommended only if auto-selection is not desired)
variable "unix_gim_installer_sh_path" {
  description = "Optional path (on the runner) to the GIM .gim.sh installer. If empty, auto-selects from unix_packages_root."
  type        = string
  default     = ""
}

variable "unix_gim_installer_gim_path" {
  description = "Optional path (on the runner) to the GIM .gim bundle (same base name as .gim.sh). If empty, derived or auto-selected."
  type        = string
  default     = ""
}

variable "unix_central_log_path" {
  description = "Optional path (on the runner) to a central CSV summary log. If empty, defaults to <runner_log_dir>/central-summary.csv"
  type        = string
  default     = ""
}

variable "gim_server_port" {
  description = "Guardium management port for GIM. Default: 8446"
  type        = number
  default     = 8446
}

variable "listener_port" {
  description = "Enable GIM listener port. If true, uses default port 8445. If false or not set, listener port is not configured."
  type        = bool
  default     = false
}

variable "unix_perl_path" {
  description = "Optional explicit Perl path on the target host. This module NEVER installs Perl."
  type        = string
  default     = ""
}

variable "install_optional_perl_packages" {
  description = "If true, install optional Perl packages (perl-lib, perl-Sys-Hostname, perl-File-Copy) on RHEL/CentOS targets before GIM. Fixes missing Perl modules on minimal installs. If false, do not install."
  type        = bool
  default     = true
}

variable "uninstall_on_destroy" {
  description = "If true, terraform destroy (or replacing a tainted/changed host) SSHes into the target and runs scripts/uninstall_gim_unix.sh (the vendor uninstall.pl) before removing it from state. If false, destroy only forgets the resource in Terraform state and leaves GIM installed on the target."
  type        = bool
  default     = true
}
