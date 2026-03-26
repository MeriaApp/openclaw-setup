# OpenClaw Safe Setup

A secure, scripted setup for OpenClaw on a Mac Mini. Every guardrail in place from the start.

Drop this folder into [Claude Code](https://claude.ai/code) and say **"set up OpenClaw using this guide"**. Claude walks you through every step, checks for the latest versions online, and configures everything.

Or follow the steps manually below.

---

## What This Does

- Creates a **dedicated macOS user** (isolated from your personal account)
- Installs OpenClaw with **loopback-only networking** (not exposed to the internet)
- Configures **token-based authentication** on the gateway
- Sets up **Telegram** as your messaging interface with DM allowlisting
- Installs a **launchd daemon** that auto-starts on boot and auto-restarts on crash
- Installs **4 verified skills** (security scanner, web search, Google Workspace, Apple Reminders)
- Runs a **full security verification** at the end
- Locks file permissions, disables Bonjour, and redacts secrets from logs

## What You Need

- Mac Mini M4 (or any always-on Mac with Apple Silicon)
- 16GB RAM
- macOS 15+
- Admin access
- One LLM API key (Anthropic, OpenAI, or Google)
- A Telegram account

## Quick Start (with Claude Code)

```
Open Claude Code in this directory and say:

"Set up OpenClaw on this machine using the CLAUDE.md guide"
```

Claude reads CLAUDE.md, runs each script in order, asks for your API keys, and verifies the setup. Takes about 10 minutes.

## Manual Setup

```bash
# cd into the setup folder first
cd openclaw-setup

# 1. Install prerequisites (Node.js, OpenClaw)
bash scripts/prerequisites.sh

# 2. Create dedicated user (requires sudo)
sudo bash scripts/create-user.sh

# 3. Security hardening + base config
sudo -u openclaw -i bash $(pwd)/scripts/harden.sh

# 4. Configure API keys (interactive prompts)
sudo -u openclaw -i bash $(pwd)/scripts/setup-keys.sh

# 5. Set up Telegram
sudo -u openclaw -i bash $(pwd)/scripts/setup-telegram.sh

# 6. Install daemon (auto-start on boot)
sudo -u openclaw -i bash $(pwd)/scripts/install-daemon.sh

# 7. Install safe skills
sudo -u openclaw -i bash $(pwd)/scripts/install-skills.sh

# 8. Verify everything
sudo -u openclaw -i bash $(pwd)/scripts/verify.sh

# 9. Optional: daily briefing
sudo -u openclaw -i bash $(pwd)/scripts/setup-briefing.sh
```

## Security Posture

| Layer | Setting |
|-------|---------|
| User | Dedicated non-admin `openclaw` account |
| Network | Loopback only (127.0.0.1) |
| Auth | Token-based gateway |
| DMs | Allowlist (only your Telegram ID) |
| Sessions | Per-channel-peer isolation |
| Filesystem | Workspace-only access |
| Exec | Ask-always mode |
| Discovery | mDNS/Bonjour disabled |
| Logging | API keys auto-redacted |
| Daemon | Auto-start, auto-restart, crash recovery |

## File Structure

```
openclaw-setup/
├── CLAUDE.md                    # Instructions for Claude Code
├── README.md                    # This file
├── config/
│   ├── openclaw.json            # Secure base config (copied during setup)
│   └── ai.openclaw.gateway.plist  # Daemon template (reference only)
└── scripts/
    ├── prerequisites.sh         # Install Node.js + OpenClaw
    ├── create-user.sh           # Create dedicated macOS user
    ├── harden.sh                # Security hardening + config
    ├── setup-keys.sh            # API key configuration
    ├── setup-telegram.sh        # Telegram bot + allowlist
    ├── install-daemon.sh        # launchd daemon setup
    ├── install-skills.sh        # Install verified skills
    ├── setup-briefing.sh        # Daily morning briefing (optional)
    └── verify.sh                # Post-setup verification
```

## Adding More Skills

```bash
# Inspect before installing
npx clawhub inspect <skill-name>

# Install
npx clawhub install <skill-name>

# Useful additions:
npx clawhub install shopify          # E-commerce monitoring
npx clawhub install supabase         # Database queries
npx clawhub install n8n              # Workflow automation
npx clawhub install alpaca-trading   # Stock trading (paper mode!)
npx clawhub install x-twitter        # Social monitoring
npx clawhub install github-mcp       # GitHub integration
```

Always run `openclaw security audit --deep` after installing new skills.

## Maintenance

| Task | Frequency | Command |
|------|-----------|---------|
| Update OpenClaw | Monthly | `npm update -g openclaw` |
| Update skills | Monthly | `npx clawhub update --all` |
| Security audit | Weekly | `openclaw security audit --deep` |
| Check logs | As needed | `tail -f ~/.openclaw/logs/openclaw.log` |
| Check CVEs | Monthly | Search "OpenClaw CVE 2026" |

## Why Mac Mini

| Factor | Why |
|--------|-----|
| Always-on | Runs as a daemon — boots, runs, restarts automatically |
| Power | ~5W idle, ~$1/month electricity |
| Silent | Fanless at agent workloads |
| Isolation | Separate machine, separate account, separate keychain |
| Price | M4 16GB is $500 |

## Known Issues

- **CVE-2026-25253** (patched in 2026.1.29): One-click RCE via WebSocket hijacking. The install script checks for this.
- **ClawHub malware** (Feb 2026): 1,184 malicious skills were purged. Only install verified skills. The security scanner checks for this.
- **macOS permissions**: After granting Full Disk Access / Accessibility, you must restart Terminal. The setup reminds you.

## License

MIT
