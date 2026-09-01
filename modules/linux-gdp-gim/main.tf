#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

terraform {
  required_version = ">= 1.5.0"
}

locals {
  servers_raw = csvdecode(file(var.servers_csv_path))

  unix_servers = {
    for s in local.servers_raw : s.name => s
    if lower(trimspace(s.os)) == "linux" || lower(trimspace(s.os)) == "unix"
  }

  central_log = (
    trimspace(var.unix_central_log_path) != ""
    ? var.unix_central_log_path
    : "${var.runner_log_dir}/central-summary.csv"
  )

  listener_port_arg = var.listener_port ? "--listener-port \"8445\"" : ""
  failover_gim_server_args = {
    for k, v in local.unix_servers : k => trimspace(try(v.failover_gim_server_host, "")) != "" ? "--failover-gim-server \"${v.failover_gim_server_host}\"" : ""
  }
  shared_secret_args = {
    for k, v in local.unix_servers : k => trimspace(try(v.shared_secret, "")) != "" ? "--shared-secret \"${v.shared_secret}\"" : ""
  }
  gim_ca_file_args = {
    for k, v in local.unix_servers : k => trimspace(try(v.gim_ca_file, "")) != "" ? "--ca-file \"${v.gim_ca_file}\"" : ""
  }
  gim_key_file_args = {
    for k, v in local.unix_servers : k => trimspace(try(v.gim_key_file, "")) != "" ? "--key-file \"${v.gim_key_file}\"" : ""
  }
  gim_cert_file_args = {
    for k, v in local.unix_servers : k => trimspace(try(v.gim_cert_file, "")) != "" ? "--cert-file \"${v.gim_cert_file}\"" : ""
  }
  gim_kit_version_args = {
    for k, v in local.unix_servers : k => trimspace(try(v.gim_kit_version, "")) != "" ? "--kit-version \"${v.gim_kit_version}\"" : ""
  }
  local_ip_args = {
    for k, v in local.unix_servers : k => trimspace(try(v.local_ip, "")) != "" ? "--local-ip \"${v.local_ip}\"" : ""
  }
  # Paths on Terraform runner; resolve relative paths (e.g. ./certs/...) against path.module so they work regardless of cwd
  _resolve_local_path = {
    for k, v in local.unix_servers : k => {
      ca   = trimspace(try(v.gim_ca_file_local, ""))
      key  = trimspace(try(v.gim_key_file_local, ""))
      cert = trimspace(try(v.gim_cert_file_local, ""))
    }
  }
  _resolved_gim_ca_file_local = {
    for k, v in local._resolve_local_path : k => v.ca != "" ? (startswith(v.ca, "/") ? v.ca : "${path.root}/${replace(v.ca, "./", "")}") : ""
  }
  _resolved_gim_key_file_local = {
    for k, v in local._resolve_local_path : k => v.key != "" ? (startswith(v.key, "/") ? v.key : "${path.root}/${replace(v.key, "./", "")}") : ""
  }
  _resolved_gim_cert_file_local = {
    for k, v in local._resolve_local_path : k => v.cert != "" ? (startswith(v.cert, "/") ? v.cert : "${path.root}/${replace(v.cert, "./", "")}") : ""
  }
  gim_ca_file_local_args = {
    for k, v in local.unix_servers : k => local._resolved_gim_ca_file_local[k] != "" ? "--ca-file-local \"${local._resolved_gim_ca_file_local[k]}\"" : ""
  }
  gim_key_file_local_args = {
    for k, v in local.unix_servers : k => local._resolved_gim_key_file_local[k] != "" ? "--key-file-local \"${local._resolved_gim_key_file_local[k]}\"" : ""
  }
  gim_cert_file_local_args = {
    for k, v in local.unix_servers : k => local._resolved_gim_cert_file_local[k] != "" ? "--cert-file-local \"${local._resolved_gim_cert_file_local[k]}\"" : ""
  }
}

