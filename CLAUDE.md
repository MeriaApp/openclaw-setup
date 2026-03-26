# OpenClaw Safe Setup — Instructions for Claude Code

**You are setting up OpenClaw on a Mac Mini (or any always-on Mac).** Follow every step in order. Do not skip steps. Do not improvise — run the provided scripts and configs, but FIRST check online for the latest versions and best practices.

---

## Pre-Flight: Check for Latest

**BEFORE running any install commands, do this:**

1. Search the web for "OpenClaw latest version" followed by the current month and year
2. Search for "OpenClaw security advisories 2026"
3. Search for "OpenClaw Mac Mini setup guide latest"
4. Compare what you find against the versions and configs in this folder
5. If anything is outdated, tell the user what changed and update accordingly

**The goal:** This setup should always reflect the latest stable release, patched against all known CVEs, using current best-practice config. Never install a version with known unpatched vulnerabilities.

---

## Step 0: Hardware Check

Confirm with the user:
- [ ] Mac Mini M4 (or any always-on Mac with Apple Silicon)
- [ ] 16GB RAM minimum
- [ ] macOS 15+ (Sequoia or later)
- [ ] Connected to power and ethernet (WiFi is fine but ethernet is more reliable for 24/7)
- [ ] User has admin access to this machine

If this is the user's daily driver (not a dedicated machine), **warn them**: running OpenClaw on your personal Mac is less secure. A dedicated machine is strongly recommended. If they proceed anyway, the dedicated user account in Step 2 provides partial isolation.

---

## Step 1: Prerequisites

Run `scripts/prerequisites.sh` — it installs:
- Node.js 20+ (via Homebrew if not present)
- jq (for JSON processing)
- OpenClaw itself (via npm)

```bash
bash scripts/prerequisites.sh
```

After running, verify:
```bash
openclaw --version
node --version
jq --version
```

**Check online:** Is the installed OpenClaw version the latest stable? Is it >= 2026.1.29 (the CVE-2026-25253 patch)?

---

## Step 2: Dedicated User Account

Run `scripts/create-user.sh` — it creates a standard (non-admin) `openclaw` macOS user with its own home directory and keychain.

```bash
sudo bash scripts/create-user.sh
```

**Why:** The agent gets its own home directory, keychain, and file permissions. If it's compromised, your personal data is untouched.

After running, verify:
```bash
id openclaw
ls -la /Users/openclaw
```

---

## Step 3: Security Hardening

Run `scripts/harden.sh` as the openclaw user — it:
- Sets file permissions (700 on ~/.openclaw, 600 on config files)
- Enables the macOS firewall
- Copies the secure base config from `config/openclaw.json`
- Sets up loopback-only network binding
- Configures DM pairing mode (strangers must pair with a code)

```bash
sudo -u openclaw -i bash $(pwd)/scripts/harden.sh
```

After running, verify:
```bash
sudo -u openclaw ls -la /Users/openclaw/.openclaw/
sudo -u openclaw cat /Users/openclaw/.openclaw/openclaw.json | jq '.gateway.bind'
# Should show "loopback"
```

---

## Step 4: API Keys

**Ask the user for each key in chat.** Never hardcode keys. Never store in plaintext config.

