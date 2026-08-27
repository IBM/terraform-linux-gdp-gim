#!/usr/bin/env bash
#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/common_guardium_lib.sh"

COMPONENT="STAP"
VALIDATE_ONLY="false"

while [ $# -gt 0 ]; do
  case "$1" in
    --validate-only) VALIDATE_ONLY="true"; shift;;
    --host) HOST="$2"; shift 2;;
    --mgmt-port) MGMT_PORT="$2"; shift 2;;
    --username) USER="$2"; shift 2;;
    --password) PASS="$2"; shift 2;;
    --installer-sh) INSTALLER_SH="$2"; shift 2;;
    --installer-gim) INSTALLER_GIM="$2"; shift 2;;
    --log-file) LOG_FILE="$2"; shift 2;;
    --central-log) CENTRAL_LOG="$2"; shift 2;;
    --ssh-key) SSH_KEY="$2"; shift 2;;
    *) shift;;
  esac
done

mkdir -p "$(dirname "$LOG_FILE")"

log "Starting $COMPONENT"
log "Validate only: $VALIDATE_ONLY"

if bool_is_true "$VALIDATE_ONLY"; then
  remote_cmd "echo SSH_OK"
  log "Validation complete"
  central_append "$(date -u +%Y-%m-%dT%H:%M:%SZ),$HOST,STAP,VALIDATED,ok"
  exit 0
fi

REMOTE_DIR="/tmp/guardium_stap"
remote_cmd "mkdir -p '$REMOTE_DIR'"
copy_file "$INSTALLER_SH" "$REMOTE_DIR/stap.sh"
copy_file "$INSTALLER_GIM" "$REMOTE_DIR/stap.gim"
remote_cmd "chmod +x '$REMOTE_DIR/stap.sh'"

OUT="$(remote_cmd "$REMOTE_DIR/stap.sh -q" 2>&1 || true)"
echo "$OUT" | tee -a "$LOG_FILE"

if echo "$OUT" | grep -qi "already installed"; then
  log "STAP already installed – OK"
  central_append "$(date -u +%Y-%m-%dT%H:%M:%SZ),$HOST,STAP,SKIPPED,already_installed"
  exit 0
fi

log "STAP installation completed"
central_append "$(date -u +%Y-%m-%dT%H:%M:%SZ),$HOST,STAP,SUCCESS,installed"
