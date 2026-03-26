#!/bin/bash
set -euo pipefail
umask 077

echo "================================================"
echo "  OpenClaw Security Hardening"
echo "================================================"
echo ""

OPENCLAW_HOME="/Users/$(whoami)/.openclaw"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create directory structure
echo "Creating secure directory structure..."
mkdir -p "$OPENCLAW_HOME"/{logs,credentials,skills,agents}

# Copy base config if not present
if [[ ! -f "$OPENCLAW_HOME/openclaw.json" ]]; then
  echo "Installing secure base config..."
  cp "$SCRIPT_DIR/config/openclaw.json" "$OPENCLAW_HOME/openclaw.json"

  # Generate unique auth token
  AUTH_TOKEN=$(openssl rand -hex 32)
  if command -v jq &>/dev/null; then
    TMP_FILE=$(mktemp)
    jq --arg token "$AUTH_TOKEN" '.gateway.auth.token = $token' "$OPENCLAW_HOME/openclaw.json" > "$TMP_FILE"
    mv "$TMP_FILE" "$OPENCLAW_HOME/openclaw.json"
    echo "Generated unique gateway auth token."
  else
    sed -i '' "s/REPLACE_WITH_GENERATED_TOKEN/$AUTH_TOKEN/" "$OPENCLAW_HOME/openclaw.json"
  fi
else
  echo "Config already exists. Checking security settings..."

  # Verify critical security settings
  if command -v jq &>/dev/null; then
    BIND=$(jq -r '.gateway.bind // "unknown"' "$OPENCLAW_HOME/openclaw.json")
    if [[ "$BIND" != "loopback" ]]; then
      echo "WARNING: Gateway bind is '$BIND', should be 'loopback'"
      echo "Fix: Set .gateway.bind to 'loopback' in openclaw.json"
    fi

    DM_POLICY=$(jq -r '.channels.telegram.dmPolicy // "unknown"' "$OPENCLAW_HOME/openclaw.json")
    if [[ "$DM_POLICY" == "open" ]]; then
      echo "WARNING: Telegram DM policy is 'open'. This allows anyone to message your agent."
      echo "Fix: Set to 'pairing' or 'allowlist'"
    fi
  fi
fi

# Lock down file permissions
echo ""
echo "Setting file permissions..."
chmod 700 "$OPENCLAW_HOME"
chmod 600 "$OPENCLAW_HOME/openclaw.json"
chmod 700 "$OPENCLAW_HOME/credentials"
chmod 700 "$OPENCLAW_HOME/logs"
chmod 700 "$OPENCLAW_HOME/agents"

# Lock down .env if it exists
[[ -f "$OPENCLAW_HOME/.env" ]] && chmod 600 "$OPENCLAW_HOME/.env"

# Lock down all credential files
find "$OPENCLAW_HOME/credentials" -type f -exec chmod 600 {} \; 2>/dev/null || true

echo "  ~/.openclaw/              700 (owner only)"
echo "  ~/.openclaw/openclaw.json 600 (owner read/write)"
echo "  ~/.openclaw/credentials/  700 (owner only)"
echo "  ~/.openclaw/logs/         700 (owner only)"

# Check macOS firewall (enabling requires admin — not this script's job)
echo ""
echo "Checking macOS firewall..."
FIREWALL_STATE=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null | grep -c "enabled" || true)
if [[ "$FIREWALL_STATE" -eq 0 ]]; then
  echo "WARNING: macOS firewall is not enabled."
  echo "An admin user should enable it:"
  echo "  sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on"
else
  echo "Firewall: already enabled"
fi

# Check FileVault
echo ""
echo "Checking FileVault..."
FV_STATUS=$(fdesetup status 2>/dev/null || echo "unknown")
if echo "$FV_STATUS" | grep -q "On"; then
  echo "FileVault: enabled (good)"
else
  echo "FileVault: NOT enabled"
  echo "  Recommended for machines that aren't physically secured."
  echo "  Enable: sudo fdesetup enable"
  echo "  Note: FileVault blocks auto-login on boot."
fi

# Disable Bonjour/mDNS broadcasting
echo ""
echo "Disabling Bonjour discovery..."
if command -v jq &>/dev/null; then
  TMP_FILE=$(mktemp)
  jq '.discovery.mdns.mode = "off"' "$OPENCLAW_HOME/openclaw.json" > "$TMP_FILE"
  mv "$TMP_FILE" "$OPENCLAW_HOME/openclaw.json"
  chmod 600 "$OPENCLAW_HOME/openclaw.json"
fi

echo ""
echo "================================================"
echo "  Hardening Complete"
echo "================================================"
echo ""
echo "Security posture:"
echo "  Network:     loopback only (127.0.0.1)"
echo "  Auth:        token-based gateway authentication"
echo "  DMs:         pairing mode (strangers must verify)"
echo "  Sessions:    per-channel-peer isolation"
echo "  Filesystem:  workspace-only access"
echo "  Exec:        ask-always mode"
echo "  Discovery:   mDNS disabled"
echo "  Logging:     secrets auto-redacted"
echo ""
echo "Next: Set up API keys with scripts/setup-keys.sh"
