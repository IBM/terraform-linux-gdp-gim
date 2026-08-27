#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

locals {
  csv_lines_raw = [
    for l in split("\n", trimspace(file(var.inventory_csv_path))) :
    trimspace(l) if trimspace(l) != ""
  ]

  header_raw = [for h in split(",", local.csv_lines_raw[0]) : trimspace(h)]

  # Normalize header names (handles Excel BOM and case)
  header = [
    for h in local.header_raw :
    replace(lower(trimspace(h)), "\ufeff", "")
  ]

  rows = [
    for r in slice(local.csv_lines_raw, 1, length(local.csv_lines_raw)) :
    [
      for c in split(",", r) :
      (
        # Trim and strip optional surrounding double-quotes (common in CSV exports)
        # Implemented without regexreplace for compatibility.
        (
          startswith(trimspace(c), "\"") && endswith(trimspace(c), "\"") && length(trimspace(c)) >= 2
        )
        ? trimsuffix(trimprefix(trimspace(c), "\""), "\"")
        : trimspace(c)
      )
    ]
  ]
  idx = { for i, v in local.header : v => i }

  # Full schema supported (empty values use defaults):
  # Required columns:
  #   name, os, host, mgmt_port, username, password, gim_server_host, gim_server_port, local_ip
  # Optional columns:
  #   install_dir, perl_path, listener_port, shared_secret, failover_gim_server_host,
  #   gim_ca_file, gim_key_file, gim_cert_file (paths on target) OR gim_ca_file_local, gim_key_file_local, gim_cert_file_local (paths on runner; script copies to target),
  #   auto_assign_ip, check_8443, allow_tls_fallback

  servers = {
    for r in local.rows :
    r[local.idx["name"]] => {
      name = r[local.idx["name"]]
      os   = lower(r[local.idx["os"]])
      host = r[local.idx["host"]]

      mgmt_port = tonumber(
        (
          (contains(keys(local.idx), "mgmt_port") && r[local.idx["mgmt_port"]] != "")
          ? r[local.idx["mgmt_port"]]
          : "22"
        )
      )

      username = r[local.idx["username"]]
      password = r[local.idx["password"]]

      gim_server_host = r[local.idx["gim_server_host"]]

      gim_server_port = tonumber(
        (
          (contains(keys(local.idx), "gim_server_port") && r[local.idx["gim_server_port"]] != "")
          ? r[local.idx["gim_server_port"]]
          : "8446"
        )
      )

      local_ip = (
        (contains(keys(local.idx), "local_ip") && r[local.idx["local_ip"]] != "")
        ? r[local.idx["local_ip"]]
        : r[local.idx["host"]]
      )

      install_dir = (
        (contains(keys(local.idx), "install_dir") && r[local.idx["install_dir"]] != "")
        ? r[local.idx["install_dir"]]
        : "/usr/local/guardium"
      )

      perl_path = (
        (contains(keys(local.idx), "perl_path") && r[local.idx["perl_path"]] != "")
        ? r[local.idx["perl_path"]]
        : ""
      )

      listener_port = tonumber(
        (
          (contains(keys(local.idx), "listener_port") && r[local.idx["listener_port"]] != "")
          ? r[local.idx["listener_port"]]
          : "8445"
        )
      )

      shared_secret = (
        (contains(keys(local.idx), "shared_secret") && r[local.idx["shared_secret"]] != "")
        ? r[local.idx["shared_secret"]]
        : ""
      )

      failover_gim_server_host = (
        (contains(keys(local.idx), "failover_gim_server_host") && r[local.idx["failover_gim_server_host"]] != "")
        ? r[local.idx["failover_gim_server_host"]]
        : ""
      )

      gim_ca_file = (
        (contains(keys(local.idx), "gim_ca_file") && r[local.idx["gim_ca_file"]] != "")
        ? r[local.idx["gim_ca_file"]]
        : ""
      )
      gim_key_file = (
        (contains(keys(local.idx), "gim_key_file") && r[local.idx["gim_key_file"]] != "")
        ? r[local.idx["gim_key_file"]]
        : ""
      )
      gim_cert_file = (
        (contains(keys(local.idx), "gim_cert_file") && r[local.idx["gim_cert_file"]] != "")
        ? r[local.idx["gim_cert_file"]]
        : ""
      )
      gim_ca_file_local = (
        (contains(keys(local.idx), "gim_ca_file_local") && r[local.idx["gim_ca_file_local"]] != "")
        ? r[local.idx["gim_ca_file_local"]]
        : ""
      )
      gim_key_file_local = (
        (contains(keys(local.idx), "gim_key_file_local") && r[local.idx["gim_key_file_local"]] != "")
        ? r[local.idx["gim_key_file_local"]]
        : ""
      )
      gim_cert_file_local = (
        (contains(keys(local.idx), "gim_cert_file_local") && r[local.idx["gim_cert_file_local"]] != "")
        ? r[local.idx["gim_cert_file_local"]]
        : ""
      )

      auto_assign_ip = (
        (contains(keys(local.idx), "auto_assign_ip") && r[local.idx["auto_assign_ip"]] != "")
        ? lower(r[local.idx["auto_assign_ip"]])
        : "0"
      )

      check_8443 = (
        (contains(keys(local.idx), "check_8443") && r[local.idx["check_8443"]] != "")
        ? lower(r[local.idx["check_8443"]])
        : "true"
      )

      allow_tls_fallback = (
        (contains(keys(local.idx), "allow_tls_fallback") && r[local.idx["allow_tls_fallback"]] != "")
        ? lower(r[local.idx["allow_tls_fallback"]])
        : "false"
      )
    }
  }

  is_unix = { for k, s in local.servers : k => contains(["linux", "unix"], s.os) }

  # Avoid null-in-template issues; empty string means "not provided"
  ssh_key_path = var.ssh_private_key_path == null ? "" : var.ssh_private_key_path
}

