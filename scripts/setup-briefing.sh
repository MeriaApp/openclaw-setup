#!/bin/bash
set -euo pipefail
umask 077

echo "================================================"
echo "  Daily Briefing Setup"
echo "================================================"
echo ""

OPENCLAW_HOME="${HOME}/.openclaw"

echo "This configures a daily morning briefing sent via Telegram."
echo ""
read -rp "What time? (24h format, e.g. 07:00): " BRIEFING_TIME
BRIEFING_TIME="${BRIEFING_TIME:-07:00}"

HOUR=$(echo "$BRIEFING_TIME" | cut -d: -f1)
MINUTE=$(echo "$BRIEFING_TIME" | cut -d: -f2)

echo ""
echo "What should the briefing include?"
echo "  1. Weather and calendar (default)"
echo "  2. Weather, calendar, and email summary"
echo "  3. Custom prompt"
echo ""
read -rp "Choice (1/2/3): " CHOICE
CHOICE="${CHOICE:-1}"

case "$CHOICE" in
  1)
    PROMPT="Good morning. Give me a briefing: today's weather for my location, and my calendar for today. Keep it concise."
    ;;
  2)
    PROMPT="Good morning. Give me a briefing: today's weather for my location, my calendar for today, and a summary of any important unread emails. Keep it concise."
    ;;
  3)
    echo ""
    read -rp "Enter your custom briefing prompt: " PROMPT
    ;;
esac

# Write cron config
if command -v jq &>/dev/null && [[ -f "$OPENCLAW_HOME/openclaw.json" ]]; then
  TMP_FILE=$(mktemp)
  jq --arg min "$MINUTE" --arg hr "$HOUR" --arg prompt "$PROMPT" '
    .cron = (.cron // []) + [{
      "schedule": ($min + " " + $hr + " * * 1-5"),
      "prompt": $prompt,
      "channel": "telegram",
      "enabled": true
    }]
  ' "$OPENCLAW_HOME/openclaw.json" > "$TMP_FILE"
  mv "$TMP_FILE" "$OPENCLAW_HOME/openclaw.json"
  chmod 600 "$OPENCLAW_HOME/openclaw.json"

  echo ""
  echo "Daily briefing configured."
  echo "  Time: $BRIEFING_TIME (weekdays)"
  echo "  Channel: Telegram"
  echo ""
  echo "Restart daemon to apply:"
  echo "  launchctl kickstart -k gui/\$(id -u)/ai.openclaw.gateway"
else
  echo "ERROR: jq or openclaw.json not found."
  echo "Add this manually to openclaw.json:"
  echo ""
  echo '  "cron": [{'
  echo "    \"schedule\": \"$MINUTE $HOUR * * 1-5\","
  echo "    \"prompt\": \"$PROMPT\","
  echo '    "channel": "telegram",'
  echo '    "enabled": true'
  echo '  }]'
fi
