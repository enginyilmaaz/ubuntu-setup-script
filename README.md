# Ubuntu Post-Installation Setup Script

A comprehensive, modular Bash script that automates Ubuntu post-installation setup. Install your favorite tools, configure your desktop environment, debloat the system, and get a fresh Ubuntu machine ready for development in minutes — from a single command.

**Version:** 2.5.0 (rev-178)

## 🚀 Quick Start

Install straight from the Gist — **no cloning required**. The short link is the recommended way:

```bash
# Recommended — interactive menu (pick & choose)
curl -fsSL https://bit.ly/ubuntu-ey | bash -s -- --menu

# Or install everything at once
curl -fsSL https://bit.ly/ubuntu-ey | bash -s -- --all
```

<details>
<summary>Full Gist URL (use this if the short link is unavailable)</summary>

```bash
# Interactive menu
curl -fsSL https://gist.githubusercontent.com/enginyilmaaz/deb328012eaa1d74e050724db74d2377/raw/ubuntu-setup.sh | bash -s -- --menu

# Everything
curl -fsSL https://gist.githubusercontent.com/enginyilmaaz/deb328012eaa1d74e050724db74d2377/raw/ubuntu-setup.sh | bash -s -- --all
```
</details>

> The interactive menu reads from your terminal (`/dev/tty`), so it works correctly even through `curl | bash`.

## 🔗 Links

The script is available in **both** places — install from the Gist, browse the source in the repo:

| | URL |
|------|-----|
| **Gist** (quick install) | https://gist.github.com/enginyilmaaz/deb328012eaa1d74e050724db74d2377 |
| **Repository** (source) | https://github.com/enginyilmaaz/ubuntu-setup-script |
| **Gist ID** | `deb328012eaa1d74e050724db74d2377` |

## ✨ Capabilities

Everything below is reachable through the interactive menu (`--menu`) or directly via its flag.

### 🧰 Core Apps & Tools

| Flag | Installs |
|------|----------|
| `--all` | Install everything (non-interactive) |
| `--menu` | Interactive menu to pick & choose |
| `--nodejs` | Node.js 22 via NVM (NVM ⇄ native switch available in Tweaks) |
| `--python` | Python 3 + pip + venv |
| `--docker` | Docker Engine + Compose plugin |
| `--chrome` | Google Chrome |
| `--vscode` | Visual Studio Code (+ extensions submenu) |
| `--dbeaver` | DBeaver Community (database tool) |
| `--vlc` | VLC Media Player |
| `--cloudflared` | Cloudflare Tunnel client |
| `--gh` | GitHub CLI (`gh`) |
| `--postman` | Postman |
| `--filezilla` | FileZilla (FTP/SFTP client) |
| `--localsend` | LocalSend (local-network file sharing) |
| `--gnome` | GNOME desktop tweaks + extensions (submenu) |
| `--debloat` | Remove pre-installed bloat (submenu) |
| `--remove-firefox` | Remove Firefox Snap |
| `--jetson-fix` | NVIDIA Jetson / ARM `snapd` compatibility fix |
| `--login` | CLI login helpers |

### 🤖 AI CLI Tools

Grouped under **AI CLI Tools** in the interactive menu, or install directly:

| Flag | Tool |
|------|------|
| `--claude` | **Claude Code** — Anthropic CLI (native installer) |
| `--codex` | **Codex** — OpenAI CLI (`@openai/codex`) |
| `--kimi` | **Kimi Code** — Moonshot AI CLI |
| `--grok` | **Grok** — xAI CLI |
| `--gemini` | **Gemini CLI** — Google |
| `--qwen` | **Qwen Code** — Alibaba |

### 🖥️ Remote Support Tools

| Flag | Tool |
|------|------|
| `--vnc` | RealVNC Connect (commercial, free plan) |
| `--anydesk` | AnyDesk (fast, lightweight) |
| `--rustdesk` | RustDesk (open source, self-host) |
| `--teamviewer` | TeamViewer (commercial, free personal) |

### 🎨 GNOME Tweaks (`--gnome`)

<details>
<summary>20 desktop tweaks &amp; extensions — click to expand</summary>