resource "null_resource" "install_gim_unix" {
  for_each = { for k, s in local.servers : k => s if local.is_unix[k] }

  triggers = {
    host            = each.value.host
    username        = each.value.username
    gim_server_host = each.value.gim_server_host

    gim_sh_hash  = filesha256(var.unix_gim_installer_sh_path)
    gim_gim_hash = filesha256(var.unix_gim_installer_gim_path)

    stap_enabled  = tostring(var.install_stap)
    stap_sh_hash  = var.install_stap && var.unix_stap_installer_sh_path != "" ? filesha256(var.unix_stap_installer_sh_path) : "disabled"
    stap_gim_hash = var.install_stap && var.unix_stap_installer_gim_path != "" ? filesha256(var.unix_stap_installer_gim_path) : "disabled"
  }

  provisioner "local-exec" {
    command = <<EOT
set -e
mkdir -p "${var.runner_log_dir}"
LOG_FILE="${var.runner_log_dir}/${each.key}.log"

bash "${path.module}/scripts/unix/install_gim_unix.sh" \
  --host "${each.value.host}" \
  --mgmt-port "${each.value.mgmt_port}" \
  --username "${each.value.username}" \
  --password "${each.value.password}" \
  --gim-server "${each.value.gim_server_host}" \
  --gim-server-port "${each.value.gim_server_port}" \
  --local-ip "${each.value.local_ip}" \
  --install-dir "${each.value.install_dir}" \
  --perl-path "${each.value.perl_path}" \
  --listener-port "${each.value.listener_port}" \
  --shared-secret "${each.value.shared_secret}" \
  --failover-gim-server "${each.value.failover_gim_server_host}" \
  --ca-file "${each.value.gim_ca_file}" \
  --key-file "${each.value.gim_key_file}" \
  --cert-file "${each.value.gim_cert_file}" \
  --ca-file-local "${each.value.gim_ca_file_local}" \
  --key-file-local "${each.value.gim_key_file_local}" \
  --cert-file-local "${each.value.gim_cert_file_local}" \
  --auto-assign-ip "${each.value.auto_assign_ip}" \
  --check-8443 "${each.value.check_8443}" \
  --allow-tls-fallback "${each.value.allow_tls_fallback}" \
  --installer-sh "${var.unix_gim_installer_sh_path}" \
  --installer-gim "${var.unix_gim_installer_gim_path}" \
  --install-stap "${var.install_stap}" \
  --stap-installer-sh "${var.unix_stap_installer_sh_path}" \
  --stap-installer-gim "${var.unix_stap_installer_gim_path}" \
  --ports "${join(",", var.gim_ports)}" \
  --ssh-key "${local.ssh_key_path}" \
  --log-file "$${LOG_FILE}"
EOT
  }
}

