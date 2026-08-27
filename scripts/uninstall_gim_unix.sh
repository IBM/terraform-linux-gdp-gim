#!/usr/bin/env bash
#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#
set -euo pipefail

#############################################
# IBM Guardium GIM Uninstaller / Cleanup Script
#############################################

MGMT_PORT=22
INSTALL_DIR="/usr/local/guardium"
SKIP_IF_NOT_INSTALLED=true

HOST=""
USER=""
PASS=""
SSH_KEY=""
PEM_KEY=""
USE_SUDO="false"
LOG_FILE=""

usage() {
  echo "Usage: uninstall_gim_unix.sh --host --username (--password|--pem-key|--ssh-key) --log-file [--use-sudo true|false] [--install-dir DIR] [--mgmt-port PORT]"
  exit 1
}

#############################################
# Argument parsing
#############################################
while [[ $# -gt 0 ]]; do
  case "$1" in
    --host) HOST="$2"; shift 2;;
    --username) USER="$2"; shift 2;;
    --password) PASS="$2"; shift 2;;
    --ssh-key) SSH_KEY="$2"; shift 2;;
    --pem-key) PEM_KEY="$2"; shift 2;;
    --use-sudo) USE_SUDO="$2"; shift 2;;
    --log-file) LOG_FILE="$2"; shift 2;;
    --mgmt-port) MGMT_PORT="$2"; shift 2;;
    --install-dir) INSTALL_DIR="$2"; shift 2;;
    *)
      echo "ERROR: Unknown argument $1"
      usage
      ;;
    esac
done

[[ -z "$HOST" || -z "$USER" || -z "$LOG_FILE" ]] && usage

# Normalize boolean values to lowercase
USE_SUDO=$(echo "$USE_SUDO" | tr '[:upper:]' '[:lower:]')
SKIP_IF_NOT_INSTALLED=$(echo "${SKIP_IF_NOT_INSTALLED:-true}" | tr '[:upper:]' '[:lower:]')

# Use PEM_KEY if provided, otherwise fall back to SSH_KEY, then password
if [[ -n "$PEM_KEY" ]]; then
  SSH_KEY="$PEM_KEY"
fi

[[ -z "$PASS" && -z "$SSH_KEY" ]] && usage

mkdir -p "$(dirname "$LOG_FILE")"

# Enhanced logging with levels and formatting
if [[ -t 1 ]]; then
  USE_COLORS=true
else
  USE_COLORS=false
fi

log() {
  local level="${1:-INFO}"
  shift
  local message="$*"
  local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  local color=""
  local reset=""
  
  if [[ "$USE_COLORS" == "true" ]]; then
    case "$level" in
      INFO)   color="\033[0;36m" ;;
      WARN)   color="\033[0;33m" ;;
      ERROR)  color="\033[0;31m" ;;
      SUCCESS) color="\033[0;32m" ;;
      DEBUG)  color="\033[0;90m" ;;
      *)      color="" ;;
    esac
    reset="\033[0m"
  fi
  
  local log_line="[${timestamp}] [${level}] ${message}"
  echo "[${timestamp}] [${level}] ${message}" >> "$LOG_FILE"
  
  if [[ "$USE_COLORS" == "true" ]]; then
    echo -e "${color}${log_line}${reset}"
  else
    echo "$log_line"
  fi
}

log_info() { log "INFO" "$@"; }
log_warn() { log "WARN" "$@"; }
log_error() { log "ERROR" "$@"; }
log_success() { log "SUCCESS" "$@"; }
log_debug() { log "DEBUG" "$@"; }

log_section() {
  local title="$1"
  echo "" >> "$LOG_FILE"
  log_info "=========================================="
  log_info "$title"
  log_info "=========================================="
}

log_summary() {
  local status="$1"
  local message="$2"
  log_section "Uninstallation Summary"
  log_info "Host: ${HOST}"
  log_info "Install Directory: ${INSTALL_DIR}"
  log_info "Status: $status"
  log_info "Message: $message"
  log_info "=========================================="
}

# Enhanced error trap
trap 'log_error "Script failed at line $LINENO" "Command: $BASH_COMMAND"; log_summary "FAILED" "Script error at line $LINENO"; exit 1' ERR

# Start logging
log_section "IBM Guardium GIM Uninstallation / Cleanup"
log_info "Starting uninstallation on ${HOST}"
log_info "User: ${USER}"
log_info "Install Directory: ${INSTALL_DIR}"

#############################################
# SSH helpers
#############################################
SSH_OPTS="-o StrictHostKeyChecking=accept-new -o LogLevel=ERROR"

