#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

variable "inventory_csv_path" {
  description = "Path to servers.csv inventory file."
  type        = string
}

variable "runner_log_dir" {
  description = "Directory on the Terraform runner where per-host logs will be written."
  type        = string
  default     = "./logs"
}

variable "ssh_private_key_path" {
  description = "Optional SSH private key path used for UNIX/Linux targets. If null/empty, password auth (sshpass) is used."
  type        = string
  default     = null
}

variable "gim_ports" {
  description = "Ports to validate from target server to Guardium appliance (typical: 8446 and optionally 8443/8445)."
  type        = list(number)
  default     = [8446, 8443]
}

# -----------------------------
# UNIX / Linux installers (Option B)
# -----------------------------
variable "unix_gim_installer_sh_path" {
  description = "Path on the Terraform runner to the extracted Guardium GIM installer .gim.sh (platform-specific)."
  type        = string
}

variable "unix_gim_installer_gim_path" {
  description = "Path on the Terraform runner to the extracted Guardium GIM bundle .gim file (platform-specific)."
  type        = string
}

variable "install_stap" {
  description = "If true, also install S-TAP (requires STAP installer paths)."
  type        = bool
  default     = false
}

variable "unix_stap_installer_sh_path" {
  description = "Path on the Terraform runner to the extracted S-TAP installer .gim.sh for the target platform. Required if install_stap=true."
  type        = string
  default     = ""
}

variable "unix_stap_installer_gim_path" {
  description = "Path on the Terraform runner to the extracted S-TAP bundle .gim file for the target platform. Required if install_stap=true."
  type        = string
  default     = ""
}

