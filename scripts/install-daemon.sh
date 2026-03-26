#!/bin/bash
set -euo pipefail

echo "================================================"
echo "  Install OpenClaw Daemon"
echo "================================================"
echo ""

OPENCLAW_HOME="${HOME}/.openclaw"
PLIST_NAME="ai.openclaw.gateway"
PLIST_DIR="${HOME}/Library/LaunchAgents"
PLIST_FILE="${PLIST_DIR}/${PLIST_NAME}.plist"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create log directory
mkdir -p "$OPENCLAW_HOME/logs"

# Find openclaw binary
OPENCLAW_BIN=$(which openclaw 2>/dev/null || echo "")
if [[ -z "$OPENCLAW_BIN" ]]; then
  # Check common npm global locations
  for BIN_PATH in /usr/local/bin/openclaw /opt/homebrew/bin/openclaw "${HOME}/.npm-global/bin/openclaw"; do
    if [[ -x "$BIN_PATH" ]]; then
      OPENCLAW_BIN="$BIN_PATH"
      break
    fi
  done
fi

if [[ -z "$OPENCLAW_BIN" ]]; then
  echo "ERROR: openclaw binary not found."
  echo "Run scripts/prerequisites.sh first."
  exit 1
fi

echo "OpenClaw binary: $OPENCLAW_BIN"

# Create LaunchAgents directory if needed
mkdir -p "$PLIST_DIR"

# Unload existing daemon if present
if launchctl list 2>/dev/null | grep -q "$PLIST_NAME"; then
  echo "Stopping existing daemon..."
  launchctl unload "$PLIST_FILE" 2>/dev/null || true
fi

# Generate plist with correct paths
cat > "$PLIST_FILE" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${PLIST_NAME}</string>

    <key>ProgramArguments</key>
    <array>
        <string>${OPENCLAW_BIN}</string>
        <string>gateway</string>
    </array>

    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>${HOME}</string>
        <key>OPENCLAW_HOME</key>
        <string>${HOME}</string>
        <key>OPENCLAW_STATE_DIR</key>
        <string>${OPENCLAW_HOME}</string>
        <key>PATH</key>
        <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
    </dict>

    <key>WorkingDirectory</key>
    <string>${HOME}</string>

    <key>StandardOutPath</key>
    <string>${OPENCLAW_HOME}/logs/openclaw.log</string>

    <key>StandardErrorPath</key>
    <string>${OPENCLAW_HOME}/logs/openclaw-error.log</string>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>ThrottleInterval</key>
    <integer>10</integer>

    <key>ProcessType</key>
    <string>Background</string>
</dict>
</plist>
EOF

echo "Daemon plist written to: $PLIST_FILE"

# Load the daemon
echo "Loading daemon..."
launchctl load "$PLIST_FILE"

# Verify
sleep 2
if launchctl list 2>/dev/null | grep -q "$PLIST_NAME"; then
  echo ""
  echo "Daemon is running."
else
  echo ""
  echo "WARNING: Daemon may not have started. Check logs:"
  echo "  cat $OPENCLAW_HOME/logs/openclaw-error.log"
fi

echo ""
echo "================================================"
echo "  Daemon Installed"
echo "================================================"
echo ""
echo "  Auto-starts on boot: yes"
echo "  Auto-restarts on crash: yes"
echo "  Logs: ~/.openclaw/logs/"
echo ""
echo "Commands:"
echo "  Status:  launchctl list | grep openclaw"
echo "  Stop:    launchctl unload $PLIST_FILE"
echo "  Start:   launchctl load $PLIST_FILE"
echo "  Restart: launchctl kickstart -k gui/\$(id -u)/$PLIST_NAME"
echo "  Logs:    tail -f ~/.openclaw/logs/openclaw.log"
