#!/bin/bash
set -euo pipefail

echo "================================================"
echo "  OpenClaw Setup Verification"
echo "================================================"
echo ""

OPENCLAW_HOME="${HOME}/.openclaw"
PASS=0
FAIL=0
WARN=0

check_pass() { echo "  PASS: $1"; ((PASS++)); }
check_fail() { echo "  FAIL: $1"; ((FAIL++)); }
check_warn() { echo "  WARN: $1"; ((WARN++)); }

# 1. OpenClaw installed and version check
echo "--- Version ---"
if command -v openclaw &>/dev/null; then
  VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
  check_pass "OpenClaw installed: $VERSION"

  # Check minimum safe version (proper semver comparison)
  MIN_VERSION="2026.1.29"
  if printf '%s\n' "$MIN_VERSION" "$VERSION" | sort -V | head -1 | grep -q "^${MIN_VERSION}$"; then
    check_pass "Version >= $MIN_VERSION (CVE-2026-25253 patched)"
  else
    check_fail "Version $VERSION may be vulnerable to CVE-2026-25253. Update: npm update -g openclaw"
  fi
else
  check_fail "OpenClaw not installed"
fi

# 2. Config exists and permissions
echo ""
echo "--- File Permissions ---"
if [[ -d "$OPENCLAW_HOME" ]]; then
  PERMS=$(stat -f '%A' "$OPENCLAW_HOME")
  if [[ "$PERMS" == "700" ]]; then
    check_pass "~/.openclaw/ permissions: $PERMS"
  else
    check_fail "~/.openclaw/ permissions: $PERMS (should be 700)"
  fi
else
  check_fail "~/.openclaw/ directory does not exist"
fi

if [[ -f "$OPENCLAW_HOME/openclaw.json" ]]; then
  PERMS=$(stat -f '%A' "$OPENCLAW_HOME/openclaw.json")
  if [[ "$PERMS" == "600" ]]; then
    check_pass "openclaw.json permissions: $PERMS"
  else
    check_fail "openclaw.json permissions: $PERMS (should be 600)"
  fi
else
  check_fail "openclaw.json does not exist"
fi

if [[ -f "$OPENCLAW_HOME/.env" ]]; then
  PERMS=$(stat -f '%A' "$OPENCLAW_HOME/.env")
  if [[ "$PERMS" == "600" ]]; then
    check_pass ".env permissions: $PERMS"
  else
    check_fail ".env permissions: $PERMS (should be 600)"
  fi
else
  check_warn ".env not found (API keys not configured yet?)"
fi

# 3. Network binding
echo ""
echo "--- Network Security ---"
if [[ -f "$OPENCLAW_HOME/openclaw.json" ]] && command -v jq &>/dev/null; then
  BIND=$(jq -r '.gateway.bind // "unknown"' "$OPENCLAW_HOME/openclaw.json")
  if [[ "$BIND" == "loopback" ]]; then
    check_pass "Gateway bind: loopback (127.0.0.1 only)"
  else
    check_fail "Gateway bind: $BIND (should be 'loopback')"
  fi

  AUTH_MODE=$(jq -r '.gateway.auth.mode // "none"' "$OPENCLAW_HOME/openclaw.json")
  if [[ "$AUTH_MODE" == "token" ]]; then
    TOKEN=$(jq -r '.gateway.auth.token // ""' "$OPENCLAW_HOME/openclaw.json")
    if [[ "$TOKEN" != "REPLACE_WITH_GENERATED_TOKEN" && -n "$TOKEN" ]]; then
      check_pass "Gateway auth: token (configured)"
    else
      check_fail "Gateway auth token not generated. Run harden.sh"
    fi
  else
    check_fail "Gateway auth mode: $AUTH_MODE (should be 'token')"
  fi
fi

# 4. DM policy
echo ""
echo "--- Messaging Security ---"
if [[ -f "$OPENCLAW_HOME/openclaw.json" ]] && command -v jq &>/dev/null; then
  DM_POLICY=$(jq -r '.channels.telegram.dmPolicy // "unknown"' "$OPENCLAW_HOME/openclaw.json")
  case "$DM_POLICY" in
    "allowlist") check_pass "Telegram DM policy: allowlist (strictest)" ;;
    "pairing")   check_pass "Telegram DM policy: pairing (secure)" ;;
    "disabled")  check_pass "Telegram DM policy: disabled" ;;
    "open")      check_fail "Telegram DM policy: OPEN (anyone can message!)" ;;
    *)           check_warn "Telegram DM policy: $DM_POLICY" ;;
  esac

  MDNS=$(jq -r '.discovery.mdns.mode // "unknown"' "$OPENCLAW_HOME/openclaw.json")
  if [[ "$MDNS" == "off" ]]; then
    check_pass "mDNS/Bonjour: disabled"
  else
    check_warn "mDNS/Bonjour: $MDNS (recommend 'off')"
  fi
fi

# 5. Daemon running
echo ""
echo "--- Daemon ---"
if launchctl list 2>/dev/null | grep -q "ai.openclaw.gateway"; then
  check_pass "Daemon: running"
else
  check_warn "Daemon: not running (may not be installed yet)"
fi

# 6. Firewall
echo ""
echo "--- System Security ---"
FW_STATE=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || echo "unknown")
if echo "$FW_STATE" | grep -q "enabled"; then
  check_pass "macOS firewall: enabled"
else
  check_warn "macOS firewall: not enabled"
fi

FV_STATUS=$(fdesetup status 2>/dev/null || echo "unknown")
if echo "$FV_STATUS" | grep -q "On"; then
  check_pass "FileVault: enabled"
else
  check_warn "FileVault: not enabled (recommended for physical security)"
fi

# 7. Plaintext secret scan
echo ""
echo "--- Secret Scan ---"
if [[ -f "$OPENCLAW_HOME/openclaw.json" ]]; then
  if grep -qE 'sk-ant-|sk-[a-zA-Z0-9]{20,}|Bearer ' "$OPENCLAW_HOME/openclaw.json" 2>/dev/null; then
    check_fail "Plaintext API keys found in openclaw.json! Move to .env"
  else
    check_pass "No plaintext secrets in openclaw.json"
  fi
fi

if [[ -d "$OPENCLAW_HOME/logs" ]]; then
  if grep -rqE 'sk-ant-|sk-[a-zA-Z0-9]{20,}' "$OPENCLAW_HOME/logs/" 2>/dev/null; then
    check_warn "Possible API keys found in log files. Review: ~/.openclaw/logs/"
  else
    check_pass "No secrets leaked in logs"
  fi
fi

# 8. Port check
echo ""
echo "--- Port Check ---"
if lsof -i :18789 &>/dev/null; then
  LISTENER=$(lsof -i :18789 -sTCP:LISTEN 2>/dev/null | grep -v COMMAND | awk '{print $1, $9}')
  if echo "$LISTENER" | grep -q "127.0.0.1\|localhost"; then
    check_pass "Port 18789: listening on localhost only"
  else
    check_warn "Port 18789: $LISTENER (verify this is loopback only)"
  fi
else
  check_warn "Port 18789: nothing listening (daemon may not be running)"
fi

# Summary
echo ""
echo "================================================"
echo "  Results: $PASS passed, $FAIL failed, $WARN warnings"
echo "================================================"
echo ""

if [[ "$FAIL" -gt 0 ]]; then
  echo "FIX the $FAIL failure(s) above before using OpenClaw."
  exit 1
elif [[ "$WARN" -gt 0 ]]; then
  echo "Setup is functional. Review the $WARN warning(s) above."
  exit 0
else
  echo "All checks passed. OpenClaw is ready."
  exit 0
fi
