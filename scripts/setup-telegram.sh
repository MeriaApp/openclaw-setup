#!/bin/bash
set -euo pipefail
umask 077

echo "================================================"
echo "  Telegram Channel Setup"
echo "================================================"
echo ""

OPENCLAW_HOME="${HOME}/.openclaw"
CONFIG="$OPENCLAW_HOME/openclaw.json"

if [[ ! -f "$CONFIG" ]]; then
  echo "ERROR: openclaw.json not found. Run harden.sh first."
  exit 1
fi

# Check for bot token
if ! grep -q "TELEGRAM_BOT_TOKEN" "$OPENCLAW_HOME/.env" 2>/dev/null; then
  echo "No Telegram bot token found in .env"
  echo ""
  echo "Setup steps:"
  echo "  1. Open Telegram, message @BotFather"
  echo "  2. Send /newbot and follow the prompts"
  echo "  3. Copy the bot token"
  echo ""
  read -rp "Enter your Telegram bot token: " BOT_TOKEN
  if [[ -n "$BOT_TOKEN" ]]; then
    echo "TELEGRAM_BOT_TOKEN=${BOT_TOKEN}" >> "$OPENCLAW_HOME/.env"
    chmod 600 "$OPENCLAW_HOME/.env"
    echo "Token saved to .env"
  else
    echo "ERROR: Bot token is required for Telegram."
    exit 1
  fi
fi

# Set up allowlist
echo ""
echo "--- DM Allowlist ---"
echo ""
echo "Your Telegram user ID restricts who can message the bot."
echo "Get it: message @userinfobot on Telegram"
echo ""
read -rp "Enter your Telegram numeric user ID: " USER_ID

if [[ -n "$USER_ID" ]]; then
  # Update config with allowlist
  if command -v jq &>/dev/null; then
    TMP_FILE=$(mktemp)
    jq --argjson uid "$USER_ID" '
      .channels.telegram.dmPolicy = "allowlist" |
      .channels.telegram.allowFrom = [$uid]
    ' "$CONFIG" > "$TMP_FILE"
    mv "$TMP_FILE" "$CONFIG"
    chmod 600 "$CONFIG"
    echo ""
    echo "Allowlist configured: only user ID $USER_ID can message the bot."
    echo "DM policy upgraded from 'pairing' to 'allowlist' (strictest)."
  else
    echo "WARNING: jq not found. Manually add your ID to openclaw.json:"
    echo '  .channels.telegram.allowFrom = ['"$USER_ID"']'
  fi
else
  echo "No user ID provided. Keeping 'pairing' mode (strangers must verify with a code)."
fi

echo ""
echo "Telegram setup complete."
echo "Restart the daemon to apply: launchctl kickstart -k gui/\$(id -u)/ai.openclaw.gateway"
