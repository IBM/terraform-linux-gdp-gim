#!/usr/bin/env bash
#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#
set -euo pipefail

#############################################
# IBM Guardium GIM Installer – FINAL (TF-safe)
#############################################

MGMT_PORT=22
INSTALL_DIR="/usr/local/guardium"
GIM_SERVER_PORT=8446
LISTENER_PORT=8445
SKIP_IF_INSTALLED=true
CENTRAL_LOG=""

HOST=""
USER=""
PASS=""
SSH_KEY=""
PEM_KEY=""
USE_SUDO="false"
GIM_SERVER=""
PACKAGES_ROOT=""
LOG_FILE=""
INSTALL_OPTIONAL_PERL_PACKAGES=false
FAILOVER_GIM_SERVER=""
SHARED_SECRET=""
GIM_CA_FILE=""
GIM_KEY_FILE=""
GIM_CERT_FILE=""
GIM_CA_FILE_LOCAL=""
GIM_KEY_FILE_LOCAL=""
GIM_CERT_FILE_LOCAL=""
KIT_VERSION=""
LOCAL_IP=""
# Remote dir for copied certs: use $HOME/.guardium_gim_certs so SSH user can always write (avoids /tmp/gim-certs permission issues if dir was root-owned)
REMOTE_GIM_CERTS_DIR=""

usage() {
  echo "Usage: install_gim_unix.sh --host --username (--password|--pem-key|--ssh-key) --gim-server --packages-root --log-file [--use-sudo true|false] [--install-optional-perl-packages true|false] [--install-dir DIR] [--gim-server-port PORT] [--listener-port PORT] [--failover-gim-server HOST] [--shared-secret SECRET] [--ca-file PATH] [--key-file PATH] [--cert-file PATH] [--ca-file-local PATH] [--key-file-local PATH] [--cert-file-local PATH] [--kit-version STRING] [--local-ip IP]"
  echo "  Optional TLS certs: (A) Paths on target host: --ca-file, --key-file, --cert-file (files must exist on target). (B) Paths on runner: --ca-file-local, --key-file-local, --cert-file-local (script copies them to target $REMOTE_GIM_CERTS_DIR/ before install). Use key+cert (and optionally ca); omit ca for self-signed."
  echo "  --kit-version STRING: when multiple GIM kits match the target OS/arch, restrict the search to kits whose directory or file name contains STRING (e.g. '12.2.2.0' or 'r123489'). Without it, the newest-sorting matching kit is used."
  echo "  --local-ip IP: use this IPv4 address for --tapip and CLIENT_IP instead of auto-detecting it on the target. Useful when the target has multiple interfaces/addresses and auto-detection picks the wrong one."
  exit 1
}

#############################################
# Argument parsing (Terraform tolerant)
#############################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2;;
    --username) USER="$2"; shift 2;;
    --password) PASS="$2"; shift 2;;
    --ssh-key) SSH_KEY="$2"; shift 2;;
    --pem-key) PEM_KEY="$2"; shift 2;;
    --use-sudo) USE_SUDO="$2"; shift 2;;
    --gim-server) GIM_SERVER="$2"; shift 2;;
    --packages-root) PACKAGES_ROOT="$2"; shift 2;;
    --log-file) LOG_FILE="$2"; shift 2;;
    --central-log) CENTRAL_LOG="$2"; shift 2;;   # <-- NEW (Terraform)
    --mgmt-port) MGMT_PORT="$2"; shift 2;;
    --skip-if-installed) SKIP_IF_INSTALLED="$2"; shift 2;;
    --install-optional-perl-packages) INSTALL_OPTIONAL_PERL_PACKAGES="$2"; shift 2;;
    --install-dir) INSTALL_DIR="$2"; shift 2;;
    --gim-server-port) GIM_SERVER_PORT="$2"; shift 2;;
    --listener-port) LISTENER_PORT="$2"; shift 2;;
    --failover-gim-server) FAILOVER_GIM_SERVER="$2"; shift 2;;
    --shared-secret) SHARED_SECRET="$2"; shift 2;;
    --ca-file) GIM_CA_FILE="$2"; shift 2;;
    --key-file) GIM_KEY_FILE="$2"; shift 2;;
    --cert-file) GIM_CERT_FILE="$2"; shift 2;;
    --ca-file-local) GIM_CA_FILE_LOCAL="$2"; shift 2;;
    --key-file-local) GIM_KEY_FILE_LOCAL="$2"; shift 2;;
    --cert-file-local) GIM_CERT_FILE_LOCAL="$2"; shift 2;;
    --kit-version) KIT_VERSION="$2"; shift 2;;
    --local-ip) LOCAL_IP="$2"; shift 2;;
    *)
      echo "ERROR: Unknown argument $1"
      usage
      ;;
    esac
done

[[ -z "$HOST" || -z "$USER" || -z "$GIM_SERVER" || -z "$PACKAGES_ROOT" || -z "$LOG_FILE" ]] && usage

# Normalize boolean values to lowercase (handle TRUE/True/true from CSV)
USE_SUDO=$(echo "$USE_SUDO" | tr '[:upper:]' '[:lower:]')
INSTALL_OPTIONAL_PERL_PACKAGES=$(echo "$INSTALL_OPTIONAL_PERL_PACKAGES" | tr '[:upper:]' '[:lower:]')

# Use PEM_KEY if provided, otherwise fall back to SSH_KEY, then password
if [[ -n "$PEM_KEY" ]]; then
  SSH_KEY="$PEM_KEY"
fi

[[ -z "$PASS" && -z "$SSH_KEY" ]] && usage

mkdir -p "$(dirname "$LOG_FILE")"

# Enhanced logging with levels and formatting
# Check if output is to terminal (for colors) vs file
if [[ -t 1 ]]; then
  USE_COLORS=true
else
  USE_COLORS=false
fi