| Tweak | What it does |
|-------|--------------|
| Extensions | Extension Manager + Shell Extensions + AppIndicator |
| Update System | `sudo apt update && sudo apt upgrade -y` |
| GNOME Tweaks | GNOME Tweaks App + Browser Connector |
| Dash to Dock | Dock settings, single workspace, performance mode |
| Script Launcher | Right-click context menu (Claude, Codex, VS Code) |
| Disable Wayland | Switch to X11 (VNC/RDP compatibility) |
| Node.js: switch NVM ⇄ native | Shown only when Node.js is installed — swaps between NVM and native (NodeSource apt) |
| OpenSSH Server | Install + auto-start SSH server (port 22) |
| Change Hostname | Set the computer's hostname |
| Alias: ccskip | `claude --dangerously-skip-permissions --effort max --model claude-opus-5` |
| Alias: cxskip | `codex --sandbox danger-full-access` (xhigh) |
| Alias: cckimi | Claude Code on Kimi backend (+`cckimi-token` auto) |
| Alias: ccglm | Claude Code on Z.AI GLM backend (+`ccglm-token` auto) |
| Alias: ccort | Claude Code on the OpenRouter gateway (+`ccort-token` / `ccort-model` auto) — defaults to the free `stealth/ox-alpha`; run `ccort-model` for a numbered picker, or pass any id from [openrouter.ai/models](https://openrouter.ai/models) |
| Alias: ccart | Claude Code on the [AgentRouter](https://agentrouter.org) gateway (+`ccart-token` / `ccart-model` auto) — defaults to `claude-opus-5`; run `ccart-model` to pick from its catalogue |
| English Language | Set system language to English (US) |
| Screen Off: Never | Disable screen timeout + auto suspend |
| Show Hidden Files | Show hidden files in the file manager |
| Keyboard: Turkish Q | Add Turkish Q keyboard layout |
| Keyboard: English Q | Add English (US) keyboard layout |
| IBus Leak Fix | Disable ibus-daemon, use XKB only (fix memory leak) |
| Activate Apport | Install + enable Ubuntu crash reporting |
| Install Camera (Cheese) | Install the cheese webcam app |
| Virtual Screen 1080p | Create a virtual 1920×1080 display (VNC/RDP/headless) |
| Cleanup Period: 2Y | Auto-cleanup 730 days (Tweaks default is 365) |
| GDM Auto-Login | Auto-login to GUI on boot (needed for VNC tray icon) |

</details>

### 🧩 VS Code Extensions (`--vscode`)

Claude Code · Codex / ChatGPT · Python · Pylance · GitLens · Prettier · ESLint · Docker · Material Icon Theme · plus an **Apply Settings/Tweaks** option.

### 🧹 Debloat (`--debloat`)

Remove pre-installed games, apps and stacks you don't need — 50+ selectable items.

<details>
<summary>What can be removed — click to expand</summary>

- **Games:** Mahjongg, Solitaire (AisleRiot), Mines, Sudoku
- **Apps:** LibreOffice, Thunderbird, Remmina, GNOME To Do, Transmission, Shotwell, Document Scanner (Simple Scan), Rhythmbox, Totem (Videos), Cheese, Power Statistics, Calendar, Calculator, Fonts, Characters (gucharmap / GNOME Characters), XTerm, Vim
- **Stacks:** Printer stack (CUPS + HPLIP, ~200 MB), Extensions stack, Script Launcher extension
- **Remote:** RealVNC, AnyDesk, RustDesk, TeamViewer, RDP server (xrdp)
- **Dev tools:** Claude Code CLI, Codex CLI, VS Code, Node.js (NVM), Python pip, DBeaver, Docker, GitHub CLI, Postman, FileZilla, LocalSend, jtop
- **Browsers:** Google Chrome, Chromium (apt + snap), Firefox (APT / ESR), Firefox Snap
- **System:** Language packs, extra XKB keyboard layouts, virtual screen config, GDM auto-login, Apport, individual snaps, or **remove snap completely** (snaps + snapd + `/snap`, ~300 MB)

</details>

## 🎛️ Interactive Menu

Run without flags (or with `--menu`) for a keyboard-driven menu:

```bash
curl -fsSL https://bit.ly/ubuntu-ey | bash -s -- --menu
```

Navigate with **↑↓**, toggle with **SPACE**, `a` = all, `n` = none, `c`/`ESC` = save & continue, `q` = discard. Grouped items (AI CLI Tools, Remote Support Tools, GNOME Tweaks, VS Code, Debloat) open their own submenus.

## 💾 GNOME Backup & Restore

The script automatically backs up your GNOME settings before making changes.

```bash
# Show current backup
curl -fsSL https://bit.ly/ubuntu-ey | bash -s -- --show-backup-gnome

# Restore previous settings
curl -fsSL https://bit.ly/ubuntu-ey | bash -s -- --restore-gnome-desktop
```

## 🔀 Combining Flags

Install only what you need:

```bash
curl -fsSL https://bit.ly/ubuntu-ey | bash -s -- --nodejs --docker --vscode --chrome
```

## ⚠️ Error Handling

The script uses an interactive error handler. If any step fails, you're prompted to either continue or abort — no silent failures.

## 📋 Requirements

- Ubuntu 20.04+ (tested on 22.04 and 24.04)
- `sudo` access
- Internet connection

## License

MIT
