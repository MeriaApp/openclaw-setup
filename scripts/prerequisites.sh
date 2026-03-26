#!/bin/bash
set -euo pipefail

echo "================================================"
echo "  OpenClaw Prerequisites"
echo "================================================"
echo ""

# Check macOS
if [[ "$(uname)" != "Darwin" ]]; then
  echo "ERROR: This setup is designed for macOS. Detected: $(uname)"
  exit 1
fi

# Check Apple Silicon
ARCH=$(uname -m)
if [[ "$ARCH" != "arm64" ]]; then
  echo "WARNING: Expected Apple Silicon (arm64), detected: $ARCH"
  echo "Continuing, but performance may vary."
fi

# Check macOS version
MACOS_VERSION=$(sw_vers -productVersion)
MAJOR_VERSION=$(echo "$MACOS_VERSION" | cut -d. -f1)
if [[ "$MAJOR_VERSION" -lt 15 ]]; then
  echo "WARNING: macOS 15+ recommended. Detected: $MACOS_VERSION"
fi

echo "System: macOS $MACOS_VERSION ($ARCH)"
echo ""

# Install Homebrew if missing
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Homebrew: $(brew --version | head -1)"
fi

# Install Node.js if missing or outdated
if ! command -v node &>/dev/null; then
  echo "Installing Node.js..."
  brew install node
else
  NODE_MAJOR=$(node -v | cut -d. -f1 | tr -d 'v')
  if [[ "$NODE_MAJOR" -lt 20 ]]; then
    echo "Upgrading Node.js (need v20+, have v$(node -v))..."
    brew upgrade node
  else
    echo "Node.js: $(node -v)"
  fi
fi

# Install jq if missing
if ! command -v jq &>/dev/null; then
  echo "Installing jq..."
  brew install jq
else
  echo "jq: $(jq --version)"
fi

# Install OpenClaw
echo ""
echo "Installing OpenClaw..."
npm install -g openclaw

OPENCLAW_VERSION=$(openclaw --version 2>/dev/null || echo "unknown")
echo ""
echo "OpenClaw installed: $OPENCLAW_VERSION"

# Version safety check
echo ""
echo "================================================"
echo "  IMPORTANT: Version Check"
echo "================================================"
echo ""
echo "Installed version: $OPENCLAW_VERSION"
echo ""
echo "Before proceeding, verify this is the latest stable version:"
echo "  https://github.com/openclaw/openclaw/releases"
echo ""
echo "Must be >= 2026.1.29 (CVE-2026-25253 patch)"
echo ""
echo "Prerequisites complete."
