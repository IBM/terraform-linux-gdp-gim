#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

output "parsed_servers" {
  description = "Inventory parsed from CSV (sanitized: password omitted). Useful for debugging."
  value = {
    for k, s in local.unix_servers : k => {
      name                     = s.name
      os                       = s.os
      host                     = s.host
      mgmt_port                = s.mgmt_port
      username                 = s.username
      gim_server_host          = s.gim_server_host
      install_dir              = try(s.install_dir, "/usr/local/guardium")
      shared_secret_set        = (trimspace(try(s.shared_secret, "")) != "")
      failover_gim_server_host = try(s.failover_gim_server_host, "")
      local_ip                 = try(s.local_ip, "")
      gim_kit_version          = try(s.gim_kit_version, "")
    }
  }
  sensitive = false
}

output "log_directory" {
  description = "Directory on the Terraform runner where per-host logs are written."
  value       = var.runner_log_dir
}

output "central_log_file" {
  description = "Path to the central deployment summary CSV log file."
  value       = local.central_log
}
