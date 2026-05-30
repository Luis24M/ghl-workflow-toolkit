#!/usr/bin/env bash
# Smart wrapper for the GHL MCP server inside this plugin.
#
# Order of operations:
# 1. Source ~/.ghl-workflow-toolkit/credentials.env if present (highest priority).
# 2. Otherwise fall back to env vars set by Claude Code from userConfig in .mcp.json.
# 3. If still missing required credentials, print a friendly error pointing the
#    user at the /ghl-workflow-toolkit:start wizard and exit cleanly.
# 4. Ensure the BusyBee3333 MCP is installed + patched + built under
#    $CLAUDE_PLUGIN_DATA/ghl-mcp (~3 min one-time cost). Subsequent runs: instant.
# 5. Exec node on dist/main.js.

set -euo pipefail

CREDS_FILE="${HOME}/.ghl-workflow-toolkit/credentials.env"
MCP_DIR="${CLAUDE_PLUGIN_DATA:-${HOME}/.claude/plugins/data/ghl-workflow-toolkit}/ghl-mcp"
MAIN="${MCP_DIR}/dist/main.js"
PATCH="${CLAUDE_PLUGIN_ROOT}/patches/workflow-builder-client.diff"
STAMP="${MCP_DIR}/.patched"

log() { echo "[ghl-plugin] $*" >&2; }

# 1) Credentials file overrides env vars from .mcp.json.
if [[ -f "$CREDS_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$CREDS_FILE"
  set +a
fi

# 2) Validate required credentials.
missing=()
[[ -z "${GHL_API_KEY:-}" ]] && missing+=("GHL_API_KEY (PIT)")
[[ -z "${GHL_LOCATION_ID:-}" ]] && missing+=("GHL_LOCATION_ID")
[[ -z "${GHL_FIREBASE_API_KEY:-}" ]] && missing+=("GHL_FIREBASE_API_KEY")
[[ -z "${GHL_FIREBASE_REFRESH_TOKEN:-}" ]] && missing+=("GHL_FIREBASE_REFRESH_TOKEN")

if [[ ${#missing[@]} -gt 0 ]]; then
  log ""
  log "=========================================================="
  log "  GHL Workflow Toolkit — credentials not configured yet."
  log "=========================================================="
  log ""
  log "  Missing: ${missing[*]}"
  log ""
  log "  Run this command in Claude Code to set them up:"
  log ""
  log "    /ghl-workflow-toolkit:start"
  log ""
  log "  Then restart Claude Code."
  log "=========================================================="
  log ""
  exit 1
fi

# 3) Install MCP on first run.
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
    log "Applying workflow-chain patch…"
    git apply "$PATCH" >&2 || log "Patch already applied or conflicting — skipping."
    touch "$STAMP"
  fi
  npm run build --silent >&2
  log "MCP server installed and built."
fi

# 4) Hand over to the MCP server (stdio JSON-RPC).
exec node "$MAIN"