############################
# UNIX / LINUX – GIM
############################
resource "null_resource" "install_gim_unix" {
  for_each = local.unix_servers

  triggers = {
    host                       = each.value.host
    mgmt_port                  = tostring(each.value.mgmt_port)
    username                   = each.value.username
    password                   = try(each.value.password, "")
    use_sudo                   = try(each.value.use_sudo, "false")
    pem_key_path               = try(each.value.pem_key_path, "")
    gim_server_host            = each.value.gim_server_host
    gim_server_port            = var.gim_server_port
    listener_port              = var.listener_port
    failover_gim_server_host   = try(each.value.failover_gim_server_host, "")
    shared_secret              = try(each.value.shared_secret, "")
    install_dir                = try(each.value.install_dir, "/usr/local/guardium")
    gim_kit_version            = try(each.value.gim_kit_version, "")
    local_ip                   = try(each.value.local_ip, "")
    packages_root              = var.unix_packages_root
    script_hash                = filesha256("${path.module}/../../scripts/install_gim_unix.sh")
    install_optional_perl_pkgs = tostring(var.install_optional_perl_packages)
    # Destroy-time provisioners may only reference `self`/`count.index`/`each.key` - not
    # var.* or path.module directly - so anything the destroy provisioner below needs
    # must be threaded through here too.
    module_path          = path.module
    runner_log_dir       = var.runner_log_dir
    uninstall_on_destroy = tostring(var.uninstall_on_destroy)
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]

    command = <<EOT
set -e
mkdir -p "${var.runner_log_dir}"
LOG_FILE="${var.runner_log_dir}/${each.key}.log"

bash "${path.module}/../../scripts/install_gim_unix.sh" \
  --host "${each.value.host}" \
  --mgmt-port "${each.value.mgmt_port}" \
  --username "${each.value.username}" \
  --password "${try(each.value.password, "")}" \
  --use-sudo "${lower(try(each.value.use_sudo, "false"))}" \
  --pem-key "${try(each.value.pem_key_path, "")}" \
  --gim-server "${each.value.gim_server_host}" \
  --gim-server-port "${var.gim_server_port}" \
  --install-dir "${try(each.value.install_dir, "/usr/local/guardium")}" \
${local.listener_port_arg != "" ? "  ${local.listener_port_arg} \\\n" : ""}${local.failover_gim_server_args[each.key] != "" ? "  ${local.failover_gim_server_args[each.key]} \\\n" : ""}${local.shared_secret_args[each.key] != "" ? "  ${local.shared_secret_args[each.key]} \\\n" : ""}${local.gim_ca_file_args[each.key] != "" ? "  ${local.gim_ca_file_args[each.key]} \\\n" : ""}${local.gim_key_file_args[each.key] != "" ? "  ${local.gim_key_file_args[each.key]} \\\n" : ""}${local.gim_cert_file_args[each.key] != "" ? "  ${local.gim_cert_file_args[each.key]} \\\n" : ""}${local.gim_ca_file_local_args[each.key] != "" ? "  ${local.gim_ca_file_local_args[each.key]} \\\n" : ""}${local.gim_key_file_local_args[each.key] != "" ? "  ${local.gim_key_file_local_args[each.key]} \\\n" : ""}${local.gim_cert_file_local_args[each.key] != "" ? "  ${local.gim_cert_file_local_args[each.key]} \\\n" : ""}${local.gim_kit_version_args[each.key] != "" ? "  ${local.gim_kit_version_args[each.key]} \\\n" : ""}${local.local_ip_args[each.key] != "" ? "  ${local.local_ip_args[each.key]} \\\n" : ""}  --packages-root "${var.unix_packages_root}" \
  --log-file "$${LOG_FILE}" \
  --central-log "${local.central_log}" \
  --skip-if-installed "true" \
  --install-optional-perl-packages "${var.install_optional_perl_packages}"
EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["/bin/bash", "-c"]

    command = <<EOT
set -e
if [[ "${self.triggers.uninstall_on_destroy}" != "true" ]]; then
  echo "uninstall_on_destroy=false; skipping remote GIM uninstall for ${self.triggers.host}"
  exit 0
fi
mkdir -p "${self.triggers.runner_log_dir}"
LOG_FILE="${self.triggers.runner_log_dir}/${self.triggers.host}-uninstall.log"

bash "${self.triggers.module_path}/../../scripts/uninstall_gim_unix.sh" \
  --host "${self.triggers.host}" \
  --mgmt-port "${self.triggers.mgmt_port}" \
  --username "${self.triggers.username}" \
  --password "${self.triggers.password}" \
  --use-sudo "${lower(self.triggers.use_sudo)}" \
  --pem-key "${self.triggers.pem_key_path}" \
  --install-dir "${self.triggers.install_dir}" \
  --log-file "$${LOG_FILE}"
EOT
  }
}
