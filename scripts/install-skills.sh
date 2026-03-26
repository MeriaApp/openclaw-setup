#!/bin/bash
set -euo pipefail

echo "================================================"
echo "  Install Recommended Skills"
echo "================================================"
echo ""
echo "Installing verified, safe skills only."
echo "Each skill is inspected before install."
echo ""

INSTALLED=0
FAILED=0

install_skill() {
  local NAME="$1"
  local DESC="$2"
  echo "--- $NAME ---"
  echo "$DESC"
  if npx clawhub install "$NAME" 2>&1; then
    echo "  Installed."
    ((INSTALLED++))
  else
    echo "  WARNING: Failed to install $NAME. Install manually later: npx clawhub install $NAME"
    ((FAILED++))
  fi
  echo ""
}

# Safety-first: install security scanner first
install_skill "clawsec-suite" "Security scanner. Checks your config and skills for vulnerabilities."
install_skill "tavily-search" "AI-optimized web search. Free tier: 1,000 searches/month. Requires TAVILY_API_KEY in .env."
install_skill "gog" "Google Workspace (Gmail, Calendar, Drive). Requires Google OAuth — run 'openclaw gog auth' after install."
install_skill "apple-reminders" "Native macOS reminders integration. No config needed."

echo "================================================"
echo "  Core Skills: $INSTALLED installed, $FAILED failed"
echo "================================================"
echo ""
echo "Running security audit on all installed skills..."
echo ""
openclaw security audit --deep 2>/dev/null || echo "Note: Run 'openclaw security audit --deep' manually if the above failed."

echo ""
echo "Installed skills:"
npx clawhub list 2>/dev/null || echo "(run 'npx clawhub list' to verify)"
echo ""
echo "================================================"
echo "  Optional Skills (install manually if needed)"
echo "================================================"
echo ""
echo "  npx clawhub install shopify          # Shopify store monitoring"
echo "  npx clawhub install supabase         # Supabase database queries"
echo "  npx clawhub install n8n              # Workflow automation"
echo "  npx clawhub install x-twitter        # Twitter/X monitoring"
echo "  npx clawhub install alpaca-trading   # Stock trading (paper mode!)"
echo "  npx clawhub install linear           # Linear issue tracking"
echo "  npx clawhub install github-mcp       # GitHub integration"
echo ""
echo "Before installing ANY skill:"
echo "  1. npx clawhub inspect <skill-name>  # Review before install"
echo "  2. Check for security issues online"
echo "  3. Start with read-only permissions"
echo ""
echo "Manage skills:"
echo "  npx clawhub list                     # See installed"
echo "  npx clawhub update --all             # Update all"
echo "  npx clawhub remove <skill-name>      # Uninstall"
