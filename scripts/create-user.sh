#!/bin/bash
set -euo pipefail

echo "================================================"
echo "  Create Dedicated OpenClaw User"
echo "================================================"
echo ""

OPENCLAW_USER="openclaw"

# Check if running as root/sudo
if [[ "$EUID" -ne 0 ]]; then
  echo "ERROR: This script must be run with sudo."
  echo "Usage: sudo bash scripts/create-user.sh"
  exit 1
fi

# Check if user already exists
if id "$OPENCLAW_USER" &>/dev/null; then
  echo "User '$OPENCLAW_USER' already exists."
  echo "UID: $(id -u $OPENCLAW_USER)"
  echo "Home: $(dscl . -read /Users/$OPENCLAW_USER NFSHomeDirectory | awk '{print $2}')"
  echo ""
  echo "Skipping user creation. If you want to recreate, delete first:"
  echo "  sudo dscl . -delete /Users/$OPENCLAW_USER"
  echo "  sudo rm -rf /Users/$OPENCLAW_USER"
  exit 0
fi

# Find next available UID (above 500 to avoid system accounts)
NEXT_UID=$(dscl . -list /Users UniqueID | awk '$2 >= 500 {print $2}' | sort -n | tail -1 | awk '{print $1+1}')
if [[ -z "$NEXT_UID" || "$NEXT_UID" -lt 501 ]]; then
  NEXT_UID=501
fi

echo "Creating user: $OPENCLAW_USER (UID: $NEXT_UID)"
echo ""

# Create the user record
dscl . -create /Users/$OPENCLAW_USER
dscl . -create /Users/$OPENCLAW_USER UserShell /bin/zsh
dscl . -create /Users/$OPENCLAW_USER RealName "OpenClaw AI Agent"
dscl . -create /Users/$OPENCLAW_USER UniqueID "$NEXT_UID"
dscl . -create /Users/$OPENCLAW_USER PrimaryGroupID 20  # staff group, NOT admin
dscl . -create /Users/$OPENCLAW_USER NFSHomeDirectory /Users/$OPENCLAW_USER

# Create home directory
createhomedir -c -u $OPENCLAW_USER 2>/dev/null || mkdir -p /Users/$OPENCLAW_USER

# Set ownership
chown -R $OPENCLAW_USER:staff /Users/$OPENCLAW_USER

# Set a random password (user won't need to log in interactively)
RANDOM_PASS=$(openssl rand -base64 24)
dscl . -passwd /Users/$OPENCLAW_USER "$RANDOM_PASS"

# Hide user from login screen (optional, keeps login screen clean)
dscl . -create /Users/$OPENCLAW_USER IsHidden 1

echo "User created successfully."
echo ""
echo "  Username: $OPENCLAW_USER"
echo "  UID:      $NEXT_UID"
echo "  Group:    staff (standard, NOT admin)"
echo "  Home:     /Users/$OPENCLAW_USER"
echo "  Shell:    /bin/zsh"
echo "  Login:    Hidden from login screen"
echo ""
echo "Password has been set randomly. Use 'sudo -u openclaw' to run commands."
echo ""
echo "To switch to this user: sudo -u openclaw -i"