# Log levels: INFO, WARN, ERROR, SUCCESS, DEBUG
log() {
  local level="${1:-INFO}"
  shift
  local message="$*"
  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local color=""
  local reset=""
  
  if [[ "$USE_COLORS" == "true" ]]; then
    case "$level" in
      INFO)   color="\033[0;36m" ;;  # Cyan
      WARN)   color="\033[0;33m" ;;  # Yellow
      ERROR)  color="\033[0;31m" ;;  # Red
      SUCCESS) color="\033[0;32m" ;; # Green
      DEBUG)  color="\033[0;90m" ;;  # Gray
      *)      color="" ;;
    esac
    reset="\033[0m"
  fi
  
  # Format: [TIMESTAMP] [LEVEL] message
  local log_line="[${timestamp}] [${level}] ${message}"
  
  # Write to file (no colors)
  echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
  
  # Write to stdout (with colors if terminal)
  if [[ "$USE_COLORS" == "true" ]]; then
    echo -e "${color}${log_line}${reset}"
  else
    echo "$log_line"
  fi
}

# Convenience functions
log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }
log_debug() { log "DEBUG" "$@"; }

# Progress indicator
log_progress() {
  local step="$1"
  local total="$2"
  local message="$3"
  log_info "[$step/$total] $message"
}

# Section header
log_section() {
  local title="$1"
  log_info ""
  log_info "=========================================="
  log_info "$title"
  log_info "=========================================="
}

# Summary function (use :- for vars that may be unset when called before OS detection, e.g. on SSH failure)
log_summary() {
  local status="$1"
  local message="$2"
  log_section "Installation Summary"
  log_info "Host: ${HOST}"
  log_info "OS: ${OS_ID:-unknown} ${VERSION_ID:-unknown} (${ARCH:-unknown})"
  log_info "Kit: ${KIT_NAME:-N/A}"
  log_info "GIM Server: ${GIM_SERVER}"
  log_info "Status: $status"
  log_info "Message: $message"
  log_info "=========================================="
  
  # Write to central log if configured
  if [[ -n "${CENTRAL_LOG:-}" ]]; then
    mkdir -p "$(dirname "$CENTRAL_LOG")"
    if [[ ! -f "$CENTRAL_LOG" ]]; then
      echo "timestamp,host,os,arch,kit,status,message" > "$CENTRAL_LOG"
    fi
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ),${HOST},${OS_ID:-unknown}-${VERSION_ID:-unknown},${ARCH:-unknown},${KIT_NAME:-N/A},${status},${message//,/;}" >> "$CENTRAL_LOG"
  fi
}

# Enhanced error trap
trap 'log_error "Script failed at line $LINENO" "Command: $BASH_COMMAND"; log_summary "FAILED" "Script error at line $LINENO"; exit 1' ERR

# Start logging
log_section "IBM Guardium GIM Installation"
log_info "Starting installation on ${HOST}"
log_info "User: ${USER}"
log_info "GIM Server: ${GIM_SERVER}:${GIM_SERVER_PORT}"
log_info "Install Directory: ${INSTALL_DIR}"
log_info "Listener Port: ${LISTENER_PORT}"
[[ -n "$FAILOVER_GIM_SERVER" ]] && log_info "Failover GIM Server: ${FAILOVER_GIM_SERVER}"
[[ -n "$SHARED_SECRET" ]] && log_info "Shared secret: (set)"

#############################################
# SSH helpers
#############################################
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o LogLevel=ERROR"

# Test SSH connection
log_progress "1" "8" "Testing SSH connection to ${USER}@${HOST}:${MGMT_PORT}..."
set +e; trap '' ERR  # A failed connection is handled explicitly below, not a script error
if [[ -n "$SSH_KEY" ]]; then
  ssh -i "$SSH_KEY" -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "echo 'SSH connection successful'" >/dev/null 2>&1
else
  sshpass -p "$PASS" ssh -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "echo 'SSH connection successful'" >/dev/null 2>&1
fi
SSH_TEST_EXIT=$?
set -e; trap 'log_error "Script failed at line $LINENO" "Command: $BASH_COMMAND"; log_summary "FAILED" "Script error at line $LINENO"; exit 1' ERR  # Re-enable
if [[ "$SSH_TEST_EXIT" != "0" ]]; then
  log_error "Failed to establish SSH connection to ${USER}@${HOST}:${MGMT_PORT}"
  log_error "Please verify: SSH access, credentials, network connectivity, and firewall rules"
  log_summary "FAILED" "SSH connection failed"
  exit 1
fi
log_success "SSH connection test successful"
SSH_ESTABLISHED=1

