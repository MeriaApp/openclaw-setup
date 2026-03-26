#!/bin/bash
set -euo pipefail

echo "================================================"
echo "  API Key Setup"
echo "================================================"
echo ""

OPENCLAW_HOME="${HOME}/.openclaw"
ENV_FILE="$OPENCLAW_HOME/.env"

# Create .env if it doesn't exist
if [[ ! -f "$ENV_FILE" ]]; then
  touch "$ENV_FILE"
  chmod 600 "$ENV_FILE"
fi

echo "This script stores API keys securely in ~/.openclaw/.env"
echo "Keys are never stored in openclaw.json or any config file."
echo ""

# Helper to set a key
set_key() {
  local KEY_NAME="$1"
  local PROMPT="$2"
  local REQUIRED="${3:-false}"

  # Check if already set
  if grep -q "^${KEY_NAME}=" "$ENV_FILE" 2>/dev/null; then
    echo "$KEY_NAME: already configured (skipping)"
    return
  fi

  echo ""
  if [[ "$REQUIRED" == "true" ]]; then
    echo "[REQUIRED] $PROMPT"
  else
    echo "[OPTIONAL] $PROMPT"
  fi

  read -rp "  Enter value (or press Enter to skip): " VALUE

  if [[ -n "$VALUE" ]]; then
    echo "${KEY_NAME}=${VALUE}" >> "$ENV_FILE"
    echo "  Saved."
  elif [[ "$REQUIRED" == "true" ]]; then
    echo "  WARNING: This key is required. You'll need to add it later."
    echo "  Edit: ~/.openclaw/.env"
  else
    echo "  Skipped."
  fi
}

# LLM Provider
echo "--- LLM Provider ---"
echo "OpenClaw needs at least one LLM API key."
echo "Recommended: Claude (Anthropic) for best quality."
echo ""

set_key "ANTHROPIC_API_KEY" "Anthropic API key (sk-ant-...)" "false"
set_key "OPENAI_API_KEY" "OpenAI API key (sk-...)" "false"
set_key "GOOGLE_AI_API_KEY" "Google AI API key" "false"

# Check at least one LLM key was set
if ! grep -qE "^(ANTHROPIC|OPENAI|GOOGLE_AI)_API_KEY=" "$ENV_FILE" 2>/dev/null; then
  echo ""
  echo "WARNING: No LLM API key configured. OpenClaw needs at least one."
  echo "Add one later: edit ~/.openclaw/.env"
fi

# Tavily (web search)
echo ""
echo "--- Web Search ---"
echo "Tavily provides AI-optimized search results."
echo "Free tier: 1,000 searches/month. Sign up: https://tavily.com"
echo ""

set_key "TAVILY_API_KEY" "Tavily API key (tvly-...)" "false"

# Telegram
echo ""
echo "--- Telegram Bot ---"
echo "Create a bot: message @BotFather on Telegram, send /newbot"
echo "Get your user ID: message @userinfobot on Telegram"
echo ""

set_key "TELEGRAM_BOT_TOKEN" "Telegram bot token (from @BotFather)" "false"

echo ""
echo "================================================"
echo "  Keys Saved"
echo "================================================"
echo ""
echo "Location: $ENV_FILE"
echo "Permissions: $(stat -f '%A' "$ENV_FILE") (should be 600)"
echo ""
echo "To edit later: nano ~/.openclaw/.env"
echo "To add more keys: re-run this script"
echo ""
echo "NEVER share this file. NEVER commit it to git."
