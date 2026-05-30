#!/usr/bin/env bash
# Smart wrapper: ensures the GHL MCP server is installed under
# $CLAUDE_PLUGIN_DATA, applies the local patch, then execs it.
#
# Idempotent — first run takes ~3 min (git clone + npm install + build);
# subsequent runs are instant.

set -euo pipefail

MCP_DIR="${CLAUDE_PLUGIN_DATA}/ghl-mcp"
MAIN="${MCP_DIR}/dist/main.js"
PATCH="${CLAUDE_PLUGIN_ROOT}/patches/workflow-builder-client.diff"
STAMP="${MCP_DIR}/.patched"

log() { echo "[ghl-plugin] $*" >&2; }

if [[ ! -f "$MAIN" ]]; then
  log "First run — installing GHL MCP under $MCP_DIR (~3 min)…"
  mkdir -p "$(dirname "$MCP_DIR")"
  if [[ ! -d "$MCP_DIR/.git" ]]; then
    git clone --depth 1 \
      https://github.com/BusyBee3333/Go-High-Level-MCP-2026-Complete.git \
      "$MCP_DIR" >&2
  fi
  cd "$MCP_DIR"
  npm install --silent >&2
  if [[ -f "$PATCH" && ! -f "$STAMP" ]]; then
    log "Applying local patch for workflow chain handling…"
    git apply "$PATCH" >&2 || log "Patch already applied or conflicting, skipping."
    touch "$STAMP"
  fi
  npm run build --silent >&2
  log "Setup complete."
fi

exec node "$MAIN"
