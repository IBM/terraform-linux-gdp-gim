#!/usr/bin/env bash
#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#
set -euo pipefail

# -------- Defaults (CRITICAL for -u) --------
MGMT_PORT="${MGMT_PORT:-22}"
SSH_KEY="${SSH_KEY:-}"
PASS="${PASS:-}"
USER="${USER:-root}"

# ------------------------------------------

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $*" | tee -a "$LOG_FILE"
}

central_append() {
  [ -z "${CENTRAL_LOG:-}" ] && return 0
  if [ ! -f "$CENTRAL_LOG" ]; then
    echo "timestamp,host,component,status,reason" > "$CENTRAL_LOG"
  fi
  echo "$1" >> "$CENTRAL_LOG"
}

bool_is_true() {
  case "$(echo "${1:-}" | tr '[:upper:]' '[:lower:]')" in
    1|true|yes|y) return 0;;
    *) return 1;;
  esac
}

SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=15"

remote_cmd() {
  local cmd="$1"
  local quoted
  quoted="$(printf '%q' "$cmd")"

  if [ -n "$SSH_KEY" ] && [ -f "$SSH_KEY" ]; then
    ssh -p "$MGMT_PORT" $SSH_OPTS -i "$SSH_KEY" "$USER@$HOST" "bash -lc $quoted"
  else
    sshpass -p "$PASS" ssh -p "$MGMT_PORT" $SSH_OPTS "$USER@$HOST" "bash -lc $quoted"
  fi
}

copy_file() {
  local src="$1" dst="$2"

  if [ -n "$SSH_KEY" ] && [ -f "$SSH_KEY" ]; then
    scp -P "$MGMT_PORT" $SSH_OPTS -i "$SSH_KEY" "$src" "$USER@$HOST:$dst"
  else
    sshpass -p "$PASS" scp -P "$MGMT_PORT" $SSH_OPTS "$src" "$USER@$HOST:$dst"
  fi
}

validate_port() {
  local host="$1" port="$2"

  if remote_cmd "command -v nc >/dev/null 2>&1"; then
    remote_cmd "nc -zv '$host' '$port'"
  elif remote_cmd "command -v ncat >/dev/null 2>&1"; then
    remote_cmd "ncat -zv '$host' '$port'"
  else
    log "WARN: nc/ncat not found – skipping port $port validation"
    return 0
  fi
}
