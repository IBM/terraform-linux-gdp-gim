#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

output "parsed_servers" {
  description = "Inventory parsed from CSV (sanitized: password omitted). Useful for debugging."
  value       = module.linux_gdp_gim.parsed_servers
  sensitive   = false
}

output "log_directory" {
  description = "Directory on the Terraform runner where per-host logs are written."
  value       = module.linux_gdp_gim.log_directory
}

output "central_log_file" {
  description = "Path to the central deployment summary CSV log file."
  value       = module.linux_gdp_gim.central_log_file
}
