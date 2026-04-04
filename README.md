# Ubuntu Post-Installation Setup Script

A comprehensive, modular Bash script that automates Ubuntu post-installation setup. Install your favorite tools, configure your desktop environment, and get a fresh Ubuntu system ready for development in minutes.

## Quick Start

```bash
# One-line install (everything)
curl -fsSL https://raw.githubusercontent.com/enginyilmaaz/ubuntu-setup-script/main/ubuntu-setup.sh | bash -s -- --all

# Or clone and run
git clone https://github.com/enginyilmaaz/ubuntu-setup-script.git
cd ubuntu-setup-script
chmod +x ubuntu-setup.sh
./ubuntu-setup.sh --menu
```

## Features

| Flag | Description |
|------|-------------|
| `--all` | Install everything |
| `--menu` | Interactive menu to pick and choose |
| `--nodejs` | Node.js (via nvm) |
| `--python` | Python 3 + pip + venv |
| `--docker` | Docker Engine + Docker Compose |
| `--chrome` | Google Chrome |
| `--vscode` | Visual Studio Code |
| `--cursor` | Cursor IDE |
| `--claude-code` | Claude Code (AI coding assistant) |
| `--dbeaver` | DBeaver Community (database tool) |
| `--vlc` | VLC Media Player |
| `--vnc` | TigerVNC Server |
| `--rustdesk` | RustDesk (remote desktop) |
| `--cloudflared` | Cloudflare Tunnel |
| `--antigravity` | Antigravity theme |
| `--gnome` | GNOME desktop tweaks + extensions |
| `--remove-firefox` | Remove Firefox Snap |
| `--login` | CLI login helpers |
| `--jetson-fix` | NVIDIA Jetson compatibility fix |

## GNOME Backup & Restore

The script automatically backs up your GNOME settings before making changes.

```bash
# Show current backup
./ubuntu-setup.sh --show-backup-gnome

# Restore previous settings
./ubuntu-setup.sh --restore-gnome-desktop
```

## Combining Flags

Install only what you need:

```bash
./ubuntu-setup.sh --nodejs --docker --vscode --chrome
```

## Error Handling

The script uses an interactive error handler. If any step fails, you'll be prompted to either continue or abort -- no silent failures.

## Requirements

- Ubuntu 20.04+ (tested on 22.04 and 24.04)
- `sudo` access
- Internet connection

## License

MIT