ssh_exec() {
  local cmd
  local needs_sudo=false
  
  if [[ $# -eq 0 ]]; then
    cmd=$(cat)
    needs_sudo=true
  else
    cmd="$*"
    if [[ "$cmd" =~ ^(source|echo|hostname|uname|command -v|test|\[).* ]] && \
       [[ ! "$cmd" =~ (systemctl|dnf|yum|apt-get|chmod|rm|mkdir|install|enable|start|stop|disable|perl) ]]; then
      needs_sudo=false
    else
      needs_sudo=true
    fi
  fi
  
  if [[ "$USE_SUDO" == "true" ]] && [[ "$needs_sudo" == "true" ]]; then
    if [[ $# -eq 0 ]] || [[ "$cmd" == *"set "* ]] || [[ "$cmd" == *"cd "* ]] || \
       [[ "$cmd" == *"&&"* ]] || [[ "$cmd" == *"||"* ]] || \
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

#############################################
# Test SSH connection
#############################################
log_info "Testing SSH connection to ${USER}@${HOST}:${MGMT_PORT}..."
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
  log_summary "FAILED" "SSH connection failed"
  exit 1
fi
log_success "SSH connection successful"

#############################################
# Check if GIM is installed, and locate the vendor uninstall.pl
# (prefer the "current" symlink; fall back to the newest versioned dir if
# no symlink exists - some kits don't create one, confirmed on real hosts).
#############################################
log_info "Checking if GIM is installed..."
set +e; trap '' ERR  # Absence is an expected, handled outcome here, not a script error
UNINSTALL_PL=$(ssh_exec "if [ -f ${INSTALL_DIR}/modules/GIM/current/uninstall.pl ]; then echo ${INSTALL_DIR}/modules/GIM/current/uninstall.pl; else ls -1t ${INSTALL_DIR}/modules/GIM/*/uninstall.pl 2>/dev/null | head -n 1; fi" 2>/dev/null)
set -e; trap 'log_error "Script failed at line $LINENO" "Command: $BASH_COMMAND"; log_summary "FAILED" "Script error at line $LINENO"; exit 1' ERR

if [[ -z "$UNINSTALL_PL" ]]; then
  if [[ "$SKIP_IF_NOT_INSTALLED" == "true" ]]; then
    log_warn "GIM does not appear to be installed (no uninstall.pl found under ${INSTALL_DIR}/modules/GIM)"
    log_info "Skipping uninstallation (SKIP_IF_NOT_INSTALLED=true)"
    log_summary "SKIPPED" "GIM not installed"
    exit 0
  else
    log_error "GIM does not appear to be installed (no uninstall.pl found under ${INSTALL_DIR}/modules/GIM)"
    log_summary "FAILED" "GIM not installed"
    exit 1
  fi
fi

log_info "GIM installation detected: $UNINSTALL_PL"

#############################################
# Run the vendor uninstaller (IBM's own supported removal path - stops
# services, deregisters from the collector, and removes only what GIM
# installed). Must be invoked by absolute path; prompts for confirmation
# on stdin, so feed it "y" answers to run non-interactively.
# Uses heredoc mode (not a quoted arg) so ssh_exec wraps the *entire* piped
# command in `sudo bash -c '...'` - a plain sudo-prefixed pipe would only
# apply sudo to the first stage (yes), leaving perl running unprivileged.
#############################################
log_info "Running vendor uninstaller: $UNINSTALL_PL..."
set +e; trap '' ERR  # A non-zero exit here is inspected and handled below, not a script error
UNINSTALL_OUT=$(ssh_exec <<EOF 2>&1
yes | perl '${UNINSTALL_PL}'
EOF
)
UNINSTALL_EXIT=$?
set -e; trap 'log_error "Script failed at line $LINENO" "Command: $BASH_COMMAND"; log_summary "FAILED" "Script error at line $LINENO"; exit 1' ERR
echo "$UNINSTALL_OUT" >> "$LOG_FILE"
if [[ "$UNINSTALL_EXIT" == "0" ]]; then
  log_success "Vendor uninstaller completed"
else
  log_warn "Vendor uninstaller exited with code $UNINSTALL_EXIT (see log for output); continuing with fallback cleanup"
fi

#############################################
# Fallback cleanup: stop/disable the service and remove its systemd unit
# file if the vendor uninstaller left anything behind. Targeted and safe -
# deliberately NOT a blanket `rm -rf $INSTALL_DIR`, since INSTALL_DIR is
# often a shared system directory (e.g. /usr/local), not GIM-exclusive.
#############################################
log_info "Checking GIM service state..."
set +e
SERVICE_STATUS=$(ssh_exec "systemctl is-active guard_gim 2>/dev/null || echo 'inactive'" 2>/dev/null || echo "unknown")
set -e

if [[ "$SERVICE_STATUS" == "active" ]]; then
  log_info "GIM service still running, stopping it..."
  ssh_exec "systemctl stop guard_gim" || log_warn "Failed to stop guard_gim service (may already be stopped)"
  sleep 2
  log_success "GIM service stopped"
else
  log_info "GIM service is not running (status: ${SERVICE_STATUS})"
fi

set +e
ssh_exec "systemctl disable guard_gim 2>/dev/null" || true
set -e

set +e
if ssh_exec "test -f /etc/systemd/system/guard_gim.service" 2>/dev/null; then
  ssh_exec "rm -f /etc/systemd/system/guard_gim.service"
  ssh_exec "systemctl daemon-reload 2>/dev/null" || true
  log_success "Systemd service file removed"
fi
set -e

#############################################
# Clean up temporary files
#############################################
log_info "Cleaning up temporary files..."
set +e
ssh_exec "rm -rf /tmp/guardium_gim 2>/dev/null" || true
ssh_exec "rm -f /tmp/config.all 2>/dev/null" || true
ssh_exec "rm -f /tmp/*.gim.sh 2>/dev/null" || true
set -e
log_success "Temporary files cleaned up"

#############################################
# Clean up log files (optional)
#############################################
log_info "Checking for Guardium log files..."
set +e
LOG_FILES=$(ssh_exec "find /var/log -name '*guardium*' -o -name '*gim*' 2>/dev/null | head -10" 2>/dev/null || echo "")
if [[ -n "$LOG_FILES" ]]; then
  log_info "Found Guardium log files (not removing - may contain useful information):"
  echo "$LOG_FILES" | while read -r logfile; do
    log_info "  - $logfile"
  done
else
  log_info "No Guardium log files found in /var/log"
fi
set -e

#############################################
# Summary
#############################################
log_success "GIM uninstallation completed successfully"
log_summary "SUCCESS" "GIM uninstalled and cleaned up"

exit 0