ssh_exec() {
  # Build the command - handle both regular args and heredoc
  local cmd
  local needs_sudo=false
  
  if [[ $# -eq 0 ]]; then
    # Heredoc mode - read from stdin
    cmd=$(cat)
    # Heredoc commands typically need sudo (file operations, installations, etc.)
    needs_sudo=true
  else
    # Regular command mode
    cmd="$*"
    # Commands that don't need sudo (read-only operations that work without root)
    # These are safe to run without sudo even if USE_SUDO=true
    if [[ "$cmd" =~ ^(source|echo|hostname|uname|command -v|test|\[).* ]] && \
       [[ ! "$cmd" =~ (systemctl|dnf|yum|apt-get|chmod|rm|mkdir|install|enable|start|perl) ]]; then
      needs_sudo=false
    else
      # Commands that need root: systemctl, dnf, yum, apt-get, chmod, rm, mkdir, install, etc.
      needs_sudo=true
    fi
  fi
  
  # Add sudo prefix if USE_SUDO is true and command needs it
  if [[ "$USE_SUDO" == "true" ]] && [[ "$needs_sudo" == "true" ]]; then
    # For heredoc or complex commands (with if/elif/else/fi, &&, ||, set, cd), wrap in sudo bash -c
    if [[ $# -eq 0 ]] || [[ "$cmd" == *"set "* ]] || [[ "$cmd" == *"cd "* ]] || \
       [[ "$cmd" == *"&&"* ]] || [[ "$cmd" == *"||"* ]] || [[ "$cmd" == *"<<CONF"* ]] || \
       [[ "$cmd" == *"if "* ]] || [[ "$cmd" == *"elif "* ]] || [[ "$cmd" == *"else "* ]] || [[ "$cmd" == *"fi"* ]]; then
      cmd="sudo bash -c $(printf '%q' "$cmd")"
    else
      cmd="sudo $cmd"
    fi
  fi
  
  if [[ -n "$SSH_KEY" ]]; then
    ssh -i "$SSH_KEY" -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "$cmd"
  else
    sshpass -p "$PASS" ssh -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "$cmd"
  fi
}

scp_copy() {
  if [[ -n "$SSH_KEY" ]]; then
    scp -i "$SSH_KEY" -P "$MGMT_PORT" $SSH_OPTS "$1" "$USER@$HOST:$2"
  else
    sshpass -p "$PASS" scp -P "$MGMT_PORT" $SSH_OPTS "$1" "$USER@$HOST:$2"
  fi
}

# Run a command as the SSH user (never with sudo). Use for dirs the user must write to (e.g. cert staging).
ssh_exec_as_user() {
  local cmd="$*"
  if [[ -n "$SSH_KEY" ]]; then
    ssh -i "$SSH_KEY" -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "$cmd"
  else
    sshpass -p "$PASS" ssh -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "$cmd"
  fi
}

#############################################
# Pull GIM debug logs from the target to the runner, alongside this host's own
# log file, for post-mortem debugging. Best-effort: never fails the script, and
# runs on every exit path (success, warning, or failure) via the EXIT trap below,
# since logs matter most exactly when something went wrong.
# - Agent installation log: <INSTALL_DIR>/modules/GIM/<version>/GIM.log
# - Core connection logger: <INSTALL_DIR>/modules/central_logger.log
#############################################
copy_debug_logs() {
  [[ "${SSH_ESTABLISHED:-0}" != "1" ]] && return 0
  local log_base="${LOG_FILE%.log}"

  local local_central="${log_base}_central_logger.log"
  if ssh_exec "cat '${INSTALL_DIR}/modules/central_logger.log'" >"$local_central" 2>/dev/null && [[ -s "$local_central" ]]; then
    log_info "Copied central_logger.log to $local_central"
  else
    rm -f "$local_central" 2>/dev/null
  fi

  local remote_gim_log
  remote_gim_log=$(ssh_exec "ls -1t ${INSTALL_DIR}/modules/GIM/*/GIM.log 2>/dev/null | head -n 1" 2>/dev/null) || true
  if [[ -n "$remote_gim_log" ]]; then
    local local_gim="${log_base}_GIM.log"
    if ssh_exec "cat '$remote_gim_log'" >"$local_gim" 2>/dev/null && [[ -s "$local_gim" ]]; then
      log_info "Copied GIM.log to $local_gim"
    else
      rm -f "$local_gim" 2>/dev/null
    fi
  fi
  return 0
}
trap 'copy_debug_logs' EXIT

#############################################
# Check connectivity from the target host to the GIM server port, and whether
# the listener port is free on the target. Non-fatal (warn only): a failed
# check here doesn't always mean the install will fail (e.g. proxies, MTU),
# but it's a strong early signal for the most common cause of GIM registration failures.
#############################################
check_tcp() {
  # Runs on the target host via ssh_exec_as_user; returns 0 if the TCP connect succeeds.
  local target_host="$1" target_port="$2"
  ssh_exec_as_user "command -v timeout >/dev/null 2>&1 && TMO='timeout 5' || TMO=''; \$TMO bash -c '(exec 3<>/dev/tcp/${target_host}/${target_port}) 2>/dev/null'" >/dev/null 2>&1
}

log_info "Checking connectivity from ${HOST} to GIM server ${GIM_SERVER}:${GIM_SERVER_PORT}..."
set +e; trap '' ERR  # A closed/filtered port is an expected outcome here, not a script error
check_tcp "$GIM_SERVER" "$GIM_SERVER_PORT"
GIM_PORT_REACHABLE=$?
set -e; trap 'log_error "Script failed at line $LINENO" "Command: $BASH_COMMAND"; log_summary "FAILED" "Script error at line $LINENO"; exit 1' ERR  # Re-enable
if [[ "$GIM_PORT_REACHABLE" == "0" ]]; then
  log_success "GIM server port ${GIM_SERVER_PORT} is reachable from ${HOST}"
else
  log_warn "GIM server ${GIM_SERVER}:${GIM_SERVER_PORT} is NOT reachable from ${HOST} - check firewall/security group rules. The GIM agent will likely fail to register with the Guardium server."
fi

if [[ -n "$LISTENER_PORT" ]]; then
  log_info "Checking whether listener port ${LISTENER_PORT} is already in use on ${HOST}..."
  set +e; trap '' ERR
  check_tcp "127.0.0.1" "$LISTENER_PORT"
  LISTENER_PORT_IN_USE=$?
  set -e; trap 'log_error "Script failed at line $LINENO" "Command: $BASH_COMMAND"; log_summary "FAILED" "Script error at line $LINENO"; exit 1' ERR
  if [[ "$LISTENER_PORT_IN_USE" == "0" ]]; then
    log_warn "Listener port ${LISTENER_PORT} already has something listening on ${HOST} - GIM may fail to bind it"
  else
    log_success "Listener port ${LISTENER_PORT} is free on ${HOST}"
  fi
fi

#############################################
# Detect OS and version
#############################################
log_progress "2" "8" "Detecting OS and architecture..."
OS_ID=$(ssh_exec "source /etc/os-release && echo \$ID")
VERSION_ID=$(ssh_exec "source /etc/os-release && echo \${VERSION_ID:-}")
ARCH=$(ssh_exec "uname -m")

# Build OS_VERSION for kit matching based on OS type
# CentOS, Oracle Linux, Rocky Linux, and AlmaLinux are RHEL-compatible and use RHEL kits
if [[ "$OS_ID" == "rhel" || "$OS_ID" == "centos" || "$OS_ID" == "ol" || "$OS_ID" == "rocky" || "$OS_ID" == "almalinux" ]]; then
  # RHEL/CentOS/Oracle Linux: use major version (e.g., "8", "9", "10")
  RHEL_VERSION=$(echo "$VERSION_ID" | cut -d. -f1)
  OS_VERSION="rhel-${RHEL_VERSION}"
  log_info "Detected platform: ${OS_ID} ${RHEL_VERSION} (${ARCH}) - using kit: ${OS_VERSION}"
elif [[ "$OS_ID" == "ubuntu" ]]; then
  # Ubuntu: use full VERSION_ID (e.g., "24.04", "22.04")
  OS_VERSION="ubuntu-${VERSION_ID}"
  log_info "Detected platform: ${OS_ID} ${VERSION_ID} (${ARCH}) - using kit: ${OS_VERSION}"
elif [[ "$OS_ID" == "debian" ]]; then
  # Debian: use major version (e.g., "11", "12")
  DEBIAN_VERSION=$(echo "$VERSION_ID" | cut -d. -f1)
  OS_VERSION="debian-${DEBIAN_VERSION}"
  log_info "Detected platform: ${OS_ID} ${DEBIAN_VERSION} (${ARCH}) - using kit: ${OS_VERSION}"
elif [[ "$OS_ID" == "sles" || "$OS_ID" == "opensuse-leap" ]]; then
  # SUSE: use major version (e.g., "12", "15")
  SUSE_VERSION=$(echo "$VERSION_ID" | cut -d. -f1)
  if [[ "$SUSE_VERSION" == "16" ]]; then
    # No suse-16 kit exists yet, and the suse-15 kit is NOT a usable fallback: IBM's gim_installer
    # enforces a strict VENDOR_VERSION check and rejects it ("VENDOR_VERSION mismatch (required=16,
    # received=15)"), confirmed on a real SLES 16 host. Fail fast here instead of running through
    # steps 4-8 (kit copy, Perl packages, config) only to hit that error at the very end.
    log_error "Detected platform: ${OS_ID} ${SUSE_VERSION} (${ARCH}) - no compatible GIM kit available"
    log_error "The suse-15 kit is rejected by the installer's VENDOR_VERSION check on SLES 16; SLES 16 is not yet supported until IBM ships a suse-16 kit"
    log_summary "FAILED" "No compatible GIM kit for SLES 16 (VENDOR_VERSION check rejects suse-15 kit)"
    exit 1
  else
    OS_VERSION="suse-${SUSE_VERSION}"
    log_info "Detected platform: ${OS_ID} ${SUSE_VERSION} (${ARCH}) - using kit: ${OS_VERSION}"
  fi
elif [[ "$OS_ID" == "amzn" ]]; then
  # Amazon Linux: VERSION_ID can be "2" or "2023"
  if [[ "$VERSION_ID" == "2" ]]; then
    OS_VERSION="amzn-2"
  elif [[ "$VERSION_ID" == "2023" ]]; then
    OS_VERSION="amzn-2023"
  else
    # Fallback: try to match what we have
    OS_VERSION="amzn-${VERSION_ID}"
  fi
  log_info "Detected platform: ${OS_ID} ${VERSION_ID} (${ARCH}) - using kit: ${OS_VERSION}"
else
  # Other OSes: use OS_ID as-is (may need version matching later)
  OS_VERSION="$OS_ID"
  log_info "Detected platform: ${OS_ID}-${ARCH}"
fi
log_success "OS detection completed"

#############################################
# Resolve gim_client on remote: bin/gim_client or modules/GIM/current/gim_client[.pl]
#############################################
# How we check "GIM ready": run the GIM client status command; exit 0 = ready.
# Path can be: .../bin/gim_client, .../modules/GIM/current/gim_client(.pl), or - when the
# installer creates no "current" symlink - the newest .../modules/GIM/<version>/gim_client.pl.
# Always relative to $INSTALL_DIR: the installer places files under the exact --dir it's given,
# not under a hardcoded /usr/local/guardium (that was only ever the script's own default).
GIM_STATUS_CMD="if [ -x ${INSTALL_DIR}/bin/gim_client ]; then ${INSTALL_DIR}/bin/gim_client status; \
elif [ -x ${INSTALL_DIR}/modules/GIM/current/gim_client ]; then ${INSTALL_DIR}/modules/GIM/current/gim_client status; \
elif [ -f ${INSTALL_DIR}/modules/GIM/current/gim_client.pl ]; then perl ${INSTALL_DIR}/modules/GIM/current/gim_client.pl status; \
elif [ -f ${INSTALL_DIR}/GIM/current/gim_client.pl ]; then perl ${INSTALL_DIR}/GIM/current/gim_client.pl status; \
else GIM_PL=\$(ls -1 ${INSTALL_DIR}/modules/GIM/*/gim_client.pl 2>/dev/null | sort | tail -n 1); \
  if [ -n \"\$GIM_PL\" ]; then perl \"\$GIM_PL\" status; else echo \"No gim_client found\"; exit 1; fi; fi"

#############################################
# Skip if already installed (check gim_client or GIM module dir)
#############################################
if [[ "$SKIP_IF_INSTALLED" == "true" ]]; then
  log_progress "3" "8" "Checking if GIM is already installed..."
  set +e  # Temporarily disable exit on error for this check
  trap '' ERR  # Temporarily disable ERR trap (these failures are expected when GIM isn't installed)
  CHECK1=$(ssh_exec "[ -x ${INSTALL_DIR}/bin/gim_client ]" 2>/dev/null)
  CHECK1_EXIT=$?
  CHECK2=$(ssh_exec "[ -d ${INSTALL_DIR}/modules/GIM/current ]" 2>/dev/null)
  CHECK2_EXIT=$?
  CHECK3=$(ssh_exec "ls ${INSTALL_DIR}/modules/GIM/*/gim_client.pl" 2>/dev/null)
  CHECK3_EXIT=$?
  trap 'log_error "Script failed at line $LINENO" "Command: $BASH_COMMAND"; log_summary "FAILED" "Script error at line $LINENO"; exit 1' ERR  # Re-enable ERR trap
  set -e  # Re-enable exit on error
  if [[ "$CHECK1_EXIT" == "0" ]] || [[ "$CHECK2_EXIT" == "0" ]] || [[ "$CHECK3_EXIT" == "0" ]]; then
    log_success "GIM already installed – skipping installation"
    log_summary "SKIPPED" "GIM already installed"
    exit 0
  fi
  log_info "GIM not found – proceeding with installation"
fi

#############################################
# Locate GIM kit (prefer guard-bundle-GIM over GUC – GIM bundle has correct config.all for installer)
# Match exact OS version (e.g., rhel-8, rhel-9, rhel-10) to avoid VENDOR_VERSION mismatch
#############################################
log_progress "4" "8" "Searching for GIM kit matching ${OS_VERSION} (${ARCH})${KIT_VERSION:+, version '${KIT_VERSION}'}..."
log_debug "Search path: ${PACKAGES_ROOT}/*/GIM_Agents/*${OS_VERSION}*linux*${ARCH}.gim.sh"
ALL_KITS=$(find "$PACKAGES_ROOT" \
  -type f \
  -path "*/GIM_Agents/*" \
  -name "*${OS_VERSION}*linux*${ARCH}.gim.sh" \
  2>/dev/null | sort)

# If --kit-version was given, restrict candidates to paths containing that string
# (matches the versioned kit directory, e.g. "Guardium_12.2.2.0_GIM_Amazon_r123489", or the file name).
CANDIDATE_KITS="$ALL_KITS"
if [[ -n "$KIT_VERSION" ]]; then
  CANDIDATE_KITS=$(echo "$ALL_KITS" | grep -F -- "$KIT_VERSION" 2>/dev/null || true)
  if [[ -z "$CANDIDATE_KITS" ]]; then
    log_error "No GIM kit matching ${OS_VERSION} (${ARCH}) contains requested version '${KIT_VERSION}' in ${PACKAGES_ROOT}"
    if [[ -n "$ALL_KITS" ]]; then
      log_warn "Kits available for ${OS_VERSION} (${ARCH}):"
      echo "$ALL_KITS" | while read -r kit; do
        log_info "  - $kit"
      done
    fi
    log_summary "FAILED" "No GIM kit found matching requested version '${KIT_VERSION}'"
    exit 1
  fi
fi

# Prefer guard-bundle-GIM*.sh (same as consolidated_installer) to avoid "GIM information is missing from config.all"
# grep returns non-zero when no match found, so suppress error
KIT=$(echo "$CANDIDATE_KITS" | grep -E "guard-bundle-GIM-" 2>/dev/null | tail -n 1 || true)
[[ -z "$KIT" ]] && KIT=$(echo "$CANDIDATE_KITS" | tail -n 1)

if [[ -z "$KIT" ]]; then
  log_error "No matching GIM kit found for ${OS_VERSION} (${ARCH}) in ${PACKAGES_ROOT}"
  log_error "Searched pattern: *${OS_VERSION}*linux*${ARCH}.gim.sh"
  if [[ -z "$ALL_KITS" ]]; then
    log_error "No kits found at all. Please ensure installer packages are extracted in ${PACKAGES_ROOT}"
    log_error "Expected structure: ${PACKAGES_ROOT}/Guardium_*_GIM_*/GIM_Agents/guard-bundle-GIM-*.gim.sh"
  else
    log_warn "Found kits but none matched:"
    echo "$ALL_KITS" | while read -r kit; do
      log_info "  - $kit"
    done
  fi
  log_summary "FAILED" "No matching GIM kit found"
  exit 1
fi

KIT_NAME=$(basename "$KIT")
if [[ -n "$KIT_VERSION" ]]; then
  MATCH_COUNT=$(echo "$ALL_KITS" | grep -Fc -- "$KIT_VERSION" 2>/dev/null || echo 0)
  if [[ "$MATCH_COUNT" -gt 1 ]]; then
    log_warn "Multiple kits matched version '${KIT_VERSION}'; using the last one after sorting: $KIT_NAME"
  fi
else
  KIT_COUNT=$(echo "$ALL_KITS" | grep -c . || true)
  if [[ "$KIT_COUNT" -gt 1 ]]; then
    log_warn "Multiple GIM kits found for ${OS_VERSION} (${ARCH}); no --kit-version given, so picking the last one after sorting: $KIT_NAME"
    log_warn "To pin a specific kit, set 'gim_kit_version' for this host in servers.csv (e.g. a version like '12.2.2.0' or a substring like 'r123489')."
  fi
fi
log_success "Found kit: $KIT_NAME"

#############################################
# Prepare remote host
#############################################
log_progress "5" "8" "Preparing remote host directory..."
# Remove existing directory if it exists (may be root-owned from previous run)
# If USE_SUDO is true and regular removal fails, try with sudo
set +e; trap '' ERR  # A failure here is expected and handled below (retried with sudo)
if [[ -n "$SSH_KEY" ]]; then
  ssh -i "$SSH_KEY" -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "rm -rf /tmp/guardium_gim" 2>/dev/null
  RM_EXIT=$?
else
  sshpass -p "$PASS" ssh -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "rm -rf /tmp/guardium_gim" 2>/dev/null
  RM_EXIT=$?
fi
set -e; trap 'log_error "Script failed at line $LINENO" "Command: $BASH_COMMAND"; log_summary "FAILED" "Script error at line $LINENO"; exit 1' ERR  # Re-enable

# If removal failed and USE_SUDO is true, try with sudo (do not exit on failure; we will recreate dir next)
if [[ "$RM_EXIT" != "0" ]] && [[ "$USE_SUDO" == "true" ]]; then
  log_warn "Previous directory exists (may be root-owned), removing with sudo..."
  ssh_exec "rm -rf /tmp/guardium_gim" 2>/dev/null || true
fi

# Create directory without sudo (since /tmp is world-writable, regular users can create dirs there)
# This ensures the directory is owned by the regular user, so SCP can write to it
if [[ -n "$SSH_KEY" ]]; then
  ssh -i "$SSH_KEY" -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "mkdir -p /tmp/guardium_gim" || {
    log_error "Failed to create remote directory /tmp/guardium_gim"
    log_summary "FAILED" "Failed to create remote directory"
    exit 1
  }
else
  sshpass -p "$PASS" ssh -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "mkdir -p /tmp/guardium_gim" || {
    log_error "Failed to create remote directory /tmp/guardium_gim"
    log_summary "FAILED" "Failed to create remote directory"
    exit 1
  }
fi

log_info "Copying installer kit to remote host..."
if ! scp_copy "$KIT" "/tmp/guardium_gim/"; then
  log_error "Failed to copy installer kit to remote host"
  log_summary "FAILED" "Failed to copy installer kit"
  exit 1
fi
log_success "Installer kit copied successfully"

log_info "Setting installer permissions..."
if ! ssh_exec "chmod +x /tmp/guardium_gim/$KIT_NAME"; then
  log_error "Failed to set installer permissions"
  log_summary "FAILED" "Failed to set installer permissions"
  exit 1
fi

#############################################
# Optional: install Perl packages on RHEL/CentOS/Amazon Linux (when install_optional_perl_packages=true)
# Installs: perl-lib, perl-Sys-Hostname, perl-File-Copy, perl-File-Find, perl-Data-Dumper (required by GIM on minimal installs)
# On RHEL 8, if modular filtering blocks, try perl-core as fallback
# Amazon Linux 2023 uses dnf like RHEL 9, so same package names work
#############################################
if [[ "$INSTALL_OPTIONAL_PERL_PACKAGES" == "true" ]] && [[ "$OS_ID" == "rhel" || "$OS_ID" == "centos" || "$OS_ID" == "ol" || "$OS_ID" == "rocky" || "$OS_ID" == "almalinux" || "$OS_ID" == "amzn" ]]; then
  log_progress "6" "8" "Installing optional Perl packages..."
  # RHEL 8: Perl is in a module stream; enable it then install perl-core (avoids "All matches were filtered out by modular filtering")
  if [[ "$OS_VERSION" == "rhel-8" ]]; then
    log_info "RHEL 8: enabling Perl module stream and installing perl-core"
    PERL_OUT=$(ssh_exec "dnf module enable -y perl:5.26 2>/dev/null; dnf install -y perl-core 2>&1" || true)
  else
    log_info "Installing: perl-lib, perl-Sys-Hostname, perl-File-Copy, perl-File-Find, perl-Data-Dumper, perl-core"
    PERL_OUT=$(ssh_exec "dnf install -y perl-lib perl-Sys-Hostname perl-File-Copy perl-File-Find perl-Data-Dumper perl-core 2>&1 || yum install -y perl-lib perl-Sys-Hostname perl-File-Copy perl-File-Find perl-Data-Dumper perl-core 2>&1 || true" || true)
  fi
  if echo "$PERL_OUT" | grep -qi "error\|failed\|unable to find"; then
    log_warn "Some Perl packages may have failed to install (non-critical; GIM may still work)"
    log_debug "Perl installation output: $PERL_OUT"
  else
    log_success "Perl packages installed successfully"
  fi
elif [[ "$INSTALL_OPTIONAL_PERL_PACKAGES" == "false" ]]; then
  log_info "Skipping optional Perl packages (install_optional_perl_packages=false)"
fi

#############################################
# Resolve the host's IPv4 address, used for both config.all's CLIENT_IP and
# the installer's --tapip (which requires an IPv4 address, not a hostname).
# IPv6 (including link-local addresses like fe80::...%eth0) is rejected by the
# GIM installer, so every lookup here is IPv4-only; `hostname -i`/-I can otherwise
# return IPv6 first. --local-ip (from servers.csv local_ip column) always wins when set,
# for hosts with multiple interfaces/addresses where auto-detection picks the wrong one.
#############################################
IPV4_RE='^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$'
if [[ -n "$LOCAL_IP" ]]; then
  if [[ "$LOCAL_IP" =~ $IPV4_RE ]]; then
    HOST_IP="$LOCAL_IP"
    log_info "Using local_ip override: $HOST_IP"
  else
    log_warn "local_ip '$LOCAL_IP' is not a valid IPv4 address; ignoring and auto-detecting instead"
    LOCAL_IP=""
  fi
fi
if [[ -z "$LOCAL_IP" ]]; then
  log_info "Getting host IPv4 address..."
  HOST_IP=$(ssh_exec "hostname -I 2>/dev/null" | tr ' ' '\n' | grep -E "$IPV4_RE" | head -n 1)
  if [[ -z "$HOST_IP" ]]; then
    # Fallback: IPv4 route lookup, then IPv4-only hostname resolution
    HOST_IP=$(ssh_exec "ip -4 route get 1.1.1.1 2>/dev/null | grep -oP 'src \K[0-9.]+' | head -n 1")
  fi
  if [[ -z "$HOST_IP" ]]; then
    HOST_IP=$(ssh_exec "getent ahostsv4 \$(hostname) 2>/dev/null | awk '{print \$1}' | head -n 1")
  fi
  if [[ -z "$HOST_IP" ]]; then
    log_warn "Could not determine an IPv4 address for the host, using hostname as fallback"
    HOST_IP="$HOST"
  elif [[ ! "$HOST_IP" =~ $IPV4_RE ]]; then
    log_warn "Detected address '$HOST_IP' is not IPv4, using hostname as fallback"
    HOST_IP="$HOST"
  fi
fi
log_info "Using IP address: $HOST_IP for CLIENT_IP / --tapip"

#############################################
# Create IBM-expected config.all (installer may validate "GIM information" keys)
#############################################
log_progress "7" "8" "Creating GIM configuration file..."

# Use \$ for remote expansion of CLIENT_HOST so it's resolved on the target host, not the runner
ssh_exec <<EOF
set -e
cd /tmp/guardium_gim

CLIENT_HOST=\$(hostname -f)

cat > config.all <<CONF
INSTALL_GIM=1
GIM_SERVER_IP=${GIM_SERVER}
GIM_SQLGUARDIP=${GIM_SERVER}
GIM_LISTENER_PORT=${LISTENER_PORT}
CLIENT_IP=${HOST_IP}
CLIENT_HOSTNAME=\${CLIENT_HOST}
INSTALL_DIR=${INSTALL_DIR}
CONF

chmod 600 config.all
EOF

#############################################
# Run installer (foreground, supported mode)
# Match consolidated_installer.sh: --dir, --tapip, --sqlguardip, --perl required for GIM
# If installer exits non-zero but reports "already installed", treat as success
#############################################
log_progress "8" "8" "Running Guardium GIM installer"

# Optional: copy certs from Terraform runner to remote host, then use those paths for the installer.
if [[ -n "$GIM_KEY_FILE_LOCAL" && -n "$GIM_CERT_FILE_LOCAL" ]]; then
  if [[ ! -f "$GIM_KEY_FILE_LOCAL" ]] || [[ ! -f "$GIM_CERT_FILE_LOCAL" ]]; then
    log_error "Local cert files not found: key=$GIM_KEY_FILE_LOCAL cert=$GIM_CERT_FILE_LOCAL"
    log_summary "FAILED" "Local cert files not found"
    exit 1
  fi
  [[ -n "$GIM_CA_FILE_LOCAL" && ! -f "$GIM_CA_FILE_LOCAL" ]] && log_error "Local CA file not found: $GIM_CA_FILE_LOCAL" && log_summary "FAILED" "Local CA file not found" && exit 1
  # Stage in SSH user's home (no sudo) so scp can write; then copy into install_dir so certs live under install_dir.
  REMOTE_HOME=$(ssh_exec_as_user "echo \$HOME" | tr -d '\r\n')
  [[ -z "$REMOTE_HOME" ]] && { log_error "Could not determine remote home (empty \$HOME?)"; log_summary "FAILED" "Could not create remote cert directory"; exit 1; }
  REMOTE_STAGING="${REMOTE_HOME}/.guardium_gim_certs"
  ssh_exec_as_user "mkdir -p $REMOTE_STAGING" || true
  log_info "Copying TLS certs from runner to remote (staging: $REMOTE_STAGING, then $INSTALL_DIR/.gim-certs)..."
  scp_copy "$GIM_KEY_FILE_LOCAL" "$REMOTE_STAGING/gim-key.pem" || { log_error "Failed to copy key to remote"; log_summary "FAILED" "Could not copy certs to remote"; exit 1; }
  scp_copy "$GIM_CERT_FILE_LOCAL" "$REMOTE_STAGING/gim-cert.pem" || { log_error "Failed to copy cert to remote"; log_summary "FAILED" "Could not copy certs to remote"; exit 1; }
  [[ -n "$GIM_CA_FILE_LOCAL" ]] && scp_copy "$GIM_CA_FILE_LOCAL" "$REMOTE_STAGING/gim-ca.pem" || true
  # Move certs under install_dir so they live with the installation; installer (run with sudo) can read them.
  REMOTE_GIM_CERTS_DIR="$INSTALL_DIR/.gim-certs"
  ssh_exec "mkdir -p $REMOTE_GIM_CERTS_DIR && cp $REMOTE_STAGING/gim-key.pem $REMOTE_STAGING/gim-cert.pem $REMOTE_GIM_CERTS_DIR/ && ( test -f $REMOTE_STAGING/gim-ca.pem && cp $REMOTE_STAGING/gim-ca.pem $REMOTE_GIM_CERTS_DIR/ || true ) && chmod -R go-rwx $REMOTE_GIM_CERTS_DIR"
  GIM_KEY_FILE="$REMOTE_GIM_CERTS_DIR/gim-key.pem"
  GIM_CERT_FILE="$REMOTE_GIM_CERTS_DIR/gim-cert.pem"
  [[ -n "$GIM_CA_FILE_LOCAL" ]] && GIM_CA_FILE="$REMOTE_GIM_CERTS_DIR/gim-ca.pem" || GIM_CA_FILE=""
  log_success "TLS certs copied to remote $REMOTE_GIM_CERTS_DIR"
elif [[ -n "$GIM_CA_FILE_LOCAL" || -n "$GIM_KEY_FILE_LOCAL" || -n "$GIM_CERT_FILE_LOCAL" ]]; then
  log_warn "Ignoring partial local cert options: both --key-file-local and --cert-file-local are required when copying certs from runner"
fi

FAILOVER_INSTALLER_ARG=""
[[ -n "$FAILOVER_GIM_SERVER" ]] && FAILOVER_INSTALLER_ARG=" --failover_sqlguardip ${FAILOVER_GIM_SERVER}"
# Optional custom TLS certs: key_file and cert_file must both be set; ca_file is optional (omit for self-signed). Paths are on the target host (or set above from -local copy).
# Use unquoted paths/values in INSTALLER_ARGS so the remote command string has no nested double quotes (avoids "unexpected EOF" in ssh_exec).
CERT_INSTALLER_ARG=""
if [[ -n "$GIM_KEY_FILE" && -n "$GIM_CERT_FILE" ]]; then
  CERT_INSTALLER_ARG=" --key_file ${GIM_KEY_FILE} --cert_file ${GIM_CERT_FILE}"
  [[ -n "$GIM_CA_FILE" ]] && CERT_INSTALLER_ARG="${CERT_INSTALLER_ARG} --ca_file ${GIM_CA_FILE}"
  log_info "Using custom TLS certs (key_file, cert_file${GIM_CA_FILE:+ , ca_file})"
elif [[ -n "$GIM_CA_FILE" || -n "$GIM_KEY_FILE" || -n "$GIM_CERT_FILE" ]]; then
  log_warn "Ignoring partial cert options: key_file and cert_file are both required when using custom certs; ca_file is optional (omit for self-signed)"
fi
# Build installer args without double quotes so the remote command does not break (shared_secret with spaces would need different handling).
SHARED_SECRET_INSTALLER_ARG=""
[[ -n "$SHARED_SECRET" ]] && SHARED_SECRET_INSTALLER_ARG=" --shared_secret ${SHARED_SECRET}"

log_info "Installer command: ./${KIT_NAME} -- --dir ${INSTALL_DIR} --tapip ${HOST_IP} --sqlguardip ${GIM_SERVER}${FAILOVER_INSTALLER_ARG}${SHARED_SECRET_INSTALLER_ARG}${CERT_INSTALLER_ARG}"

# Build remote command in a variable to avoid fragile single/double-quote alternation that causes "unexpected EOF while looking for matching '"
REMOTE_INSTALL_CMD="set +e; cd /tmp/guardium_gim && PERL_DIR=\$(dirname \"\$(command -v perl 2>/dev/null || echo /usr/bin/perl)\") && ./${KIT_NAME} -- --dir ${INSTALL_DIR} --tapip ${HOST_IP} --sqlguardip ${GIM_SERVER}${FAILOVER_INSTALLER_ARG}${SHARED_SECRET_INSTALLER_ARG}${CERT_INSTALLER_ARG} --perl \"\$PERL_DIR\" -q 2>&1; echo \"INSTALL_EXIT=\$?\""
INSTALL_OUT=$(ssh_exec "$REMOTE_INSTALL_CMD")

INSTALL_EXIT=$(echo "$INSTALL_OUT" | grep '^INSTALL_EXIT=' | sed 's/INSTALL_EXIT=//')
if [[ "${INSTALL_EXIT:-1}" != "0" ]]; then
  if echo "$INSTALL_OUT" | grep -qE "already installed|Bundle is already installed"; then
    log_success "Bundle already installed on host – treating as success"
  elif echo "$INSTALL_OUT" | grep -qi "GIM is installed but not running"; then
    log_warn "GIM is already installed but not running – starting service..."
    ssh_exec "systemctl start guard_gim 2>/dev/null; systemctl enable guard_gim 2>/dev/null; sleep 5; true" || true
    log_success "GIM service started – treating as success"
  elif echo "$INSTALL_OUT" | grep -q "Installation completed with some errors" && echo "$INSTALL_OUT" | grep -q "Failed sending REGISTER message"; then
    log_warn "GIM installed but registration to Guardium server failed"
    log_warn "Check connectivity from host to ${GIM_SERVER}:${GIM_SERVER_PORT} and firewall rules"
    log_info "Continuing – agent may register once network is available"
  else
    echo "$INSTALL_OUT" | tee -a "$LOG_FILE"
    log_error "GIM installer failed with exit code: ${INSTALL_EXIT:-unknown}"
    log_debug "Installer output: $INSTALL_OUT"
    log_summary "FAILED" "GIM installer failed"
    exit 1
  fi
else
  log_success "GIM installer completed successfully"
fi

#############################################
# Ensure GIM service is running, then verify
#############################################
log_info "Starting GIM service (if needed)..."
SERVICE_OUT=$(ssh_exec "systemctl start guard_gim 2>&1; systemctl enable guard_gim 2>&1; sleep 5; echo 'SERVICE_OK'" || echo "SERVICE_ERROR")
if echo "$SERVICE_OUT" | grep -q "SERVICE_OK"; then
  log_success "GIM service started and enabled"
else
  log_warn "GIM service may not have started properly"
  log_debug "Service output: $SERVICE_OUT"
fi

log_info "Waiting for GIM client to become ready..."
for i in 1 2 3 4 5 6 7 8 9 10; do
  sleep 10
  if ssh_exec "$GIM_STATUS_CMD" >/dev/null 2>&1; then
    log_success "GIM client is ready and responding"
    log_summary "SUCCESS" "GIM installation completed successfully"
    exit 0
  fi
  log_info "  Attempt $i/10: GIM not ready yet, waiting 10 seconds..."
done

# Log what gim_client reports for debugging
STATUS_OUT=$(ssh_exec "$GIM_STATUS_CMD 2>&1" || true)
log_warn "GIM client status check failed after 100 seconds"
log_info "GIM client status output: ${STATUS_OUT:-'(none)'}"

if [[ "${STRICT_VERIFY:-0}" == "1" ]]; then
  log_error "GIM installed but not responding after 100s (STRICT_VERIFY=1)"
  log_summary "FAILED" "GIM client not responding (STRICT_VERIFY=1)"
  exit 1
fi

log_warn "GIM installed but client not responding after 100s"
log_info "Install succeeded; check service and Guardium server connectivity"
log_info "Set STRICT_VERIFY=1 to fail on this condition"
log_summary "WARNING" "GIM installed but client not responding - check connectivity"
exit 0