Required:
- LLM API key (one of: Anthropic `sk-ant-...`, OpenAI `sk-...`, or Google `AIza...`)
- Tavily API key (`tvly-...`) — for web search (free at https://tavily.com)
- Telegram Bot Token (from @BotFather) — if using Telegram
- The user's Telegram numeric ID (from @userinfobot) — for the allowlist

**IMPORTANT: Do NOT run setup-keys.sh interactively** — Claude Code cannot type into `read` prompts. Instead, ask the user for each key in chat, then write the .env file directly:

```bash
sudo -u openclaw -i bash -c 'cat > /Users/openclaw/.openclaw/.env << EOF
ANTHROPIC_API_KEY=<key from user>
TAVILY_API_KEY=<key from user>
TELEGRAM_BOT_TOKEN=<key from user>
EOF
chmod 600 /Users/openclaw/.openclaw/.env'
```

**Check online:** Search for "OpenClaw .env format" with the current year to confirm the environment variable names haven't changed.

---

## Step 5: Messaging Channel

Ask the user which messaging app they want:
- **Telegram** (recommended — easiest setup)
- Signal
- Discord
- WhatsApp

For Telegram:
1. User creates a bot via @BotFather in Telegram
2. User sends a message to @userinfobot to get their numeric Telegram ID
3. These go into the .env and the allowlist in openclaw.json

Run:
```bash
sudo -u openclaw bash scripts/setup-telegram.sh
```

---

## Step 6: Install Daemon

Run `scripts/install-daemon.sh` — it:
- Copies the launchd plist from `config/ai.openclaw.gateway.plist`
- Configures auto-start on boot
- Configures auto-restart on crash
- Sets up log rotation

```bash
sudo -u openclaw -i bash $(pwd)/scripts/install-daemon.sh
```

After running, verify the daemon is active:
```bash
sudo -u openclaw launchctl list | grep openclaw
sudo -u openclaw openclaw status
```

---

## Step 7: Install Skills

Run `scripts/install-skills.sh` — it installs the recommended safe skill set:

1. **clawsec-suite** — Security scanner (install this FIRST)
2. **tavily-search** — AI-optimized web search
3. **gog** — Google Workspace (Gmail, Calendar, Drive)
4. **apple-reminders** — Native macOS reminders

```bash
sudo -u openclaw -i bash $(pwd)/scripts/install-skills.sh
```

**Check online:** Before each install, search for "[skill-name] OpenClaw security issues 2026" to verify no known problems.

After installing, run the security audit:
```bash
sudo -u openclaw openclaw security audit --deep
```

**Ask the user** if they want additional skills:
- `shopify` — e-commerce monitoring
- `supabase` — database queries
- `n8n` — workflow automation
- `alpaca-trading` — stock trading (paper mode only to start)
- `x-twitter` — social monitoring

Install only what they need. Each additional skill increases attack surface.

---

## Step 8: Verify Everything

Run `scripts/verify.sh` — it checks:
- OpenClaw version is latest and patched
- Daemon is running
- Config permissions are correct
- Network is loopback-only
- DM policy is pairing or allowlist
- No plaintext secrets in config files
- All installed skills pass security audit

```bash
sudo -u openclaw -i bash $(pwd)/scripts/verify.sh
```

If anything fails, the script tells you exactly what to fix.

---

## Step 9: Test It

**Tell the user to test these in Telegram** (Claude Code cannot interact with Telegram directly):

1. Open Telegram and message the bot: "Hello, are you running?"
2. Complete the pairing process if prompted (enter the 6-digit code shown in the logs)
3. Send: "What time is it?"
4. Send: "Search the web for today's top tech news"

Ask the user to report back whether all three worked. If not, check the logs:
```bash
sudo -u openclaw -i tail -50 /Users/openclaw/.openclaw/logs/openclaw-error.log
```

---

## Step 10: Daily Briefing (Optional)

Ask the user if they want a daily morning briefing. If yes, run:
```bash
sudo -u openclaw -i bash $(pwd)/scripts/setup-briefing.sh
```

This configures a cron job that runs at 7am and sends a Telegram summary of:
- Weather
- Calendar for the day
- Unread email count
- Any custom data sources they configure later

---

## Post-Setup Maintenance

Tell the user:
- **Updates:** Run `npm update -g openclaw` monthly. Always check release notes for breaking changes.
- **Security audit:** Run `openclaw security audit --deep` weekly.
- **Skill updates:** Run `npx clawhub update --all` monthly. Review changelogs.
- **Log review:** Check `~/.openclaw/logs/` periodically for errors or suspicious activity.
- **CVE monitoring:** Search "OpenClaw CVE" monthly. Patch immediately.

---

## If Something Goes Wrong

- **Agent not responding:** `sudo -u openclaw launchctl kickstart -k gui/$(id -u openclaw)/ai.openclaw.gateway`
- **Suspicious activity:** `sudo -u openclaw openclaw stop && openclaw security audit --deep`
- **Compromised keys:** Rotate ALL API keys immediately, then restart.
- **Full reset:** `sudo -u openclaw -i rm -rf /Users/openclaw/.openclaw` then redo from Step 3
