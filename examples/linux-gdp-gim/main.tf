#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

terraform {
  required_version = ">= 1.5.0"
}

module "linux_gdp_gim" {
  source = "../../modules/linux-gdp-gim"

  servers_csv_path               = var.servers_csv_path
  runner_log_dir                 = var.runner_log_dir
  unix_packages_root             = var.unix_packages_root
  unix_gim_installer_sh_path     = var.unix_gim_installer_sh_path
  unix_gim_installer_gim_path    = var.unix_gim_installer_gim_path
  unix_central_log_path          = var.unix_central_log_path
  gim_server_port                = var.gim_server_port
  listener_port                  = var.listener_port
  unix_perl_path                 = var.unix_perl_path
  install_optional_perl_packages = var.install_optional_perl_packages
  uninstall_on_destroy           = var.uninstall_on_destroy
}
