#!/bin/bash

#===============================================================================
# Ubuntu Post-Installation Setup Script
# Version: 2.5.0 (rev-53)
# Author: Smart Marine / enginyilmaaz
# Description: Automates Ubuntu post-installation setup with modular options
#
# Usage:
#   ./ubuntu-setup.sh --all                    # Install everything
#   ./ubuntu-setup.sh --nodejs --vscode        # Install specific apps
#   ./ubuntu-setup.sh --help                   # Show all options
#   ./ubuntu-setup.sh --show-backup-gnome      # Show GNOME backup
#   ./ubuntu-setup.sh --restore-gnome-desktop  # Restore GNOME settings
#   ./ubuntu-setup.sh --version                # Show version
#===============================================================================

SCRIPT_VERSION="2.5.0"
SCRIPT_REVISION="80"
SCRIPT_DATE="2026-03-27"

# NOTE: We intentionally do NOT use set -e here.
# Instead, errors are handled interactively via handle_error() so the user
# can decide whether to continue or abort.

# Backup directory
BACKUP_DIR="$HOME/.gnome_desktop_conf_backup"

# Command line flags - all default to false
INSTALL_ALL=false
INSTALL_VNC=false
INSTALL_RUSTDESK=false
INSTALL_NODEJS=false
INSTALL_CHROME=false
INSTALL_VSCODE=false
INSTALL_PYTHON=false
INSTALL_GNOME=false
INSTALL_DBEAVER=false
INSTALL_VLC=false
INSTALL_CLOUDFLARED=false
INSTALL_DOCKER=false
INSTALL_CLAUDE=false
INSTALL_GH=false
INSTALL_POSTMAN=false
INSTALL_FILEZILLA=false
DO_CLI_LOGIN=false
DO_REMOVE_FIREFOX=false

# Special commands
SHOW_BACKUP_GNOME=false
RESTORE_GNOME=false
SHOW_HELP=false
SHOW_MENU=false
APPLY_JETSON_FIX=false

# Parse command line arguments
for arg in "$@"; do
    case $arg in
        --all)
            INSTALL_ALL=true
            ;;
        --vnc)
            INSTALL_VNC=true
            ;;
        --rustdesk)
            INSTALL_RUSTDESK=true
            ;;
        --nodejs)
            INSTALL_NODEJS=true
            ;;
        --chrome)
            INSTALL_CHROME=true
            ;;
        --vscode)
            INSTALL_VSCODE=true
            ;;
        --python)
            INSTALL_PYTHON=true
            ;;
        --gnome)
            INSTALL_GNOME=true
            ;;
        --dbeaver)
            INSTALL_DBEAVER=true
            ;;
        --vlc)
            INSTALL_VLC=true
            ;;
        --cloudflared)
            INSTALL_CLOUDFLARED=true
            ;;
        --docker)
            INSTALL_DOCKER=true
            ;;
        --claude|--claude-code)
            INSTALL_CLAUDE=true
            ;;
        --gh|--github-cli)
            INSTALL_GH=true
            ;;
        --postman)
            INSTALL_POSTMAN=true
            ;;
        --filezilla)
            INSTALL_FILEZILLA=true
            ;;
        --login)
            DO_CLI_LOGIN=true
            ;;
        --remove-firefox)
            DO_REMOVE_FIREFOX=true
            ;;
        --show-backup-gnome)
            SHOW_BACKUP_GNOME=true
            ;;
        --restore-gnome-desktop)
            RESTORE_GNOME=true
            ;;
        --help|-h)
            SHOW_HELP=true
            ;;
        --menu)
            SHOW_MENU=true
            ;;
        --jetson-fix|--arm-fix)
            APPLY_JETSON_FIX=true
            ;;
        --version|-v)
            echo "Ubuntu Setup Script v${SCRIPT_VERSION} (rev-${SCRIPT_REVISION}) [${SCRIPT_DATE}]"
            exit 0
            ;;
        *)
            echo "Unknown option: $arg"
            echo "Use --help for available options"
            exit 1
            ;;
    esac
done

# If --all is set, enable all installations
if $INSTALL_ALL; then
    INSTALL_VNC=true
    INSTALL_RUSTDESK=true
    INSTALL_NODEJS=true
    INSTALL_CHROME=true
    INSTALL_VSCODE=true
    INSTALL_PYTHON=true
    INSTALL_GNOME=true
    INSTALL_DBEAVER=true
    INSTALL_VLC=true
    INSTALL_CLOUDFLARED=true
    INSTALL_DOCKER=true
    INSTALL_CLAUDE=true
    INSTALL_GH=true
    INSTALL_POSTMAN=true
    INSTALL_FILEZILLA=true
    DO_REMOVE_FIREFOX=true
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${CYAN}========================================${NC}"
    echo -e "${CYAN}[STEP]${NC} $1"
    echo -e "${CYAN}========================================${NC}\n"
}

# Interactive error handler - asks user whether to continue or abort
# Usage: some_command || handle_error "Description of what failed"
# Returns: 0 if user wants to continue, exits if user wants to abort
handle_error() {
    local error_msg="$1"
    echo ""
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${RED}[ERROR]${NC} $error_msg"
    echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "Do you want to continue? (y/n): " -n 1 -r < /dev/tty
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_error "Script aborted by user."
        exit 1
    fi
    log_info "Continuing despite error..."
    return 0
}

# Safe apt-get update - tolerates repo errors and asks user on failure
safe_apt_update() {
    if ! sudo apt-get update 2>&1 | tee /tmp/apt-update-output.tmp; then
        local errors
        errors=$(grep -i "err\|failed\|error" /tmp/apt-update-output.tmp 2>/dev/null || true)
        if [ -n "$errors" ]; then
            handle_error "apt-get update encountered errors:\n$errors"
        fi
    fi
    rm -f /tmp/apt-update-output.tmp
}

#===============================================================================
# Help Function
#===============================================================================
show_help() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              Ubuntu Post-Installation Setup Script                        ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}USAGE:${NC}"
    echo "  $0 [OPTIONS]"
    echo ""
    echo -e "${GREEN}INSTALLATION OPTIONS:${NC}"
    echo ""
    echo -e "  ${YELLOW}--all${NC}"
    echo "      Install everything (all options below)"
    echo ""
    echo -e "  ${YELLOW}--vnc${NC}"
    echo "      RealVNC Connect - Remote desktop server"
    echo "      - AMD64: Downloads .deb from realvnc.com"
    echo "      - ARM64: Downloads tar.gz installer"
    echo "      - Disables Wayland for VNC compatibility"
    echo ""
    echo -e "  ${YELLOW}--nodejs${NC}"
    echo "      Node.js development environment"
    echo "      - NVM (Node Version Manager)"
    echo "      - Node.js 22 LTS"
    echo "      - Yarn package manager"
    echo "      - CLI tools: codex"
    echo ""
    echo -e "  ${YELLOW}--chrome${NC}"
    echo "      Web browser"
    echo "      - AMD64: Google Chrome"
    echo "      - ARM64: Chromium (Chrome not available)"
    echo ""
    echo -e "  ${YELLOW}--vscode${NC}"
    echo "      Visual Studio Code"
    echo "      - VS Code from Microsoft apt repository"
    echo "      - Extensions: ESLint, Prettier, GitLens, Material Icon, Python"
    echo "      - User settings configuration"
    echo ""
    echo -e "  ${YELLOW}--python${NC}"
    echo "      Python 3 development environment"
    echo "      - python3, python3-pip, python3-venv"
    echo ""
    echo -e "  ${YELLOW}--gnome${NC}"
    echo "      GNOME Shell customization"
    echo "      - GNOME Shell Extensions"
    echo "      - Extension Manager, GNOME Tweaks"
    echo "      - Dash to Dock configuration"
    echo "      - ${CYAN}Creates backup before changes (~/.gnome_desktop_conf_backup/)${NC}"
    echo ""
    echo -e "  ${YELLOW}--dbeaver${NC}"
    echo "      DBeaver CE - Universal database tool"
    echo "      - AMD64: From dbeaver apt repository"
    echo "      - ARM64: Downloads arm64 .deb"
    echo ""
    echo -e "  ${YELLOW}--vlc${NC}"
    echo "      VLC Media Player"
    echo "      - Installed via apt"
    echo ""
    echo -e "  ${YELLOW}--cloudflared${NC}"
    echo "      Cloudflare Tunnel client"
    echo "      - From Cloudflare apt repository"
    echo ""
    echo -e "  ${YELLOW}--docker${NC}"
    echo "      Docker Engine"
    echo "      - Docker CE from official apt repository"
    echo "      - docker-compose-plugin included"
    echo "      - Adds user to docker group"
    echo ""
    echo -e "  ${YELLOW}--rustdesk${NC}"
    echo "      RustDesk - Open source remote desktop"
    echo "      - Downloads .deb from GitHub releases"
    echo "      - Supports AMD64 and ARM64"
    echo "      - Set password: rustdesk --password YOUR_PASSWORD"
    echo ""
    echo -e "  ${YELLOW}--claude${NC}"
    echo "      Claude Code - AI coding assistant CLI"
    echo "      - Native installer (no Node.js required)"
    echo "      - Auto-updates in background"
    echo ""
    echo -e "  ${YELLOW}--gh${NC}"
    echo "      GitHub CLI (gh)"
    echo "      - Official GitHub apt repository"
    echo "      - Manage repos, PRs, issues from terminal"
    echo ""
    echo -e "${GREEN}ACTION OPTIONS:${NC}"
    echo ""
    echo -e "  ${YELLOW}--login${NC}"
    echo "      Run CLI login prompts"
    echo "      - Requires --nodejs to be installed first"
    echo "      - Prompts for Claude, Codex authentication"
    echo ""
    echo -e "  ${YELLOW}--remove-firefox${NC}"
    echo "      Remove Firefox browser"
    echo "      - Detects snap, deb, flatpak installations"
    echo "      - Only removes if alternative browser available"
    echo ""
    echo -e "${GREEN}GNOME BACKUP/RESTORE:${NC}"
    echo ""
    echo -e "  ${YELLOW}--show-backup-gnome${NC}"
    echo "      Display saved GNOME desktop backup"
    echo "      - Shows backup from ~/.gnome_desktop_conf_backup/gnome-backup/"
    echo ""
    echo -e "  ${YELLOW}--restore-gnome-desktop${NC}"
    echo "      Restore GNOME desktop to previous state"
    echo "      - Restores from ~/.gnome_desktop_conf_backup/gnome-backup/"
    echo ""
    echo -e "${GREEN}MENU & INTERACTIVE:${NC}"
    echo ""
    echo -e "  ${YELLOW}--menu${NC}"
    echo "      Open full interactive menu"
    echo "      - Install applications"
    echo "      - Remove applications"
    echo "      - Manage backups"
    echo "      - System info"
    echo ""
    echo -e "  ${YELLOW}(no arguments)${NC}"
    echo "      Open interactive app selection"
    echo "      - Select apps with numbers"
    echo "      - Shows OS info and architecture"
    echo ""
    echo -e "${GREEN}SPECIAL:${NC}"
    echo ""
    echo -e "  ${YELLOW}--arm-fix${NC}"
    echo "      Apply ARM snapd fix manually"
    echo "      - Required for browsers on ARM devices"
    echo "      - Auto-selected when VNC is chosen on ARM"
    echo ""
    echo -e "  ${YELLOW}--help, -h${NC}"
    echo "      Show this help message"
    echo ""
    echo -e "${GREEN}EXAMPLES:${NC}"
    echo ""
    echo "  # Interactive menu"
    echo "  $0"
    echo ""
    echo "  # Full menu system"
    echo "  $0 --menu"
    echo ""
    echo "  # Install everything"
    echo "  $0 --all"
    echo ""
    echo "  # Install only Node.js and VS Code"
    echo "  $0 --nodejs --vscode"
    echo ""
    echo "  # Install development tools"
    echo "  $0 --nodejs --vscode --docker --python"
    echo ""
    echo "  # Install with CLI logins"
    echo "  $0 --nodejs --login"
    echo ""
    echo "  # Restore GNOME to previous state"
    echo "  $0 --restore-gnome-desktop"
    echo ""
    echo -e "${GREEN}NOTES:${NC}"
    echo "  - Jetson devices: Automatically applies snapd fix for browser compatibility"
    echo "  - ARM64: Some packages use alternative sources (Chromium instead of Chrome)"
    echo "  - GNOME backup is created automatically before any GNOME changes"
    echo "  - Backups stored in: ~/.gnome_desktop_conf_backup/"
    echo ""
}

#===============================================================================
# Interactive Menu System
#===============================================================================

# Detect system info for display (without logging)
detect_system_silent() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        OS_CODENAME=$VERSION_CODENAME
    else
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
        OS_CODENAME="Unknown"
    fi

    ARCH=$(uname -m)
    case $ARCH in
        x86_64) DEB_ARCH="amd64" ;;
        aarch64) DEB_ARCH="arm64" ;;
        armv7l) DEB_ARCH="armhf" ;;
        *) DEB_ARCH="unknown" ;;
    esac

    # Detect Jetson
    IS_JETSON=false
    if [ -f /etc/nv_tegra_release ] || ([ -d /sys/devices/soc0 ] && grep -qi "nvidia" /sys/devices/soc0/family 2>/dev/null); then
        IS_JETSON=true
    fi

    # Detect Armbian
    IS_ARMBIAN=false
    if [ -f /etc/armbian-release ]; then
        IS_ARMBIAN=true
    fi
}

# Show system info header
show_system_header() {
    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Ubuntu Post-Installation Setup Script  ${YELLOW}v${SCRIPT_VERSION}${CYAN} (rev-${SCRIPT_REVISION})       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${GREEN}System Information:${NC}"
    echo -e "  OS:           ${YELLOW}$OS_NAME $OS_VERSION${NC} ($OS_CODENAME)"
    echo -e "  Architecture: ${YELLOW}$ARCH${NC} ($DEB_ARCH)"
    if $IS_JETSON; then
        echo -e "  Device:       ${YELLOW}NVIDIA Jetson (ARM)${NC}"
    elif $IS_ARMBIAN; then
        echo -e "  Device:       ${YELLOW}Armbian (ARM)${NC}"
    elif [ "$DEB_ARCH" == "arm64" ] || [ "$DEB_ARCH" == "armhf" ]; then
        echo -e "  Device:       ${YELLOW}ARM Device${NC}"
    fi
    echo ""
}

# Interactive app selection menu with arrow key navigation
show_interactive_install_menu() {
    detect_system_silent

    # Build menu dynamically based on architecture and device
    local -a APP_NAMES=()
    local -a APP_DESCS=()
    local -a APP_VARS=()
    local idx=0

    # Always available apps
    APP_NAMES+=("VNC");         APP_DESCS+=("RealVNC Connect (Remote Desktop)");      APP_VARS+=("INSTALL_VNC")
    APP_NAMES+=("RustDesk");    APP_DESCS+=("RustDesk (Open Source Remote Desktop)"); APP_VARS+=("INSTALL_RUSTDESK")
    APP_NAMES+=("NodeJS");      APP_DESCS+=("NVM + Node.js 22 + Yarn + CLI Tools");  APP_VARS+=("INSTALL_NODEJS")

    # Chrome only on amd64, Chromium on ARM
    if [ "$DEB_ARCH" == "amd64" ]; then
        APP_NAMES+=("Chrome");  APP_DESCS+=("Google Chrome");                         APP_VARS+=("INSTALL_CHROME")
    else
        APP_NAMES+=("Chromium"); APP_DESCS+=("Chromium Browser (ARM)");               APP_VARS+=("INSTALL_CHROME")
    fi

    APP_NAMES+=("VSCode");      APP_DESCS+=("Visual Studio Code + Extensions");       APP_VARS+=("INSTALL_VSCODE")
    APP_NAMES+=("Python");      APP_DESCS+=("Python 3 + pip + venv");                 APP_VARS+=("INSTALL_PYTHON")
    APP_NAMES+=("GNOME");       APP_DESCS+=("Ubuntu (GNOME) Tweaks + Wayland Off");    APP_VARS+=("INSTALL_GNOME")
    APP_NAMES+=("DBeaver");     APP_DESCS+=("DBeaver CE (Database Tool)");            APP_VARS+=("INSTALL_DBEAVER")
    APP_NAMES+=("VLC");         APP_DESCS+=("VLC Media Player");                      APP_VARS+=("INSTALL_VLC")
    APP_NAMES+=("Cloudflared"); APP_DESCS+=("Cloudflare Tunnel Client");              APP_VARS+=("INSTALL_CLOUDFLARED")
    APP_NAMES+=("Docker");      APP_DESCS+=("Docker Engine + Compose");               APP_VARS+=("INSTALL_DOCKER")
    APP_NAMES+=("Claude Code"); APP_DESCS+=("Claude Code (AI Coding CLI)");           APP_VARS+=("INSTALL_CLAUDE")
    APP_NAMES+=("Git & GitHub CLI"); APP_DESCS+=("Git + GitHub CLI (gh)");               APP_VARS+=("INSTALL_GH")
    APP_NAMES+=("Postman");     APP_DESCS+=("Postman (API Testing Tool)");             APP_VARS+=("INSTALL_POSTMAN")
    APP_NAMES+=("FileZilla");   APP_DESCS+=("FileZilla (FTP/SFTP Client)");            APP_VARS+=("INSTALL_FILEZILLA")

    # ARM Fix on ARM devices - only show if snap exists AND not Armbian (Armbian uses apt for Chromium)
    if ([ "$DEB_ARCH" == "arm64" ] || [ "$DEB_ARCH" == "armhf" ]) && command_exists snap && ! $IS_ARMBIAN; then
        APP_NAMES+=("ARM Fix"); APP_DESCS+=("ARM Snapd Fix (Browser Fix)");           APP_VARS+=("APPLY_JETSON_FIX")
    fi

    local TOTAL_ITEMS=${#APP_NAMES[@]}
    local -a SELECTED=()
    for ((idx=0; idx<TOTAL_ITEMS; idx++)); do
        SELECTED+=(0)
    done
    local cursor=0
    local key=""
    local count=0

    # Hide cursor
    tput civis 2>/dev/null || true

    while true; do
        clear
        show_system_header

        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}     Use ↑↓ arrows to navigate, SPACE to select${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""

        # Draw menu items
        local i
        for ((i=0; i<TOTAL_ITEMS; i++)); do
            local name="${APP_NAMES[$i]}"
            local desc="${APP_DESCS[$i]}"
            local num_display=$(printf "%2d" $((i + 1)))
            local checkbox="[ ]"
            local line_start="   "

            if [ "${SELECTED[$i]}" = "1" ]; then
                checkbox="${GREEN}[✓]${NC}"
            fi

            if [ "$cursor" = "$i" ]; then
                line_start=" ${CYAN}▶${NC}"
            fi

            if [ "${SELECTED[$i]}" = "1" ]; then
                echo -e "${line_start} ${BLUE}[$num_display]${NC} $checkbox ${GREEN}$name${NC} - $desc"
            else
                echo -e "${line_start} ${BLUE}[$num_display]${NC} $checkbox $name - $desc"
            fi
        done

        echo ""
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"

        # Count selected
        count=0
        local selected_names=""
        for ((i=0; i<TOTAL_ITEMS; i++)); do
            if [ "${SELECTED[$i]}" = "1" ]; then
                count=$((count + 1))
                selected_names="${selected_names}${APP_NAMES[$i]}, "
            fi
        done

        if [ $count -gt 0 ]; then
            selected_names="${selected_names%, }"
            echo -e "  ${GREEN}Selected ($count):${NC} $selected_names"
        else
            echo -e "  ${YELLOW}Selected: None${NC}"
        fi

        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${CYAN}CONTROLS:${NC}  ${YELLOW}↑↓${NC}=Move  ${YELLOW}SPACE${NC}=Toggle  ${YELLOW}a${NC}=All  ${YELLOW}n${NC}=None  ${GREEN}c${NC}=Confirm  ${RED}q${NC}=Quit"
        echo ""

        # Read key
        IFS= read -rsn1 key < /dev/tty 2>/dev/null || key=""

        # Check for escape sequence (arrow keys)
        if [ "$key" = $'\x1b' ]; then
            read -rsn2 -t 0.1 rest < /dev/tty 2>/dev/null || rest=""
            key="${key}${rest}"
        fi

        # Handle keys
        case "$key" in
            $'\x1b[A'|'k') # Up arrow or k
                if [ $cursor -gt 0 ]; then
                    cursor=$((cursor - 1))
                fi
                ;;
            $'\x1b[B'|'j') # Down arrow or j
                if [ $cursor -lt $((TOTAL_ITEMS - 1)) ]; then
                    cursor=$((cursor + 1))
                fi
                ;;
            ' ') # Space - toggle
                if [ "${SELECTED[$cursor]}" = "1" ]; then
                    SELECTED[$cursor]=0
                else
                    SELECTED[$cursor]=1
                    # Auto-select ARM Fix when VNC is selected on ARM devices (only if snap exists)
                    if [ "${APP_VARS[$cursor]}" = "INSTALL_VNC" ] && command_exists snap; then
                        for ((ai=0; ai<TOTAL_ITEMS; ai++)); do
                            if [ "${APP_VARS[$ai]}" = "APPLY_JETSON_FIX" ]; then
                                SELECTED[$ai]=1
                                break
                            fi
                        done
                    fi
                fi
                ;;
            'a'|'A') # Select all
                for ((i=0; i<TOTAL_ITEMS; i++)); do
                    SELECTED[$i]=1
                done
                ;;
            'n'|'N') # Clear all
                for ((i=0; i<TOTAL_ITEMS; i++)); do
                    SELECTED[$i]=0
                done
                ;;
            'c'|'C'|'') # Confirm or Enter
                if [ $count -eq 0 ]; then
                    echo -e "${RED}Please select at least one application!${NC}"
                    sleep 1
                    continue
                fi
                # Set flags
                for ((i=0; i<TOTAL_ITEMS; i++)); do
                    if [ "${SELECTED[$i]}" = "1" ]; then
                        eval "${APP_VARS[$i]}=true"
                    fi
                done
                tput cnorm 2>/dev/null || true
                return 0
                ;;
            'q'|'Q') # Quit
                tput cnorm 2>/dev/null || true
                echo "Exiting..."
                exit 0
                ;;
            [1-9]) # Number keys
                local num=$((key - 1))
                if [ $num -lt $TOTAL_ITEMS ]; then
                    if [ "${SELECTED[$num]}" = "1" ]; then
                        SELECTED[$num]=0
                    else
                        SELECTED[$num]=1
                    fi
                    cursor=$num
                fi
                ;;
        esac
    done
}

# Full menu system
show_full_menu() {
    detect_system_silent

    while true; do
        clear
        show_system_header

        echo -e "${GREEN}Main Menu:${NC}"
        echo ""
        echo -e "  ${BLUE}[1]${NC}  Install Applications"
        echo -e "  ${BLUE}[2]${NC}  Remove Applications"
        echo -e "  ${BLUE}[3]${NC}  Backups"
        echo -e "  ${BLUE}[4]${NC}  System Info"
        echo ""
        echo -e "  ${RED}[q]${NC}  Quit"
        echo ""

        read -p "Enter choice: " choice < /dev/tty

        case $choice in
            1) menu_install_apps ;;
            2) menu_remove_apps ;;
            3) menu_backups ;;
            4) menu_system_info ;;
            q|Q) echo "Goodbye!"; exit 0 ;;
            *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
        esac
    done
}

# Install apps submenu
menu_install_apps() {
    show_interactive_install_menu

    echo ""
    echo -e "${GREEN}Starting installation...${NC}"
    sleep 1

    # Run the actual installations
    run_installations
}

# Remove apps submenu
menu_remove_apps() {
    detect_system_silent

    while true; do
        clear
        show_system_header

        echo -e "${GREEN}Remove Applications:${NC}"
        echo ""

        local idx=1
        declare -A REMOVABLE

        # Check installed apps
        if command_exists vncserver-x11 || package_installed realvnc-connect; then
            echo -e "  ${BLUE}[$idx]${NC}  RealVNC Connect"
            REMOVABLE[$idx]="realvnc"
            ((idx++))
        fi

        if [ -d "$HOME/.nvm" ]; then
            echo -e "  ${BLUE}[$idx]${NC}  NVM + Node.js"
            REMOVABLE[$idx]="nvm"
            ((idx++))
        fi

        if command_exists google-chrome || command_exists google-chrome-stable; then
            echo -e "  ${BLUE}[$idx]${NC}  Google Chrome"
            REMOVABLE[$idx]="chrome"
            ((idx++))
        fi

        if command_exists chromium-browser || command_exists chromium; then
            echo -e "  ${BLUE}[$idx]${NC}  Chromium"
            REMOVABLE[$idx]="chromium"
            ((idx++))
        fi

        if command_exists code; then
            echo -e "  ${BLUE}[$idx]${NC}  VS Code"
            REMOVABLE[$idx]="vscode"
            ((idx++))
        fi

        if package_installed dbeaver-ce || command_exists dbeaver; then
            echo -e "  ${BLUE}[$idx]${NC}  DBeaver CE"
            REMOVABLE[$idx]="dbeaver"
            ((idx++))
        fi

        if command_exists vlc; then
            echo -e "  ${BLUE}[$idx]${NC}  VLC"
            REMOVABLE[$idx]="vlc"
            ((idx++))
        fi

        if command_exists cloudflared; then
            echo -e "  ${BLUE}[$idx]${NC}  Cloudflared"
            REMOVABLE[$idx]="cloudflared"
            ((idx++))
        fi

        if command_exists docker; then
            echo -e "  ${BLUE}[$idx]${NC}  Docker"
            REMOVABLE[$idx]="docker"
            ((idx++))
        fi

        if command_exists claude; then
            echo -e "  ${BLUE}[$idx]${NC}  Claude Code"
            REMOVABLE[$idx]="claude"
            ((idx++))
        fi

        if command_exists firefox; then
            echo -e "  ${BLUE}[$idx]${NC}  Firefox"
            REMOVABLE[$idx]="firefox"
            ((idx++))
        fi

        if [ $idx -eq 1 ]; then
            echo -e "  ${YELLOW}No removable applications found.${NC}"
        fi

        echo ""
        echo -e "  ${RED}[b]${NC}  Back to main menu"
        echo ""

        read -p "Enter number to remove (or 'b' to go back): " choice < /dev/tty

        if [[ "$choice" == "b" || "$choice" == "B" ]]; then
            return
        fi

        if [[ "$choice" =~ ^[0-9]+$ ]] && [ -n "${REMOVABLE[$choice]}" ]; then
            local app="${REMOVABLE[$choice]}"
            echo ""
            read -p "Are you sure you want to remove $app? (y/n): " confirm < /dev/tty
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                remove_application "$app"
                echo ""
                read -p "Press Enter to continue..." < /dev/tty
            fi
        fi
    done
}

# Remove specific application
remove_application() {
    local app=$1
    echo -e "${BLUE}[INFO]${NC} Removing $app..."

    case $app in
        realvnc)
            sudo apt-get remove -y realvnc-connect realvnc-vnc-server 2>/dev/null
            # Clean up RealVNC repo and GPG key left behind after uninstall
            sudo rm -f /etc/apt/sources.list.d/*realvnc* /etc/apt/sources.list.d/*vnc*
            sudo rm -f /usr/share/keyrings/*realvnc* /etc/apt/trusted.gpg.d/*realvnc*
            ;;
        nvm)
            rm -rf "$HOME/.nvm"
            echo -e "${YELLOW}Note: Remove NVM lines from ~/.bashrc manually${NC}"
            ;;
        chrome)
            sudo apt-get remove -y google-chrome-stable 2>/dev/null
            ;;
        chromium)
            sudo apt-get remove -y chromium-browser chromium 2>/dev/null
            ;;
        vscode)
            sudo apt-get remove -y code 2>/dev/null
            ;;
        dbeaver)
            sudo apt-get remove -y dbeaver-ce 2>/dev/null
            ;;
        vlc)
            sudo apt-get remove -y vlc 2>/dev/null
            ;;
        cloudflared)
            sudo apt-get remove -y cloudflared 2>/dev/null
            ;;
        docker)
            sudo apt-get remove -y docker-ce docker-ce-cli containerd.io 2>/dev/null
            ;;
        claude)
            # Remove native installation
            rm -f "$HOME/.claude/bin/claude" 2>/dev/null
            rm -rf "$HOME/.claude" 2>/dev/null
            # Remove npm installation if exists
            npm uninstall -g @anthropic-ai/claude-code 2>/dev/null
            ;;
        firefox)
            sudo snap remove firefox 2>/dev/null
            sudo apt-get remove -y firefox 2>/dev/null
            ;;
    esac

    echo -e "${GREEN}[SUCCESS]${NC} $app removed"
}

# Backups submenu
menu_backups() {
    while true; do
        clear
        show_system_header

        echo -e "${GREEN}Backup Management:${NC}"
        echo ""
        echo -e "  ${BLUE}[1]${NC}  Show existing backups"
        echo -e "  ${BLUE}[2]${NC}  Take new backup"
        echo -e "  ${BLUE}[3]${NC}  Restore from backup"
        echo ""
        echo -e "  ${RED}[b]${NC}  Back to main menu"
        echo ""

        read -p "Enter choice: " choice < /dev/tty

        case $choice in
            1) show_all_backups ;;
            2) take_new_backup ;;
            3) restore_backup_interactive ;;
            b|B) return ;;
            *) echo -e "${RED}Invalid choice${NC}"; sleep 1 ;;
        esac
    done
}

# Show all backups
show_all_backups() {
    clear
    show_system_header

    echo -e "${GREEN}Existing Backups:${NC}"
    echo -e "${YELLOW}Location: $BACKUP_DIR${NC}"
    echo ""

    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}No backups found.${NC}"
        echo ""
        read -p "Press Enter to continue..." < /dev/tty
        return
    fi

    # List all backup directories
    local found=false
    for backup in "$BACKUP_DIR"/*; do
        if [ -d "$backup" ]; then
            found=true
            local name=$(basename "$backup")
            local timestamp=""
            if [ -f "$backup/backup-timestamp" ]; then
                timestamp=$(cat "$backup/backup-timestamp")
            fi
            echo -e "  ${CYAN}$name${NC}"
            [ -n "$timestamp" ] && echo -e "    Created: $timestamp"
            echo -e "    Files:"
            ls -la "$backup" 2>/dev/null | tail -n +2 | head -5 | while read line; do
                echo "      $line"
            done
            echo ""
        fi
    done

    if ! $found; then
        echo -e "${YELLOW}No backups found.${NC}"
    fi

    echo ""
    read -p "Press Enter to continue..." < /dev/tty
}

# Take new backup
take_new_backup() {
    clear
    show_system_header

    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_name="${timestamp}-backup"
    local backup_path="$BACKUP_DIR/$backup_name"

    echo -e "${GREEN}Taking New Backup:${NC}"
    echo -e "Backup name: ${YELLOW}$backup_name${NC}"
    echo ""

    read -p "Continue? (y/n): " confirm < /dev/tty
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        return
    fi

    mkdir -p "$backup_path"

    echo ""
    echo -e "${BLUE}[INFO]${NC} Backing up GNOME settings..."

    # Backup GNOME settings
    if command_exists dconf; then
        if dconf list /org/gnome/shell/extensions/dash-to-dock/ &>/dev/null; then
            dconf dump /org/gnome/shell/extensions/dash-to-dock/ > "$backup_path/dash-to-dock.dconf"
            echo -e "${GREEN}[OK]${NC} Dash to Dock"
        fi

        if dconf list /org/gnome/shell/ &>/dev/null; then
            dconf dump /org/gnome/shell/ > "$backup_path/gnome-shell.dconf"
            echo -e "${GREEN}[OK]${NC} GNOME Shell"
        fi

        if dconf list /org/gnome/desktop/ &>/dev/null; then
            dconf dump /org/gnome/desktop/ > "$backup_path/gnome-desktop.dconf"
            echo -e "${GREEN}[OK]${NC} GNOME Desktop"
        fi
    fi

    # Backup VS Code settings
    local vscode_settings="$HOME/.config/Code/User/settings.json"
    if [ -f "$vscode_settings" ]; then
        cp "$vscode_settings" "$backup_path/vscode-settings.json"
        echo -e "${GREEN}[OK]${NC} VS Code settings"
    fi

    # Save timestamp
    echo "$timestamp" > "$backup_path/backup-timestamp"

    echo ""
    echo -e "${GREEN}Backup completed: $backup_path${NC}"
    echo ""
    read -p "Press Enter to continue..." < /dev/tty
}

# Restore backup interactive
restore_backup_interactive() {
    clear
    show_system_header

    echo -e "${GREEN}Restore from Backup:${NC}"
    echo ""

    if [ ! -d "$BACKUP_DIR" ]; then
        echo -e "${YELLOW}No backups found.${NC}"
        echo ""
        read -p "Press Enter to continue..." < /dev/tty
        return
    fi

    # List available backups
    declare -A BACKUPS
    local idx=1

    for backup in "$BACKUP_DIR"/*; do
        if [ -d "$backup" ]; then
            local name=$(basename "$backup")
            local timestamp=""
            [ -f "$backup/backup-timestamp" ] && timestamp=$(cat "$backup/backup-timestamp")

            echo -e "  ${BLUE}[$idx]${NC}  $name"
            [ -n "$timestamp" ] && echo -e "        Created: $timestamp"
            BACKUPS[$idx]="$backup"
            ((idx++))
        fi
    done

    if [ $idx -eq 1 ]; then
        echo -e "${YELLOW}No backups found.${NC}"
        echo ""
        read -p "Press Enter to continue..." < /dev/tty
        return
    fi

    echo ""
    echo -e "  ${RED}[b]${NC}  Back"
    echo ""

    read -p "Select backup to restore: " choice < /dev/tty

    if [[ "$choice" == "b" || "$choice" == "B" ]]; then
        return
    fi

    if [[ "$choice" =~ ^[0-9]+$ ]] && [ -n "${BACKUPS[$choice]}" ]; then
        local backup_path="${BACKUPS[$choice]}"

        clear
        show_system_header

        echo -e "${GREEN}Backup Contents:${NC}"
        echo -e "Path: ${YELLOW}$backup_path${NC}"
        echo ""

        # Show backup contents
        ls -la "$backup_path" 2>/dev/null
        echo ""

        # Show dconf content preview
        if [ -f "$backup_path/dash-to-dock.dconf" ]; then
            echo -e "${CYAN}Dash to Dock settings preview:${NC}"
            head -20 "$backup_path/dash-to-dock.dconf"
            echo "..."
            echo ""
        fi

        read -p "Restore this backup? (yes/y to confirm): " confirm < /dev/tty

        if [[ "$confirm" =~ ^[Yy]([Ee][Ss])?$ ]]; then
            echo ""
            echo -e "${BLUE}[INFO]${NC} Restoring backup..."

            # Restore GNOME settings
            if [ -f "$backup_path/dash-to-dock.dconf" ] && command_exists dconf; then
                dconf load /org/gnome/shell/extensions/dash-to-dock/ < "$backup_path/dash-to-dock.dconf"
                echo -e "${GREEN}[OK]${NC} Dash to Dock restored"
            fi

            if [ -f "$backup_path/gnome-shell.dconf" ] && command_exists dconf; then
                dconf load /org/gnome/shell/ < "$backup_path/gnome-shell.dconf"
                echo -e "${GREEN}[OK]${NC} GNOME Shell restored"
            fi

            if [ -f "$backup_path/gnome-desktop.dconf" ] && command_exists dconf; then
                dconf load /org/gnome/desktop/ < "$backup_path/gnome-desktop.dconf"
                echo -e "${GREEN}[OK]${NC} GNOME Desktop restored"
            fi

            # Restore VS Code settings
            if [ -f "$backup_path/vscode-settings.json" ]; then
                local vscode_dir="$HOME/.config/Code/User"
                mkdir -p "$vscode_dir"
                cp "$backup_path/vscode-settings.json" "$vscode_dir/settings.json"
                echo -e "${GREEN}[OK]${NC} VS Code settings restored"
            fi

            echo ""
            echo -e "${GREEN}Backup restored successfully!${NC}"
            echo -e "${YELLOW}Note: You may need to restart GNOME Shell (Alt+F2, 'r') for changes to take effect.${NC}"
        fi

        echo ""
        read -p "Press Enter to continue..." < /dev/tty
    fi
}

# System info menu
menu_system_info() {
    clear
    detect_system_silent
    show_system_header

    echo -e "${GREEN}Detailed System Information:${NC}"
    echo ""
    echo -e "  Kernel:     $(uname -r)"
    echo -e "  Hostname:   $(hostname)"
    echo -e "  User:       $USER"
    echo -e "  Home:       $HOME"
    echo ""

    echo -e "${GREEN}Installed Applications:${NC}"
    echo ""

    command_exists vncserver-x11 && echo -e "  ${GREEN}✓${NC} RealVNC"
    [ -d "$HOME/.nvm" ] && echo -e "  ${GREEN}✓${NC} NVM"
    command_exists node && echo -e "  ${GREEN}✓${NC} Node.js $(node -v 2>/dev/null)"
    command_exists yarn && echo -e "  ${GREEN}✓${NC} Yarn"
    (command_exists google-chrome || command_exists google-chrome-stable) && echo -e "  ${GREEN}✓${NC} Google Chrome"
    (command_exists chromium-browser || command_exists chromium) && echo -e "  ${GREEN}✓${NC} Chromium"
    command_exists code && echo -e "  ${GREEN}✓${NC} VS Code"
    command_exists python3 && echo -e "  ${GREEN}✓${NC} Python $(python3 --version 2>&1 | cut -d' ' -f2)"
    command_exists dbeaver && echo -e "  ${GREEN}✓${NC} DBeaver"
    command_exists vlc && echo -e "  ${GREEN}✓${NC} VLC"
    command_exists cloudflared && echo -e "  ${GREEN}✓${NC} Cloudflared"
    command_exists docker && echo -e "  ${GREEN}✓${NC} Docker"
    command_exists claude && echo -e "  ${GREEN}✓${NC} Claude Code"
    command_exists gh && echo -e "  ${GREEN}✓${NC} GitHub CLI"
    (command_exists postman || snap list postman 2>/dev/null | grep -q postman) && echo -e "  ${GREEN}✓${NC} Postman"
    command_exists filezilla && echo -e "  ${GREEN}✓${NC} FileZilla"
    command_exists firefox && echo -e "  ${GREEN}✓${NC} Firefox"

    echo ""
    read -p "Press Enter to continue..." < /dev/tty
}

# Run installations based on flags
# Check already installed software and ask user for reinstall decisions
check_already_installed() {
    # Ensure claude PATH is available for detection
    export PATH="$HOME/.claude/bin:$HOME/.local/bin:$PATH"

    # Define: FLAG_VAR | Display Name | Detection Command
    local -a CHECKS=(
        "INSTALL_VNC|RealVNC|command_exists vncserver-x11 || command_exists vncserver || package_installed realvnc-connect"
        "INSTALL_RUSTDESK|RustDesk|command_exists rustdesk"
        "INSTALL_NODEJS|Node.js + NVM|[ -d \"\$HOME/.nvm\" ] && command_exists node"
        "INSTALL_CHROME|Chrome/Chromium|command_exists google-chrome || command_exists google-chrome-stable || command_exists chromium-browser || command_exists chromium"
        "INSTALL_VSCODE|VS Code|command_exists code"
        "INSTALL_PYTHON|Python 3|command_exists python3"
        "INSTALL_GNOME|GNOME Extensions|package_installed gnome-shell-extensions"
        "INSTALL_DBEAVER|DBeaver|package_installed dbeaver-ce || command_exists dbeaver"
        "INSTALL_VLC|VLC|command_exists vlc"
        "INSTALL_CLOUDFLARED|Cloudflared|command_exists cloudflared"
        "INSTALL_DOCKER|Docker|command_exists docker"
        "INSTALL_CLAUDE|Claude Code|command_exists claude"
        "INSTALL_GH|GitHub CLI|command_exists gh"
        "INSTALL_POSTMAN|Postman|command_exists postman || snap list postman 2>/dev/null | grep -q postman"
        "INSTALL_FILEZILLA|FileZilla|command_exists filezilla"
    )

    local found_any=false

    # First pass: detect which selected apps are already installed
    local -a ALREADY_INSTALLED=()
    for check in "${CHECKS[@]}"; do
        IFS='|' read -r flag_var display_name detect_cmd <<< "$check"
        # Check if this app was selected for install
        if eval "\$$flag_var"; then
            # Check if already installed
            if eval "$detect_cmd" 2>/dev/null; then
                ALREADY_INSTALLED+=("$check")
                found_any=true
            fi
        fi
    done

    # If nothing is already installed, skip
    if ! $found_any; then
        return
    fi

    echo ""
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo -e "${YELLOW}  Some selected software is already installed${NC}"
    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""

    # Ask for each already-installed app
    local idx=1
    local total=${#ALREADY_INSTALLED[@]}
    for check in "${ALREADY_INSTALLED[@]}"; do
        IFS='|' read -r flag_var display_name detect_cmd <<< "$check"
        echo -e "  ${CYAN}[$idx/$total]${NC} ${GREEN}$display_name${NC} is already installed."
        read -p "  Reinstall from scratch? (y/n): " choice < /dev/tty
        if [[ ! "$choice" =~ ^[Yy]$ ]]; then
            # User doesn't want to reinstall, disable this flag
            eval "$flag_var=false"
            echo -e "  ${YELLOW}→ Skipping $display_name${NC}"
        else
            # Mark for force reinstall
            eval "FORCE_REINSTALL_${flag_var}=true"
            echo -e "  ${GREEN}→ Will reinstall $display_name${NC}"
        fi
        echo ""
        idx=$((idx + 1))
    done

    echo -e "${YELLOW}═══════════════════════════════════════════════════════════════${NC}"
    echo ""
}

run_installations() {
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this script as root. Run as normal user."
        exit 1
    fi

    # Detect system
    detect_system

    # Check already installed apps and ask for reinstall one by one
    check_already_installed

    # Apply ARM snapd fix if selected
    if $APPLY_JETSON_FIX; then
        fix_jetson_snapd
    fi

    # Install prerequisites
    install_prerequisites

    # Run installations based on flags (each wrapped with error handling)
    if $INSTALL_VNC; then install_realvnc || handle_error "RealVNC installation failed"; fi
    if $INSTALL_NODEJS; then install_nvm_nodejs || handle_error "Node.js installation failed"; fi
    if $INSTALL_CHROME; then install_chrome || handle_error "Chrome/Chromium installation failed"; fi
    if $INSTALL_VSCODE; then install_vscode || handle_error "VS Code installation failed"; fi
    if $INSTALL_PYTHON; then install_python || handle_error "Python installation failed"; fi
    if $INSTALL_GNOME; then install_gnome_extensions || handle_error "GNOME extensions installation failed"; fi
    if $INSTALL_DBEAVER; then install_dbeaver || handle_error "DBeaver installation failed"; fi
    if $INSTALL_VLC; then install_vlc || handle_error "VLC installation failed"; fi
    if $INSTALL_CLOUDFLARED; then install_cloudflared || handle_error "Cloudflared installation failed"; fi
    if $INSTALL_DOCKER; then install_docker || handle_error "Docker installation failed"; fi
    if $INSTALL_CLAUDE; then install_claude_code || handle_error "Claude Code installation failed"; fi
    if $INSTALL_GH; then install_gh || handle_error "GitHub CLI installation failed"; fi
    if $INSTALL_POSTMAN; then install_postman || handle_error "Postman installation failed"; fi
    if $INSTALL_FILEZILLA; then install_filezilla || handle_error "FileZilla installation failed"; fi
    if $INSTALL_RUSTDESK; then install_rustdesk || handle_error "RustDesk installation failed"; fi

    # CLI logins (requires nodejs to be installed)
    if $DO_CLI_LOGIN; then
        if $INSTALL_NODEJS || command_exists node; then
            run_cli_logins || handle_error "CLI logins failed"
        else
            log_warning "CLI logins skipped: Node.js not installed. Use --nodejs first."
        fi
    fi

    # Firefox removal
    if $DO_REMOVE_FIREFOX; then remove_firefox || handle_error "Firefox removal failed"; fi

    # Setup bash aliases and Nautilus right-click actions for AI CLI tools
    setup_cli_shortcuts

    # Print summary
    print_summary
}

#===============================================================================
# System Detection
#===============================================================================
detect_system() {
    log_step "Detecting System Information"

    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        OS_CODENAME=$VERSION_CODENAME
    else
        handle_error "Cannot detect OS. This script is designed for Ubuntu."
        OS_NAME="Unknown"
        OS_VERSION="Unknown"
        OS_CODENAME="Unknown"
    fi

    # Detect Architecture
    ARCH=$(uname -m)
    case $ARCH in
        x86_64)
            DEB_ARCH="amd64"
            ;;
        aarch64)
            DEB_ARCH="arm64"
            ;;
        armv7l)
            DEB_ARCH="armhf"
            ;;
        *)
            handle_error "Unsupported architecture: $ARCH. Some packages may not install correctly."
            DEB_ARCH="unknown"
            ;;
    esac

    log_info "OS: $OS_NAME $OS_VERSION ($OS_CODENAME)"
    log_info "Architecture: $ARCH ($DEB_ARCH)"

    # Detect NVIDIA Jetson
    IS_JETSON=false
    if [ -f /etc/nv_tegra_release ] || [ -d /sys/devices/soc0 ] && grep -qi "nvidia" /sys/devices/soc0/family 2>/dev/null; then
        IS_JETSON=true
        log_info "NVIDIA Jetson device detected"
    fi

    # Detect Armbian
    IS_ARMBIAN=false
    if [ -f /etc/armbian-release ]; then
        IS_ARMBIAN=true
        log_info "Armbian detected"
    fi

    # Check if Ubuntu
    if [[ "$ID" != "ubuntu" && "$ID_LIKE" != *"ubuntu"* ]]; then
        log_warning "This script is optimized for Ubuntu. Some features may not work correctly."
    fi
}

#===============================================================================
# ARM Snapd Fix (browsers don't work without this on ARM devices)
# Reference: https://forums.developer.nvidia.com/t/neither-chromium-nor-firefox-work-with-my-jetson-orin-nano/338669
#===============================================================================
fix_jetson_snapd() {
    log_step "Applying ARM Snapd Fix"
    log_info "ARM devices require a specific snapd version for browsers to work"

    local temp_dir="/tmp/jetson-snapd-fix"
    mkdir -p "$temp_dir"
    cd "$temp_dir"

    # Download specific snapd revision
    log_info "Downloading snapd revision 24724..."
    if ! snap download snapd --revision=24724; then
        log_warning "Failed to download snapd, skipping ARM fix"
        cd - > /dev/null
        rm -rf "$temp_dir"
        return
    fi

    # Install the specific snapd version
    log_info "Installing snapd revision 24724..."
    sudo snap ack snapd_24724.assert
    sudo snap install snapd_24724.snap

    # Hold snapd to prevent auto-updates breaking it
    log_info "Holding snapd version to prevent auto-updates..."
    sudo snap refresh --hold snapd

    cd - > /dev/null
    rm -rf "$temp_dir"

    log_success "ARM snapd fix applied successfully"
}

#===============================================================================
# Helper Functions
#===============================================================================
command_exists() {
    command -v "$1" &> /dev/null
}

package_installed() {
    dpkg -l "$1" &> /dev/null 2>&1
}

download_file() {
    local url="$1"
    local output="$2"

    if command_exists wget; then
        wget -q --show-progress -O "$output" "$url"
    elif command_exists curl; then
        curl -L -o "$output" "$url"
    else
        log_error "Neither wget nor curl is available"
        exit 1
    fi
}

install_deb() {
    local deb_file="$1"
    sudo dpkg -i "$deb_file" || sudo apt-get install -f -y
}

# Retry function - runs command with 3 attempts and 5s delay
# Usage: retry_command "description" command args...
# Returns: 0 on success, 1 on failure after all attempts
retry_command() {
    local description="$1"
    shift
    local max_attempts=3
    local attempt=1
    local delay=5

    while [ $attempt -le $max_attempts ]; do
        log_info "Attempt $attempt of $max_attempts: $description"

        if "$@"; then
            return 0
        fi

        log_warning "Attempt $attempt failed"
        ((attempt++))

        if [ $attempt -le $max_attempts ]; then
            log_info "Retrying in ${delay}s..."
            sleep $delay
        fi
    done

    log_warning "All $max_attempts attempts failed for: $description"
    return 1
}

# Retry apt install with 3 attempts
retry_apt_install() {
    local package="$1"
    retry_command "Installing $package" sudo apt-get install -y "$package"
}

# Retry snap install with 3 attempts
retry_snap_install() {
    local package="$1"
    local flags="${2:-}"
    if [ -n "$flags" ]; then
        retry_command "Installing $package (snap)" sudo snap install "$package" $flags
    else
        retry_command "Installing $package (snap)" sudo snap install "$package"
    fi
}

# Retry npm install with 3 attempts
retry_npm_install() {
    local package="$1"
    retry_command "Installing $package (npm)" npm install -g "$package"
}

# Retry curl download with 3 attempts
retry_curl_download() {
    local url="$1"
    local output="$2"
    local description="${3:-Downloading file}"

    local max_attempts=3
    local attempt=1
    local delay=5

    while [ $attempt -le $max_attempts ]; do
        log_info "Attempt $attempt of $max_attempts: $description"

        if curl -L --progress-bar --connect-timeout 30 --max-time 300 -o "$output" "$url"; then
            if [ -s "$output" ]; then
                log_success "Download completed"
                return 0
            fi
        fi

        log_warning "Download attempt $attempt failed"
        rm -f "$output"
        ((attempt++))

        if [ $attempt -le $max_attempts ]; then
            log_info "Retrying in ${delay}s..."
            sleep $delay
        fi
    done

    log_warning "All download attempts failed"
    return 1
}

#===============================================================================
# 1.5 RustDesk Installation (Open Source Remote Desktop)
#===============================================================================
install_rustdesk() {
    log_step "1.5 Installing RustDesk"

    if command_exists rustdesk; then
        log_warning "RustDesk already installed, skipping..."
        return
    fi

    log_info "Installing RustDesk..."

    local temp_file="/tmp/rustdesk.deb"
    local download_url=""

    # Determine download URL based on architecture
    if [ "$DEB_ARCH" == "amd64" ]; then
        download_url="https://github.com/rustdesk/rustdesk/releases/download/1.3.6/rustdesk-1.3.6-x86_64.deb"
    else
        download_url="https://github.com/rustdesk/rustdesk/releases/download/1.3.6/rustdesk-1.3.6-aarch64.deb"
    fi

    if ! retry_curl_download "$download_url" "$temp_file" "Downloading RustDesk"; then
        log_warning "RustDesk download failed after 3 attempts"
        return
    fi

    log_info "Installing RustDesk deb package..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$temp_file"
    rm -f "$temp_file"

    log_success "RustDesk installed successfully"

    # Interactive password setup
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}RustDesk Password Setup${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    read -p "Do you want to set a permanent password for RustDesk? (y/n): " set_password < /dev/tty

    if [[ "$set_password" =~ ^[Yy]$ ]]; then
        while true; do
            echo ""
            # Read password with hidden input
            read -sp "Enter password: " rustdesk_password < /dev/tty
            echo ""

            if [ -z "$rustdesk_password" ]; then
                log_warning "Password cannot be empty. Please try again."
                continue
            fi

            # Show password and confirm
            echo ""
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo -e "Your password: ${GREEN}$rustdesk_password${NC}"
            echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
            echo ""
            echo -e "  ${BLUE}[1]${NC}  Continue with this password"
            echo -e "  ${BLUE}[2]${NC}  Re-enter password"
            echo -e "  ${BLUE}[3]${NC}  Skip password setup"
            echo ""
            read -p "Enter choice (1/2/3): " password_choice < /dev/tty

            case $password_choice in
                1)
                    log_info "Setting RustDesk password..."
                    rustdesk --password "$rustdesk_password" 2>/dev/null || true
                    log_success "RustDesk password set successfully"
                    break
                    ;;
                2)
                    log_info "Re-entering password..."
                    continue
                    ;;
                3|*)
                    log_info "Skipping password setup"
                    break
                    ;;
            esac
        done
    else
        log_info "Skipping password setup"
        log_info "You can set a password later with: rustdesk --password YOUR_PASSWORD"
    fi
}

#===============================================================================
# 2. NVM, Node.js 22, Yarn Installation
#===============================================================================
install_nvm_nodejs() {
    log_step "2. Installing NVM, Node.js 22, and Yarn"

    # 2.0 Install NVM
    log_info "2.0 Installing NVM..."
    if [ -d "$HOME/.nvm" ]; then
        log_warning "NVM already installed, skipping..."
    else
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
        log_success "NVM installed successfully"
    fi

    # Load NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # 2.1 Install Node.js 22
    log_info "2.1 Installing Node.js 22..."
    if command_exists node && [[ "$(node -v)" == v22* ]]; then
        log_warning "Node.js 22 already installed ($(node -v)), skipping..."
    else
        nvm install 22
        nvm use 22
        nvm alias default 22
        log_success "Node.js 22 installed successfully ($(node -v))"
    fi

    # 2.2 Install Yarn globally
    log_info "2.2 Installing Yarn globally..."
    if command_exists yarn; then
        log_warning "Yarn already installed ($(yarn -v)), skipping..."
    else
        if retry_npm_install yarn; then
            log_success "Yarn installed successfully"
        else
            log_warning "Yarn installation skipped after 3 failed attempts"
        fi
    fi

    # 2.3 Install Codex CLI
    log_info "2.3 Installing Codex CLI (OpenAI)..."
    if command_exists codex; then
        log_warning "Codex CLI already installed, skipping..."
    else
        if retry_npm_install @openai/codex; then
            log_success "Codex CLI installed successfully"
        else
            log_warning "Codex CLI installation skipped after 3 failed attempts"
        fi
    fi

}

#===============================================================================
# Claude Code Installation (native installer)
#===============================================================================

#===============================================================================
# GitHub CLI (gh) Installation
#===============================================================================
install_gh() {
    log_step "Installing GitHub CLI (gh)"

    if command_exists gh; then
        log_warning "GitHub CLI already installed ($(gh --version 2>/dev/null | head -1)), skipping..."
        return 0
    fi

    log_info "Adding GitHub CLI official repository..."

    # Add GitHub CLI GPG key and repo
    sudo mkdir -p -m 755 /etc/apt/keyrings
    if ! retry_command "Adding GitHub CLI GPG key" bash -c 'curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null'; then
        handle_error "GitHub CLI GPG key could not be added"
        return 1
    fi
    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

    safe_apt_update
    if retry_apt_install gh; then
        log_success "GitHub CLI installed successfully ($(gh --version 2>/dev/null | head -1))"
    else
        log_warning "GitHub CLI installation failed"
        return 1
    fi
}

#===============================================================================
# Postman Installation (via snap)
#===============================================================================
install_postman() {
    log_step "Installing Postman"

    if command_exists postman || snap list postman 2>/dev/null | grep -q postman; then
        log_warning "Postman already installed, skipping..."
        return 0
    fi

    log_info "Installing Postman via snap..."
    if retry_snap_install postman; then
        log_success "Postman installed successfully"
    else
        log_warning "Postman installation failed"
        return 1
    fi
}

#===============================================================================
# FileZilla Installation (via apt)
#===============================================================================
install_filezilla() {
    log_step "Installing FileZilla"

    if command_exists filezilla; then
        log_warning "FileZilla already installed, skipping..."
        return 0
    fi

    log_info "Installing FileZilla via apt..."
    if retry_apt_install filezilla; then
        log_success "FileZilla installed successfully"
    else
        log_warning "FileZilla installation failed"
        return 1
    fi
}

install_claude_code() {
    log_step "Installing Claude Code"

    # Clean up old claude installations and PATH entries before fresh install
    # Remove old npm-based claude if exists
    if command_exists npm; then
        npm uninstall -g @anthropic-ai/claude-code 2>/dev/null
    fi
    # Remove old native install binaries
    rm -f "$HOME/.claude/bin/claude" 2>/dev/null
    rm -f "$HOME/.local/bin/claude" 2>/dev/null
    # Remove old PATH entries from shell configs (installer will re-add)
    for rcfile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
        if [ -f "$rcfile" ]; then
            sed -i '/\.claude\/bin/d' "$rcfile" 2>/dev/null
            sed -i '/# Added by Claude/d' "$rcfile" 2>/dev/null
        fi
    done
    hash -r 2>/dev/null

    log_info "Installing Claude Code via native installer..."

    # Capture installer output to extract the install path
    local install_output
    install_output=$(curl -fsSL https://claude.ai/install.sh | bash 2>&1)
    local install_exit=$?

    echo "$install_output"

    if [ $install_exit -eq 0 ]; then
        # Try to extract path from installer output (e.g. "Installed to /home/user/.local/bin/claude")
        local detected_path=""
        detected_path=$(echo "$install_output" | grep -oP '(?:installed to|path:|location:)\s*\K\S+' -i | head -1)

        if [ -n "$detected_path" ] && [ -f "$detected_path" ]; then
            # Got path from installer output
            local detected_dir
            detected_dir=$(dirname "$detected_path")
            export PATH="$detected_dir:$PATH"
            log_info "Detected install path from installer: $detected_path"
        else
            # Fallback: search known locations
            local -a CLAUDE_SEARCH_PATHS=(
                "$HOME/.local/bin/claude"
                "$HOME/.claude/bin/claude"
                "/usr/local/bin/claude"
            )
            for cpath in "${CLAUDE_SEARCH_PATHS[@]}"; do
                if [ -f "$cpath" ]; then
                    detected_path="$cpath"
                    local detected_dir
                    detected_dir=$(dirname "$cpath")
                    export PATH="$detected_dir:$PATH"
                    log_info "Found claude binary at: $cpath"
                    break
                fi
            done
        fi

        # Also try sourcing shell configs
        [ -f "$HOME/.bashrc" ] && source "$HOME/.bashrc" 2>/dev/null
        hash -r 2>/dev/null

        if command_exists claude; then
            log_success "Claude Code installed successfully ($(claude --version 2>/dev/null || echo ''))"
            log_info "Binary location: $(which claude)"
        else
            log_warning "Claude Code installed but 'claude' command not found in PATH"
            log_info "Try: source ~/.bashrc  or restart terminal"
        fi

        # Add to .bashrc if not already there
        local claude_bin_dir=""
        if [ -n "$detected_path" ]; then
            claude_bin_dir=$(dirname "$detected_path")
        fi
        if [ -n "$claude_bin_dir" ] && ! grep -q "$claude_bin_dir" "$HOME/.bashrc" 2>/dev/null; then
            echo "export PATH=\"$claude_bin_dir:\$PATH\"  # Added by ubuntu-setup-script" >> "$HOME/.bashrc"
            log_info "Added $claude_bin_dir to ~/.bashrc PATH"
        fi
    else
        log_warning "Native installer failed, trying npm fallback..."
        if command_exists npm; then
            if retry_npm_install @anthropic-ai/claude-code; then
                log_success "Claude Code installed via npm"
            else
                log_warning "Claude Code installation skipped after all attempts"
                return 1
            fi
        else
            log_warning "Claude Code installation failed (npm not available for fallback)"
            return 1
        fi
    fi

    # Plugins will be installed after CLI login (requires auth)
    if command_exists claude; then
        log_info "Claude Code plugins will be installed after login step"
    fi
}

#===============================================================================
# 3. Google Chrome Installation (via apt repository)
#===============================================================================
# Global flag to track if browser was installed successfully
BROWSER_INSTALLED=false

install_chrome() {
    log_step "3. Installing Browser (Chrome/Chromium)"

    # Clean up broken saiarcot895/chromium-dev PPA if it exists (no longer supports Noble+)
    if ls /etc/apt/sources.list.d/*saiarcot895*chromium* &>/dev/null; then
        log_info "Removing broken Chromium PPA (saiarcot895/chromium-dev)..."
        sudo add-apt-repository --remove -y ppa:saiarcot895/chromium-dev 2>/dev/null || \
            sudo rm -f /etc/apt/sources.list.d/*saiarcot895*chromium*
        log_success "Broken PPA removed"
    fi

    # Check if any browser already installed
    if command_exists google-chrome || command_exists google-chrome-stable || command_exists chromium-browser || command_exists chromium; then
        log_warning "Browser already installed, skipping..."
        BROWSER_INSTALLED=true
        # Still open extension pages for existing browser
        if command_exists google-chrome || command_exists google-chrome-stable; then
            open_browser_extensions "google-chrome"
        elif command_exists chromium-browser; then
            open_browser_extensions "chromium-browser"
        elif command_exists chromium; then
            open_browser_extensions "chromium"
        fi
        return
    fi

    if [ "$DEB_ARCH" == "amd64" ]; then
        # AMD64: Install Google Chrome
        log_info "Installing Google Chrome (AMD64)..."

        # Add Google's signing key (with retry)
        if ! retry_command "Adding Chrome GPG key" bash -c 'curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg'; then
            handle_error "Chrome GPG key could not be added. Chrome installation may fail."
        fi

        # Add repository
        echo "deb [arch=${DEB_ARCH} signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

        # Update and install with retry
        safe_apt_update
        if retry_apt_install google-chrome-stable; then
            log_success "Google Chrome installed successfully (via apt repository)"
            BROWSER_INSTALLED=true

            # Open recommended extensions in browser
            open_browser_extensions "google-chrome"
        else
            handle_error "Chrome installation failed after 3 attempts"
        fi
    else
        # ARM64: Install Chromium (Chrome is not available for ARM64)
        log_info "Installing Chromium for ARM64 (Chrome not available)..."

        local chromium_installed=false

        # Method 1: xtradeb PPA - real .deb Chromium (no snap dependency)
        # MUST come first because Ubuntu's apt chromium-browser is a snap wrapper
        if ! $chromium_installed; then
            log_info "Trying Chromium via xtradeb PPA (native .deb)..."
            if sudo add-apt-repository -y ppa:xtradeb/apps 2>/dev/null; then
                safe_apt_update
                if sudo apt-get install -y chromium 2>/dev/null; then
                    log_success "Chromium installed via xtradeb PPA (native deb)"
                    chromium_installed=true
                fi
            fi
        fi

        # Method 2: Try snap (standard Ubuntu where snap is expected)
        if ! $chromium_installed && command_exists snap; then
            log_info "Trying Chromium via snap..."
            if retry_snap_install chromium; then
                log_success "Chromium installed via snap"
                chromium_installed=true
            fi
        fi

        if $chromium_installed; then
            BROWSER_INSTALLED=true
            # Open recommended extensions in browser
            if command_exists chromium-browser; then
                open_browser_extensions "chromium-browser"
            elif command_exists chromium; then
                open_browser_extensions "chromium"
            fi
        else
            log_warning "Chromium installation failed (xtradeb/snap all failed)"
            log_info "Firefox will be kept as the default browser"
        fi
    fi
}

# Open recommended browser extensions after install
open_browser_extensions() {
    local browser_cmd="$1"
    local extensions=(
        "https://chromewebstore.google.com/detail/ublock/epcnnfbjfcgphgdmggkamkmgojdagdnn"
        "https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn"
    )

    log_info "Opening recommended browser extensions for install..."
    log_info "Please click 'Add to Chrome' for each extension tab"

    for url in "${extensions[@]}"; do
        "$browser_cmd" "$url" &>/dev/null &
        sleep 1
    done

    log_success "Extension pages opened in browser (uBlock, Claude)"
}

#===============================================================================
# 6. Visual Studio Code Installation (via apt repository)
#===============================================================================
install_vscode() {
    log_step "6. Installing Visual Studio Code"

    if command_exists code; then
        log_warning "VS Code already installed, skipping installation..."
    else
        log_info "Adding Microsoft VS Code repository..."

        # Add Microsoft's signing key (with retry)
        if ! retry_command "Adding VS Code GPG key" bash -c 'curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg'; then
            handle_error "VS Code GPG key could not be added. Installation may fail."
        fi

        # Add repository
        echo "deb [arch=${DEB_ARCH} signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

        # Update and install with retry
        safe_apt_update
        if retry_apt_install code; then
            log_success "VS Code installed successfully (via apt repository)"
        else
            handle_error "VS Code installation failed after 3 attempts"
            return
        fi
    fi

    # Install extensions
    install_vscode_extensions
}

install_vscode_extensions() {
    log_info "6.1-6.4 Installing VS Code Extensions..."

    # 6.1 Claude Code (Claude Dev)
    log_info "6.2 Installing Claude Code extension..."
    if code --list-extensions 2>/dev/null | grep -qi "anthropic.claude-code"; then
        log_warning "Claude Code already installed, skipping..."
    else
        code --install-extension anthropic.claude-code --force 2>/dev/null || \
        code --install-extension saoudrizwan.claude-dev --force 2>/dev/null || \
        log_warning "Could not install Claude extension"
    fi

    # 6.3 ChatGPT/Codex Extension
    log_info "6.3 Installing ChatGPT extension..."
    if code --list-extensions 2>/dev/null | grep -qi "openai.chatgpt"; then
        log_warning "ChatGPT extension already installed, skipping..."
    else
        code --install-extension openai.chatgpt --force 2>/dev/null || \
        code --install-extension gencay.vscode-chatgpt --force 2>/dev/null || \
        log_warning "Could not install ChatGPT extension"
    fi

    # 6.4 Python Extension
    log_info "6.4 Installing Python extension..."
    if code --list-extensions 2>/dev/null | grep -qi "ms-python.python"; then
        log_warning "Python extension already installed, skipping..."
    else
        code --install-extension ms-python.python --force 2>/dev/null || \
        log_warning "Could not install Python extension"
    fi

    log_success "VS Code extensions installation completed"

    # Configure VS Code user settings
    configure_vscode_settings
}

configure_vscode_settings() {
    log_info "6.5 Configuring VS Code user settings..."

    local settings_dir="$HOME/.config/Code/User"
    local settings_file="$settings_dir/settings.json"

    # Create settings directory if it doesn't exist
    mkdir -p "$settings_dir"

    # Write settings file
    cat > "$settings_file" << 'VSCODE_SETTINGS'
{
  "editor.defaultFormatter": "vscode.typescript-language-features",
  "git.confirmSync": false,
  "github.experimental.multipleAccounts": true,
  "editor.unicodeHighlight.allowedCharacters": {
    "​": true
  },
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit",
    "source.fixAll.stylelint": "never",
    "source.fixAll.tslint": "explicit"
  },
  "css.validate": true,
  "less.validate": false,
  "scss.validate": true,
  "security.workspace.trust.untrustedFiles": "open",
  "[scss]": {
    "editor.defaultFormatter": "vscode.css-language-features"
  },
  "[javascript]": {
    "editor.defaultFormatter": "vscode.typescript-language-features"
  },
  "[html]": {
    "editor.defaultFormatter": "vscode.html-language-features"
  },
  "editor.formatOnSave": true,
  "[markdown]": {
    "editor.rulers": [80]
  },
  "eslint.validate": ["javascript", "javascriptreact", "markdown", "typescript", "typescriptreact"],
  "stylelint.validate": ["scss"],
  "[typescript]": {
    "editor.defaultFormatter": "vscode.typescript-language-features"
  },
  "[json]": {
    "editor.defaultFormatter": "vscode.typescript-language-features"
  },
  "workbench.colorTheme": "Visual Studio Light",
  "editor.fontSize": 13,
  "editor.minimap.enabled": false,
  "telemetry.telemetryLevel": "off",
  "git.suggestSmartCommit": false,
  "extensions.ignoreRecommendations": true,
  "workbench.layoutControl.enabled": false,
  "window.customTitleBarVisibility": "windowed",
  "window.titleBarStyle": "custom",
  "githubPullRequests.fileListLayout": "flat",
  "workbench.editor.enablePreview": false,
  "workbench.startupEditor": "none",
  "editor.unicodeHighlight.ambiguousCharacters": false,
  "workbench.editor.centeredLayoutAutoResize": false,
  "githubPullRequests.pullBranch": "never",
  "diffEditor.ignoreTrimWhitespace": false,
  "diffEditor.hideUnchangedRegions.enabled": true,
  "terminal.integrated.env.linux": {},
  "git.openRepositoryInParentFolders": "never",
  "gitblame.inlineMessageEnabled": true,
  "githubPullRequests.createOnPublishBranch": "never",
  "terminal.integrated.stickyScroll.enabled": false,
  "claudeCode.selectedModel": "default",
  "editor.stickyScroll.enabled": false,
  "editor.stickyScroll.scrollWithEditor": false,
  "workbench.tree.enableStickyScroll": false,
  "workbench.settings.showAISearchToggle": false,
  "chatgpt.cliExecutable": "",
  "chat.disableAIFeatures": true,
  "claudeCode.preferredLocation": "panel",
  "claudeCode.allowDangerouslySkipPermissions": true,
  "claudeCode.initialPermissionMode": "bypassPermissions",
  "git.autofetch": true,
  "gitblame.revsFile": []
}
VSCODE_SETTINGS

    log_success "VS Code user settings configured"

}

#===============================================================================
# 7. Python 3 Installation
#===============================================================================
install_python() {
    log_step "7. Installing Python 3"

    if command_exists python3; then
        log_warning "Python 3 already installed ($(python3 --version)), skipping..."
    else
        log_info "Installing Python 3..."
        safe_apt_update
        sudo apt-get install -y python3 python3-pip python3-venv || handle_error "Python 3 installation failed"
        log_success "Python 3 installed successfully"
    fi

    # Ensure pip is available
    if ! command_exists pip3; then
        log_info "Installing pip3..."
        sudo apt-get install -y python3-pip
    fi
}

#===============================================================================
# Helper: Force-enable a GNOME extension via gsettings (fallback for Armbian etc.)
#===============================================================================
force_enable_extension() {
    local ext_uuid="$1"
    if [ -z "$ext_uuid" ]; then return; fi

    # Method 1: gnome-extensions CLI (works when GNOME Shell is running)
    gnome-extensions enable "$ext_uuid" 2>/dev/null || true

    # Method 2: gsettings fallback - directly add to enabled-extensions list
    # This ensures extensions are enabled even if GNOME Shell isn't fully running
    local current_extensions
    current_extensions=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null) || return 0

    # Check if already in the list
    if echo "$current_extensions" | grep -q "'$ext_uuid'"; then
        return 0
    fi

    # Add to the enabled list
    if [ "$current_extensions" = "@as []" ] || [ -z "$current_extensions" ]; then
        gsettings set org.gnome.shell enabled-extensions "['$ext_uuid']" 2>/dev/null || true
    else
        # Remove trailing ] and append new UUID
        local new_extensions
        new_extensions=$(echo "$current_extensions" | sed "s/]$/, '$ext_uuid']/")
        gsettings set org.gnome.shell enabled-extensions "$new_extensions" 2>/dev/null || true
    fi
}

#===============================================================================
# 8. GNOME Shell Extensions
#===============================================================================
install_gnome_extensions() {
    log_step "8. Ubuntu (GNOME) Tweaks"

    # Check if GNOME is installed
    if ! command_exists gnome-shell; then
        log_warning "GNOME Shell not detected, skipping extensions installation..."
        return
    fi

    log_info "Installing GNOME Shell Extensions packages..."

    # Install Extension Manager (modern way to manage extensions)
    if package_installed gnome-shell-extension-manager; then
        log_warning "Extension Manager already installed, skipping..."
    else
        sudo apt-get install -y gnome-shell-extension-manager 2>/dev/null || \
        log_warning "Extension Manager not available in repositories"
    fi

    # Install GNOME Shell Extensions package (includes common extensions)
    if package_installed gnome-shell-extensions; then
        log_warning "GNOME Shell Extensions already installed, skipping..."
    else
        sudo apt-get install -y gnome-shell-extensions
        log_success "GNOME Shell Extensions installed"
    fi

    # Install browser connector for extensions.gnome.org
    if package_installed gnome-browser-connector; then
        log_warning "GNOME Browser Connector already installed, skipping..."
    else
        sudo apt-get install -y gnome-browser-connector 2>/dev/null || \
        sudo apt-get install -y chrome-gnome-shell 2>/dev/null || \
        log_warning "Browser connector not available"
    fi

    # Install gnome-tweaks for additional customization
    if package_installed gnome-tweaks; then
        log_warning "GNOME Tweaks already installed, skipping..."
    else
        sudo apt-get install -y gnome-tweaks
        log_success "GNOME Tweaks installed"
    fi

    # Install AppIndicator extension (system tray support)
    log_info "Installing AppIndicator extension (system tray)..."
    if package_installed gnome-shell-extension-appindicator; then
        log_warning "AppIndicator already installed"
    else
        sudo apt-get install -y gnome-shell-extension-appindicator 2>/dev/null || \
        log_warning "AppIndicator package not available"
    fi
    force_enable_extension "appindicatorsupport@rgcjonas.gmail.com"
    force_enable_extension "ubuntu-appindicators@ubuntu.com"
    log_success "AppIndicator (system tray) enabled"

    # Install Script Launcher GNOME extension (custom fork)
    install_gnome_script_launcher

    log_success "GNOME Shell Extensions setup completed"
    log_info "You can manage extensions via:"
    echo "  - Extension Manager app"
    echo "  - https://extensions.gnome.org (with browser)"
    echo "  - gnome-tweaks"

    # Configure Dash to Dock settings
    configure_dash_to_dock
}

#===============================================================================
# GNOME Backup Functions
#===============================================================================
backup_gnome_settings() {
    log_info "Creating GNOME settings backup..."

    local backup_dir="$BACKUP_DIR/gnome-backup"
    local timestamp=$(date +%Y%m%d_%H%M%S)

    # Create backup directory
    mkdir -p "$backup_dir"

    # Backup dash-to-dock settings
    if dconf list /org/gnome/shell/extensions/dash-to-dock/ &>/dev/null; then
        dconf dump /org/gnome/shell/extensions/dash-to-dock/ > "$backup_dir/dash-to-dock.dconf"
        log_info "  Backed up: Dash to Dock settings"
    fi

    # Backup general shell settings
    if dconf list /org/gnome/shell/ &>/dev/null; then
        dconf dump /org/gnome/shell/ > "$backup_dir/gnome-shell.dconf"
        log_info "  Backed up: GNOME Shell settings"
    fi

    # Backup desktop settings
    if dconf list /org/gnome/desktop/ &>/dev/null; then
        dconf dump /org/gnome/desktop/ > "$backup_dir/gnome-desktop.dconf"
        log_info "  Backed up: GNOME Desktop settings"
    fi

    # Save timestamp
    echo "$timestamp" > "$backup_dir/backup-timestamp"

    log_success "GNOME backup saved to: $backup_dir"
}

show_gnome_backup() {
    local backup_dir="$BACKUP_DIR/gnome-backup"

    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    GNOME Settings Backup                       ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ ! -d "$backup_dir" ]; then
        echo -e "${YELLOW}No backup found at: $backup_dir${NC}"
        echo ""
        echo "Run the script with --gnome to create a backup before making changes."
        return 1
    fi

    # Show timestamp
    if [ -f "$backup_dir/backup-timestamp" ]; then
        local timestamp=$(cat "$backup_dir/backup-timestamp")
        echo -e "${GREEN}Backup Date:${NC} $timestamp"
        echo ""
    fi

    # Show backup files
    echo -e "${GREEN}Backup Location:${NC} $backup_dir"
    echo ""
    echo -e "${GREEN}Backup Files:${NC}"
    ls -la "$backup_dir" 2>/dev/null | tail -n +2
    echo ""

    # Show Dash to Dock backup content
    if [ -f "$backup_dir/dash-to-dock.dconf" ]; then
        echo -e "${YELLOW}─────────────────────────────────────────────────────────────────${NC}"
        echo -e "${GREEN}Dash to Dock Settings:${NC}"
        echo -e "${YELLOW}─────────────────────────────────────────────────────────────────${NC}"
        cat "$backup_dir/dash-to-dock.dconf"
        echo ""
    fi

    echo -e "${CYAN}To restore: $0 --restore-gnome-desktop${NC}"
    echo ""
}

restore_gnome_settings() {
    local backup_dir="$BACKUP_DIR/gnome-backup"

    echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                  Restoring GNOME Settings                      ║${NC}"
    echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    if [ ! -d "$backup_dir" ]; then
        echo -e "${RED}No backup found at: $backup_dir${NC}"
        echo ""
        echo "Cannot restore without a backup."
        return 1
    fi

    # Check if dconf is available
    if ! command_exists dconf; then
        echo -e "${RED}dconf command not found. Cannot restore settings.${NC}"
        return 1
    fi

    # Show timestamp
    if [ -f "$backup_dir/backup-timestamp" ]; then
        local timestamp=$(cat "$backup_dir/backup-timestamp")
        echo -e "${GREEN}Restoring from backup:${NC} $timestamp"
        echo ""
    fi

    # Confirm restore
    read -p "Are you sure you want to restore GNOME settings? (y/n): " -n 1 -r < /dev/tty
    echo ""

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Restore cancelled."
        return 0
    fi

    # Restore dash-to-dock settings
    if [ -f "$backup_dir/dash-to-dock.dconf" ]; then
        echo -e "${BLUE}[INFO]${NC} Restoring Dash to Dock settings..."
        dconf load /org/gnome/shell/extensions/dash-to-dock/ < "$backup_dir/dash-to-dock.dconf"
        echo -e "${GREEN}[SUCCESS]${NC} Dash to Dock restored"
    fi

    # Restore general shell settings
    if [ -f "$backup_dir/gnome-shell.dconf" ]; then
        echo -e "${BLUE}[INFO]${NC} Restoring GNOME Shell settings..."
        dconf load /org/gnome/shell/ < "$backup_dir/gnome-shell.dconf"
        echo -e "${GREEN}[SUCCESS]${NC} GNOME Shell restored"
    fi

    # Restore desktop settings
    if [ -f "$backup_dir/gnome-desktop.dconf" ]; then
        echo -e "${BLUE}[INFO]${NC} Restoring GNOME Desktop settings..."
        dconf load /org/gnome/desktop/ < "$backup_dir/gnome-desktop.dconf"
        echo -e "${GREEN}[SUCCESS]${NC} GNOME Desktop restored"
    fi

    echo ""
    echo -e "${GREEN}GNOME settings restored successfully!${NC}"
    echo -e "${YELLOW}Note: You may need to restart GNOME Shell (Alt+F2, then 'r') for changes to take effect.${NC}"
}

#===============================================================================
# Script Launcher GNOME Extension (custom fork)
#===============================================================================
install_gnome_script_launcher() {
    log_info "Installing Script Launcher GNOME extension..."

    local gnome_version
    gnome_version=$(gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1)

    if [ -z "$gnome_version" ]; then
        log_warning "Could not detect GNOME Shell version, skipping Script Launcher..."
        return
    fi

    # Ensure unzip is available
    if ! command_exists unzip; then
        log_info "Installing unzip..."
        sudo apt-get install -y unzip
    fi

    local ext_uuid="script-launcher@enginyilmaaz"
    local ext_dir="$HOME/.local/share/gnome-shell/extensions/$ext_uuid"
    local zip_url="https://github.com/enginyilmaaz/gnome_extension_script_launcher/releases/latest/download/script-launcher.zip"
    local temp_zip="/tmp/script-launcher.zip"

    # Check if already installed
    if [ -d "$ext_dir" ]; then
        log_info "Script Launcher already installed, updating..."
        rm -rf "$ext_dir"
    fi

    # Download latest release
    if ! retry_curl_download "$zip_url" "$temp_zip" "Downloading Script Launcher extension"; then
        log_warning "Script Launcher download failed, skipping..."
        return
    fi

    # Create extension directory and extract
    mkdir -p "$ext_dir"
    if unzip -o "$temp_zip" -d "$ext_dir" > /dev/null 2>&1; then
        log_success "Script Launcher extension extracted to $ext_dir"
    else
        log_warning "Failed to extract Script Launcher, skipping..."
        rm -f "$temp_zip"
        return
    fi
    rm -f "$temp_zip"

    # Read actual UUID from metadata.json if it differs
    if [ -f "$ext_dir/metadata.json" ]; then
        local actual_uuid
        actual_uuid=$(python3 -c "import json; print(json.load(open('$ext_dir/metadata.json'))['uuid'])" 2>/dev/null)
        if [ -n "$actual_uuid" ] && [ "$actual_uuid" != "$ext_uuid" ]; then
            local actual_dir="$HOME/.local/share/gnome-shell/extensions/$actual_uuid"
            mv "$ext_dir" "$actual_dir"
            ext_uuid="$actual_uuid"
            ext_dir="$actual_dir"
            log_info "Extension UUID: $ext_uuid"
        fi
    fi

    # Compile GSettings schema if present
    if [ -d "$ext_dir/schemas" ] && command_exists glib-compile-schemas; then
        glib-compile-schemas "$ext_dir/schemas/" 2>/dev/null
        log_info "GSettings schemas compiled"
    fi

    # Enable the extension (gnome-extensions CLI + gsettings fallback for Armbian)
    log_info "Enabling Script Launcher extension..."
    force_enable_extension "$ext_uuid"

    # Verify it's enabled
    if gnome-extensions list --enabled 2>/dev/null | grep -q "$ext_uuid"; then
        log_success "Script Launcher GNOME extension installed and enabled"
    else
        log_success "Script Launcher GNOME extension installed"
        log_warning "Extension may require log out/in or GNOME Shell restart to activate"
        log_info "After reboot, enable manually: gnome-extensions enable $ext_uuid"
    fi
}

#===============================================================================
# 8.1 Dash to Dock Configuration (using dconf)
#===============================================================================
configure_dash_to_dock() {
    log_info "8.1 Configuring Dash to Dock settings..."

    # Check if dconf is available
    if ! command_exists dconf; then
        log_warning "dconf not available, skipping Dash to Dock configuration..."
        return
    fi

    # Install Dash to Dock extension if not already installed
    # Ubuntu uses "ubuntu-dock" (fork of dash-to-dock) or the original "dash-to-dock"
    local dtd_installed=false

    if gnome-extensions list 2>/dev/null | grep -q "dash-to-dock\|ubuntu-dock"; then
        dtd_installed=true
        log_info "Dash to Dock / Ubuntu Dock already installed"
    elif [ -d "$HOME/.local/share/gnome-shell/extensions/dash-to-dock@micxgx.gmail.com" ]; then
        dtd_installed=true
    fi

    if ! $dtd_installed; then
        log_info "Dash to Dock not found, installing..."

        local gnome_ver
        gnome_ver=$(gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1)
        local dtd_zip="/tmp/dash-to-dock.zip"
        local dtd_uuid="dash-to-dock@micxgx.gmail.com"
        local dtd_dir="$HOME/.local/share/gnome-shell/extensions/$dtd_uuid"

        # Method 1: Try apt packages first
        if sudo apt-get install -y gnome-shell-extension-ubuntu-dock 2>/dev/null; then
            log_success "Ubuntu Dock installed via apt"
        elif sudo apt-get install -y gnome-shell-extension-dash-to-dock 2>/dev/null; then
            log_success "Dash to Dock installed via apt"
        else
            # Method 2: Download from extensions.gnome.org (same as manual install)
            log_info "Downloading Dash to Dock from extensions.gnome.org..."

            # Query the API for the correct version matching our GNOME Shell
            local ext_info
            ext_info=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${dtd_uuid}&shell_version=${gnome_ver}" 2>/dev/null)

            if [ -n "$ext_info" ]; then
                local download_url
                download_url=$(echo "$ext_info" | python3 -c "
import sys, json
data = json.load(sys.stdin)
# Get download URL for our shell version
for ver, info in data.get('shell_version_map', {}).items():
    print('https://extensions.gnome.org' + info.get('download_url', ''))
    break
" 2>/dev/null)

                if [ -n "$download_url" ] && curl -fsSL -o "$dtd_zip" "$download_url" 2>/dev/null; then
                    # Use gnome-extensions install (proper way)
                    if gnome-extensions install --force "$dtd_zip" 2>/dev/null; then
                        log_success "Dash to Dock installed from extensions.gnome.org"
                    else
                        # Fallback: manual extract
                        mkdir -p "$dtd_dir"
                        unzip -o "$dtd_zip" -d "$dtd_dir" > /dev/null 2>&1
                        if [ -d "$dtd_dir/schemas" ] && command_exists glib-compile-schemas; then
                            glib-compile-schemas "$dtd_dir/schemas/" 2>/dev/null
                        fi
                        log_success "Dash to Dock installed (manual extract)"
                    fi
                    rm -f "$dtd_zip"
                else
                    log_warning "Could not download Dash to Dock. Install manually from:"
                    log_warning "https://extensions.gnome.org/extension/307/dash-to-dock/"
                fi
            else
                log_warning "Could not query extensions.gnome.org API"
                log_warning "Install Dash to Dock manually: https://extensions.gnome.org/extension/307/dash-to-dock/"
            fi
        fi
    fi

    # Enable the extension (try both UUIDs + gsettings fallback for Armbian)
    force_enable_extension "dash-to-dock@micxgx.gmail.com"
    force_enable_extension "ubuntu-dock@ubuntu.com"

    # Backup current settings before making changes
    backup_gnome_settings

    log_info "Applying Dash to Dock settings via dconf..."

    # Create temporary config file and load with dconf
    cat << 'DOCKCONF' | dconf load /org/gnome/shell/extensions/dash-to-dock/
[/]
animate-show-apps=true
apply-custom-theme=false
background-opacity=1.0
border-radius=0
click-action='minimize-or-previews'
custom-theme-shrink=true
dash-max-icon-size=32
disable-overview-on-startup=true
dock-fixed=true
dock-position='BOTTOM'
extend-height=true
floating-margin=0
height-fraction=0.90000000000000002
hot-keys=false
icon-size-fixed=true
intellihide-mode='FOCUS_APPLICATION_WINDOWS'
isolate-monitors=false
isolate-workspaces=false
max-alpha=0.80000000000000004
multi-monitor=true
preferred-monitor=-2
preferred-monitor-by-connector='Virtual1'
running-indicator-style='DASHES'
show-apps-always-in-the-edge=false
show-apps-at-top=true
show-favorites=true
show-mounts=false
show-mounts-only-mounted=false
show-mounts-network=false
show-running=true
show-trash=false
show-windows-preview=true
transparency-mode='FIXED'
DOCKCONF

    log_success "Dash to Dock configured successfully"

    # Disable dynamic workspaces and set to 1
    log_info "Disabling virtual desktops (setting to 1 static workspace)..."
    dconf write /org/gnome/mutter/dynamic-workspaces false
    dconf write /org/gnome/desktop/wm/preferences/num-workspaces 1
    log_success "Virtual desktops disabled (1 static workspace)"

    # Set power profile to Performance
    if command_exists powerprofilesctl; then
        log_info "Setting power profile to Performance..."
        powerprofilesctl set performance
        log_success "Power profile set to Performance"
    else
        log_warning "powerprofilesctl not found, trying via dconf..."
    fi

    # Disable screen blank / screen off (set to never)
    log_info "Disabling screen timeout (set to never)..."
    gsettings set org.gnome.desktop.session idle-delay 0
    gsettings set org.gnome.desktop.screensaver lock-enabled false
    gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
    # Disable automatic suspend
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
    gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
    log_success "Screen timeout disabled (never turns off)"

    # Show hidden files in file manager
    log_info "Enabling show hidden files in file manager..."
    gsettings set org.gtk.Settings.FileChooser show-hidden true 2>/dev/null
    gsettings set org.gtk.gtk4.Settings.FileChooser show-hidden true 2>/dev/null
    dconf write /org/gtk/settings/file-chooser/show-hidden true 2>/dev/null
    dconf write /org/gtk/gtk4/settings/file-chooser/show-hidden true 2>/dev/null
    # Nautilus (Files app)
    gsettings set org.gnome.nautilus.preferences show-hidden-files true 2>/dev/null
    log_success "Show hidden files enabled"

    # Set EVERYTHING to English (US) - language, region, formats, menus
    log_info "Setting system language to English (US)..."

    # Install English language packs, remove Turkish display language
    sudo apt-get install -y language-pack-en language-pack-en-base language-pack-gnome-en language-pack-gnome-en-base 2>/dev/null || true

    # Generate English locale
    sudo locale-gen en_US.UTF-8 2>/dev/null || true

    # System-wide locale - set ALL locale variables to English
    sudo update-locale \
        LANG=en_US.UTF-8 \
        LANGUAGE=en_US:en \
        LC_ALL=en_US.UTF-8 \
        LC_CTYPE=en_US.UTF-8 \
        LC_NUMERIC=en_US.UTF-8 \
        LC_TIME=en_US.UTF-8 \
        LC_COLLATE=en_US.UTF-8 \
        LC_MONETARY=en_US.UTF-8 \
        LC_MESSAGES=en_US.UTF-8 \
        LC_PAPER=en_US.UTF-8 \
        LC_NAME=en_US.UTF-8 \
        LC_ADDRESS=en_US.UTF-8 \
        LC_TELEPHONE=en_US.UTF-8 \
        LC_MEASUREMENT=en_US.UTF-8 \
        LC_IDENTIFICATION=en_US.UTF-8 2>/dev/null || true

    sudo localectl set-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en 2>/dev/null || true

    # GNOME display language + region
    dconf write /system/locale/region "'en_US.UTF-8'" 2>/dev/null || true
    gsettings set org.gnome.system.locale region 'en_US.UTF-8' 2>/dev/null || true

    # Set AccountsService language (controls login screen + GNOME session language)
    local current_user
    current_user=$(whoami)
    local accounts_file="/var/lib/AccountsService/users/$current_user"
    if [ -f "$accounts_file" ]; then
        # Update existing file - replace or add Language line
        if sudo grep -q "^Language=" "$accounts_file" 2>/dev/null; then
            sudo sed -i 's/^Language=.*/Language=en_US.UTF-8/' "$accounts_file"
        else
            sudo sed -i '/^\[User\]/a Language=en_US.UTF-8' "$accounts_file"
        fi
    else
        sudo bash -c "cat > $accounts_file" << ACCOUNTSEOF 2>/dev/null || true
[User]
Language=en_US.UTF-8
XSession=
ACCOUNTSEOF
    fi

    # Export for current session
    export LANG=en_US.UTF-8
    export LANGUAGE=en_US:en
    export LC_ALL=en_US.UTF-8
    log_success "System language set to English (US) - ALL menus, formats, regions"

    # Set keyboard layout to Turkish Q (ONLY keyboard, not language)
    log_info "Setting keyboard layout to Turkish Q..."
    gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'tr')]" 2>/dev/null || true
    sudo localectl set-x11-keymap tr pc105 "" "" 2>/dev/null || true
    log_success "Keyboard layout set to Turkish Q"

    # Disable Wayland (X11 is more compatible with VNC and remote desktop)
    disable_wayland

    # Enable OpenSSH server (auto-start on boot + start now)
    enable_ssh_server

    # Enable RDP server (xrdp, auto-start on boot + start now)
    enable_rdp_server
}

#===============================================================================
# Enable OpenSSH Server (auto-install, enable, start)
#===============================================================================
enable_ssh_server() {
    log_info "Enabling OpenSSH server..."

    # Install openssh-server if missing
    if ! package_installed openssh-server; then
        sudo apt-get install -y openssh-server 2>/dev/null || {
            log_warning "openssh-server could not be installed, skipping..."
            return
        }
        log_success "openssh-server installed"
    else
        log_info "openssh-server already installed"
    fi

    # Enable on boot and start now
    sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null || true
    sudo systemctl start ssh 2>/dev/null || sudo systemctl start sshd 2>/dev/null || true

    # Allow through UFW if active
    if command_exists ufw && sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        sudo ufw allow ssh 2>/dev/null || true
    fi

    # Verify
    if systemctl is-active ssh &>/dev/null || systemctl is-active sshd &>/dev/null; then
        log_success "OpenSSH server active and enabled on boot (port 22)"
    else
        log_warning "OpenSSH service status unknown, check with: sudo systemctl status ssh"
    fi
}

#===============================================================================
# Enable RDP Server (xrdp, auto-install, enable, start)
#===============================================================================
enable_rdp_server() {
    log_info "Enabling RDP server (xrdp)..."

    # Install xrdp if missing
    if ! package_installed xrdp; then
        sudo apt-get install -y xrdp 2>/dev/null || {
            log_warning "xrdp could not be installed, skipping..."
            return
        }
        log_success "xrdp installed"
    else
        log_info "xrdp already installed"
    fi

    # Add xrdp user to ssl-cert group (required for cert access)
    sudo adduser xrdp ssl-cert 2>/dev/null || true

    # Enable on boot and start now
    sudo systemctl enable xrdp 2>/dev/null || true
    sudo systemctl start xrdp 2>/dev/null || true

    # Allow through UFW if active
    if command_exists ufw && sudo ufw status 2>/dev/null | grep -q "Status: active"; then
        sudo ufw allow 3389/tcp 2>/dev/null || true
    fi

    # Verify
    if systemctl is-active xrdp &>/dev/null; then
        log_success "RDP (xrdp) server active and enabled on boot (port 3389)"
    else
        log_warning "xrdp service status unknown, check with: sudo systemctl status xrdp"
    fi
}

#===============================================================================
# CLI Shortcuts: Bash Aliases + Nautilus Right-Click Actions
#===============================================================================
setup_cli_shortcuts() {
    log_info "Setting up CLI shortcuts and Nautilus context menu actions..."

    local bashrc="$HOME/.bashrc"
    local added=false

    # --- Bash Aliases ---
    # Remove old aliases if they exist (to update to new versions)
    sed -i '/^alias claude-skip=/d' "$bashrc" 2>/dev/null
    sed -i '/^alias ccskip=/d' "$bashrc" 2>/dev/null
    sed -i '/^alias codex-skip=/d' "$bashrc" 2>/dev/null
    sed -i '/^alias cxskip=/d' "$bashrc" 2>/dev/null
    sed -i '/^# Claude Code aliases/d' "$bashrc" 2>/dev/null
    sed -i '/^# Codex aliases/d' "$bashrc" 2>/dev/null

    # Claude Code aliases
    if command_exists claude; then
        echo "" >> "$bashrc"
        echo "# Claude Code aliases (added by ubuntu-setup-script)" >> "$bashrc"
        echo "alias claude-skip='claude --dangerously-skip-permissions --effort max'" >> "$bashrc"
        echo "alias ccskip='claude --dangerously-skip-permissions --effort max'" >> "$bashrc"
        log_success "Aliases added: claude-skip, ccskip"
        added=true
    fi

    # Codex aliases
    if command_exists codex; then
        if ! $added; then echo "" >> "$bashrc"; fi
        echo "# Codex aliases (added by ubuntu-setup-script)" >> "$bashrc"
        echo "alias codex-skip='codex --sandbox danger-full-access -c model_reasoning_effort=\"xhigh\"'" >> "$bashrc"
        echo "alias cxskip='codex --sandbox danger-full-access -c model_reasoning_effort=\"xhigh\"'" >> "$bashrc"
        log_success "Aliases added: codex-skip, cxskip"
    fi

    # --- Nautilus Context Menu (python3-nautilus MenuProvider) ---
    # Clean up legacy script-based approach from previous revisions
    rm -f "$HOME/.local/share/nautilus/scripts/Open with Claude Code Terminal" 2>/dev/null
    rm -f "$HOME/.local/share/nautilus/scripts/Open with Codex Terminal" 2>/dev/null

    log_info "Installing Nautilus context menu extension (Claude Code / Codex / VS Code)..."

    # Install python3-nautilus (required for MenuProvider extensions)
    if ! package_installed python3-nautilus; then
        sudo apt-get install -y python3-nautilus 2>/dev/null || {
            log_warning "python3-nautilus could not be installed, skipping context menu setup..."
            return
        }
    fi

    local ext_dir="$HOME/.local/share/nautilus-python/extensions"
    mkdir -p "$ext_dir"

    cat > "$ext_dir/smai-context-menus.py" << 'PY_EOF'
#!/usr/bin/env python3
import os
import shlex
import subprocess

import gi
try:
    gi.require_version('Nautilus', '4.0')
except ValueError:
    try:
        gi.require_version('Nautilus', '3.0')
    except ValueError:
        pass
from gi.repository import Nautilus, GObject  # noqa: E402


CLAUDE_CMD = 'claude --dangerously-skip-permissions --effort max'
CODEX_CMD  = 'codex --sandbox danger-full-access -c model_reasoning_effort="xhigh"'

ACTIONS = (
    ('SmaiOpenClaude', 'Open in Claude Code', CLAUDE_CMD, True),
    ('SmaiOpenCodex',  'Open in Codex CLI',   CODEX_CMD,  True),
    ('SmaiOpenVscode', 'Open in VS Code',     'code',     False),
)


def _run_in_terminal(_mi, cmd, path):
    subprocess.Popen([
        'gnome-terminal', '--working-directory=' + path, '--',
        'bash', '-ic', cmd + '; exec bash'
    ])


def _run_gui(_mi, cmd, path):
    subprocess.Popen(['bash', '-ic', cmd + ' ' + shlex.quote(path)])


class SmaiContextMenus(GObject.GObject, Nautilus.MenuProvider):

    def _items_for_path(self, path):
        if not path:
            return []
        items = []
        for name, label, cmd, in_terminal in ACTIONS:
            mi = Nautilus.MenuItem(name=name, label=label, tip='')
            if in_terminal:
                mi.connect('activate', _run_in_terminal, cmd, path)
            else:
                mi.connect('activate', _run_gui, cmd, path)
            items.append(mi)
        return items

    def get_file_items(self, *args):
        files = args[-1] if args else []
        if not files:
            return []
        f = files[0]
        try:
            if not f.is_directory():
                return []
        except Exception:
            return []
        try:
            path = f.get_location().get_path()
        except Exception:
            return []
        return self._items_for_path(path)

    def get_background_items(self, *args):
        folder = args[-1] if args else None
        if folder is None:
            return []
        try:
            path = folder.get_location().get_path()
        except Exception:
            return []
        return self._items_for_path(path)
PY_EOF

    log_success "Nautilus context menu extension installed: Open in Claude Code / Codex CLI / VS Code"

    # Restart Nautilus so the extension is loaded
    if pgrep -x nautilus &>/dev/null; then
        nautilus -q 2>/dev/null &
        log_info "Nautilus refreshed to load new context menu"
    fi

    log_info "Right-click any folder in Files to see the 3 options"
}

#===============================================================================
# 1. RealVNC Connect Installation (via deb) + Wayland Disable
#===============================================================================
install_realvnc() {
    log_step "1. Installing RealVNC Connect"

    # Check multiple ways if RealVNC is already installed
    if package_installed realvnc-connect || \
       package_installed realvnc-vnc-server || \
       command_exists vncserver-x11 || \
       command_exists vncserver || \
       [ -f /usr/bin/vncserver-x11 ] || \
       [ -d /usr/share/vnc ]; then
        log_warning "RealVNC already installed."
        read -p "Reinstall from scratch? (y/n): " reinstall_choice < /dev/tty
        if [[ "$reinstall_choice" =~ ^[Yy]$ ]]; then
            log_info "Removing existing RealVNC installation..."
            sudo apt-get purge -y realvnc-connect realvnc-vnc-server 2>/dev/null
            sudo rm -f /etc/apt/sources.list.d/*realvnc* /etc/apt/sources.list.d/*vnc*
            sudo rm -f /usr/share/keyrings/*realvnc* /etc/apt/trusted.gpg.d/*realvnc*
            sudo rm -rf /usr/share/vnc /usr/bin/vncserver-x11 /usr/bin/vncserver
            sudo apt-get autoremove -y 2>/dev/null
            log_success "Old RealVNC removed, reinstalling..."
        else
            log_info "Keeping existing installation, skipping..."
            disable_wayland
            return
        fi
    fi

    if [ "$DEB_ARCH" == "amd64" ]; then
        # AMD64: Use deb package
        local temp_file="/tmp/realvnc-connect.deb"
        local download_url="https://downloads.realvnc.com/download/file/realvnc-connect/RealVNC-Connect-8.2.2-Linux-x64.deb"

        if ! retry_curl_download "$download_url" "$temp_file" "Downloading RealVNC Connect deb"; then
            log_warning "RealVNC installation skipped after 3 failed attempts. Install manually from https://www.realvnc.com/en/connect/download/vnc/"
        else
            log_info "Installing RealVNC Connect..."
            sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$temp_file"
            rm -f "$temp_file"
            log_success "RealVNC Connect installed successfully"
        fi
    else
        # ARM64: Use tar.gz installer
        local temp_file="/tmp/realvnc-connect.tar.gz"
        local temp_dir="/tmp/realvnc-installer"
        local download_url="https://downloads.realvnc.com/download/file/vnc.files/VNC-Connect-Installer-2.3.0-Linux-ARM64.tar.gz"

        if ! retry_curl_download "$download_url" "$temp_file" "Downloading RealVNC Connect tar.gz"; then
            log_warning "RealVNC installation skipped after 3 failed attempts. Install manually from https://www.realvnc.com/en/connect/download/vnc/"
        else
            log_info "Extracting and installing RealVNC Connect..."
            mkdir -p "$temp_dir"
            tar -xzf "$temp_file" -C "$temp_dir"

            # Run installer
            cd "$temp_dir"
            if [ -f "vncinstall" ]; then
                sudo ./vncinstall
            elif [ -f "VNC-Connect-Installer"* ]; then
                sudo ./VNC-Connect-Installer*
            else
                # Find and run any installer script
                local installer=$(find . -maxdepth 1 -type f -executable | head -1)
                if [ -n "$installer" ]; then
                    sudo "$installer"
                else
                    log_warning "Could not find RealVNC installer"
                fi
            fi
            cd - > /dev/null

            rm -rf "$temp_file" "$temp_dir"
            log_success "RealVNC Connect installed successfully"
        fi
    fi

    # Disable Wayland for VNC compatibility
    disable_wayland
}

disable_wayland() {
    log_info "1.1 Disabling Wayland for VNC compatibility..."

    local gdm_config="/etc/gdm3/custom.conf"

    if [ ! -f "$gdm_config" ]; then
        log_warning "GDM config not found, skipping Wayland disable..."
        return
    fi

    # Backup original config
    sudo cp "$gdm_config" "$gdm_config.backup"

    # Step 1: Remove ALL WaylandEnable lines (commented or not, true or false, with spaces)
    sudo sed -i '/^#.*WaylandEnable/d' "$gdm_config"
    sudo sed -i '/^WaylandEnable/d' "$gdm_config"

    # Step 2: Add WaylandEnable=false under [daemon] section
    if grep -q "^\[daemon\]" "$gdm_config"; then
        sudo sed -i '/^\[daemon\]/a WaylandEnable=false' "$gdm_config"
    else
        echo -e "\n[daemon]\nWaylandEnable=false" | sudo tee -a "$gdm_config" > /dev/null
    fi

    # Verify: must have exactly one WaylandEnable=false and no WaylandEnable=true
    local count_false count_true
    count_false=$(grep -c "^WaylandEnable=false" "$gdm_config" 2>/dev/null) || count_false=0
    count_true=$(grep -c "^WaylandEnable=true" "$gdm_config" 2>/dev/null) || count_true=0

    if [ "$count_false" -eq 1 ] && [ "$count_true" -eq 0 ]; then
        log_success "Wayland disabled successfully"
    else
        log_warning "Wayland disable may have failed (false=$count_false, true=$count_true), check $gdm_config manually"
    fi
    log_info "Note: Restart required for changes to take effect"
}

#===============================================================================
# 9. DBeaver CE Installation (via apt repository)
#===============================================================================
install_dbeaver() {
    log_step "9. Installing DBeaver Community Edition"

    if package_installed dbeaver-ce || command_exists dbeaver; then
        log_warning "DBeaver CE already installed, skipping..."
        return
    fi

    if [ "$DEB_ARCH" == "amd64" ]; then
        # AMD64: Use apt repository
        log_info "Installing DBeaver CE via apt repository..."

        # Add DBeaver repository with retry
        if ! retry_command "Adding DBeaver GPG key" sudo wget -O /usr/share/keyrings/dbeaver.gpg.key https://dbeaver.io/debs/dbeaver.gpg.key; then
            handle_error "DBeaver GPG key could not be added. Installation may fail."
        fi

        echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg.key] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list > /dev/null

        safe_apt_update
        if retry_apt_install dbeaver-ce; then
            log_success "DBeaver CE installed successfully (via apt repository)"
        else
            handle_error "DBeaver CE installation failed after 3 attempts"
        fi
    else
        # ARM64: Use deb package directly
        log_info "Installing DBeaver CE via deb package (ARM64)..."

        local temp_file="/tmp/dbeaver-ce.deb"
        local download_url="https://dbeaver.io/files/dbeaver-ce_latest_arm64.deb"

        if ! retry_curl_download "$download_url" "$temp_file" "Downloading DBeaver CE deb"; then
            log_warning "DBeaver installation skipped after 3 failed attempts. Install manually from https://dbeaver.io/download/"
            return
        fi

        log_info "Installing DBeaver CE..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$temp_file"
        rm -f "$temp_file"
        log_success "DBeaver CE installed successfully (via deb package)"
    fi
}

#===============================================================================
# 10. VLC Media Player Installation (via apt)
#===============================================================================
install_vlc() {
    log_step "10. Installing VLC Media Player"

    if command_exists vlc; then
        log_warning "VLC already installed, skipping..."
        return
    fi

    log_info "Installing VLC via apt..."
    if retry_apt_install vlc; then
        log_success "VLC Media Player installed successfully"
    else
        log_warning "VLC installation skipped after 3 failed attempts"
    fi
}

#===============================================================================
# 11. Cloudflared (Cloudflare Connector) Installation (via apt repository)
#===============================================================================
install_cloudflared() {
    log_step "11. Installing Cloudflared (Cloudflare Connector)"

    if command_exists cloudflared; then
        log_warning "Cloudflared already installed ($(cloudflared --version 2>&1 | head -1)), skipping..."
        return
    fi

    log_info "Installing Cloudflared via official apt repository..."

    # Add Cloudflare GPG key
    sudo mkdir -p --mode=0755 /usr/share/keyrings
    if ! retry_command "Adding Cloudflare GPG key" bash -c 'curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | sudo tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null'; then
        handle_error "Cloudflare GPG key could not be added. Installation may fail."
    fi

    # Add Cloudflare repository
    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' | sudo tee /etc/apt/sources.list.d/cloudflared.list > /dev/null

    # Update and install cloudflared
    safe_apt_update
    if retry_apt_install cloudflared; then
        log_success "Cloudflared installed successfully"
    else
        handle_error "Cloudflared installation failed after 3 attempts"
    fi
}

#===============================================================================
# 12. Docker Installation (via apt repository)
#===============================================================================
install_docker() {
    log_step "12. Installing Docker"

    if command_exists docker; then
        log_warning "Docker already installed ($(docker --version)), skipping..."
        return
    fi

    log_info "Installing Docker via official apt repository..."

    # Add Docker's official GPG key
    if ! retry_command "Adding Docker GPG key" bash -c 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg'; then
        handle_error "Docker GPG key could not be added. Installation may fail."
    fi

    # Add Docker repository
    echo "deb [arch=${DEB_ARCH} signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${OS_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update and install Docker
    safe_apt_update
    if retry_apt_install docker-ce; then
        # Install additional Docker components
        sudo apt-get install -y docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        # Add current user to docker group (no sudo needed for docker commands)
        sudo usermod -aG docker $USER

        log_success "Docker installed successfully"
        log_info "Note: Log out and back in for docker group to take effect"
    else
        log_warning "Docker installation skipped after 3 failed attempts"
    fi
}

#===============================================================================
# 13. CLI Login Commands
#===============================================================================
# Install Claude Code plugins (requires auth - run after login)
install_claude_plugins() {
    export PATH="$HOME/.claude/bin:$HOME/.local/bin:$PATH"
    hash -r 2>/dev/null

    if ! command_exists claude; then
        log_warning "Claude plugins skipped: 'claude' command not found"
        return
    fi

    # Check if authenticated
    if ! claude auth status &>/dev/null; then
        log_warning "Claude plugins skipped: not authenticated"
        log_info "Login first, then run plugins manually:"
        log_info "  claude plugin install frontend-design@claude-plugins-official"
        return
    fi

    log_info "Installing Claude Code plugins..."

    local -a CLAUDE_PLUGINS=(
        "playwright"
        "security-guidance"
        "frontend-design"
        "code-review"
        "superpowers"
        "code-simplifier"
    )

    local plugin_fail_count=0
    for plugin_name in "${CLAUDE_PLUGINS[@]}"; do
        log_info "  Installing plugin: $plugin_name ..."
        local plugin_output
        plugin_output=$(claude plugin install "${plugin_name}@claude-plugins-official" --scope user 2>&1)
        local plugin_exit=$?
        if [ $plugin_exit -eq 0 ]; then
            log_success "  ✓ $plugin_name installed"
        else
            plugin_fail_count=$((plugin_fail_count + 1))
            log_warning "  ✗ $plugin_name failed (exit: $plugin_exit)"
            log_warning "    Output: $plugin_output"
        fi
    done

    if [ $plugin_fail_count -gt 0 ]; then
        log_warning "$plugin_fail_count plugin(s) failed. Install manually:"
        for p in "${CLAUDE_PLUGINS[@]}"; do
            log_info "  claude plugin install ${p}@claude-plugins-official"
        done
    else
        log_success "All Claude Code plugins installed successfully"
    fi
}

run_cli_logins() {
    log_step "13. CLI Login Commands"

    # Reload NVM
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    local need_login=false

    # Check Claude CLI auth status
    if command_exists claude; then
        if claude auth status &>/dev/null; then
            log_warning "Claude CLI already authenticated, skipping..."
        else
            log_info "Claude CLI needs authentication"
            need_login=true
        fi
    fi

    # Check Codex CLI auth status
    if command_exists codex; then
        if codex auth status &>/dev/null; then
            log_warning "Codex CLI already authenticated, skipping..."
        else
            log_info "Codex CLI needs authentication"
            need_login=true
        fi
    fi

    if ! $need_login; then
        log_success "All CLI tools already authenticated"
        return
    fi

    echo ""
    read -p "Do you want to login to CLI tools now? (y/n): " -n 1 -r < /dev/tty
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Claude CLI login
        if command_exists claude && ! claude auth status &>/dev/null; then
            log_info "Starting Claude CLI login..."
            claude auth login || log_warning "Claude login skipped or failed"
        fi

        # Codex CLI login
        if command_exists codex && ! codex auth status &>/dev/null; then
            log_info "Starting Codex CLI login..."
            codex auth login || log_warning "Codex login skipped or failed"
        fi

        log_success "CLI logins completed"

        # Install Claude Code plugins after successful auth
        install_claude_plugins
    else
        log_info "Skipping CLI logins. You can run them later manually:"
        echo "  - claude auth login"
        echo "  - codex auth login"
    fi
}

#===============================================================================
# 14. Firefox Removal (detects snap, deb, flatpak)
#===============================================================================
remove_firefox() {
    log_step "14. Removing Firefox"

    # Don't remove Firefox if no alternative browser was installed
    if ! $BROWSER_INSTALLED; then
        log_warning "No alternative browser installed, keeping Firefox..."
        return
    fi

    local firefox_found=false
    local firefox_snap=false
    local firefox_deb=false
    local firefox_flatpak=false

    # Detect Firefox installation type
    log_info "Detecting Firefox installation..."

    # Check snap
    if snap list firefox &>/dev/null 2>&1; then
        firefox_snap=true
        firefox_found=true
        log_info "  Found: Firefox (snap)"
    fi

    # Check deb/apt
    if dpkg -l firefox 2>/dev/null | grep -q "^ii"; then
        firefox_deb=true
        firefox_found=true
        log_info "  Found: Firefox (deb/apt)"
    fi

    # Check flatpak
    if command_exists flatpak && flatpak list 2>/dev/null | grep -qi firefox; then
        firefox_flatpak=true
        firefox_found=true
        log_info "  Found: Firefox (flatpak)"
    fi

    # Check if firefox command exists but no package found
    if ! $firefox_found && command_exists firefox; then
        firefox_found=true
        log_info "  Found: Firefox (unknown source)"
    fi

    if ! $firefox_found; then
        log_warning "Firefox not found, skipping removal..."
        return
    fi

    read -p "Do you want to remove Firefox? (y/n): " -n 1 -r < /dev/tty
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing Firefox..."

        # Remove snap version
        if $firefox_snap; then
            log_info "  Removing Firefox snap..."
            sudo snap remove --purge firefox
        fi

        # Remove deb/apt version
        if $firefox_deb; then
            log_info "  Removing Firefox deb..."
            sudo apt-get remove -y firefox
            sudo apt-get purge -y firefox
            sudo apt-get autoremove -y
        fi

        # Remove flatpak version
        if $firefox_flatpak; then
            log_info "  Removing Firefox flatpak..."
            flatpak uninstall -y org.mozilla.firefox
        fi

        # Clean up Firefox user data (optional)
        if [ -d "$HOME/.mozilla/firefox" ]; then
            read -p "Do you want to remove Firefox user data too? (y/n): " -n 1 -r < /dev/tty
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                rm -rf "$HOME/.mozilla/firefox"
                log_info "  Firefox user data removed"
            fi
        fi

        log_success "Firefox removed successfully"
    else
        log_info "Keeping Firefox installed"
    fi
}

#===============================================================================
# Prerequisites
#===============================================================================
install_prerequisites() {
    log_step "Installing Prerequisites"

    log_info "Updating package lists..."
    safe_apt_update

    log_info "Installing required packages..."
    sudo apt-get install -y \
        curl \
        wget \
        gnupg \
        ca-certificates \
        apt-transport-https \
        software-properties-common \
        build-essential \
        git || handle_error "Some prerequisite packages could not be installed"

    log_success "Prerequisites installed"
}

#===============================================================================
# Summary
#===============================================================================
print_summary() {
    log_step "Installation Summary"

    echo -e "${GREEN}Installed Components:${NC}"
    echo ""

    # RealVNC & Wayland
    (package_installed realvnc-connect || command_exists vncserver-x11) && echo -e "  ${GREEN}✓${NC} RealVNC Connect"
    grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf 2>/dev/null && echo -e "  ${GREEN}✓${NC} Wayland Disabled"

    # NVM & Node
    if [ -d "$HOME/.nvm" ]; then
        echo -e "  ${GREEN}✓${NC} NVM"
    fi

    # Reload NVM for checks
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    command_exists node && echo -e "  ${GREEN}✓${NC} Node.js $(node -v)"
    command_exists yarn && echo -e "  ${GREEN}✓${NC} Yarn $(yarn -v)"
    command_exists codex && echo -e "  ${GREEN}✓${NC} Codex CLI"
    command_exists claude && echo -e "  ${GREEN}✓${NC} Claude Code $(claude --version 2>/dev/null || echo '')"
    (command_exists google-chrome || command_exists google-chrome-stable) && echo -e "  ${GREEN}✓${NC} Google Chrome"
    (command_exists chromium-browser || command_exists chromium) && echo -e "  ${GREEN}✓${NC} Chromium"
    command_exists code && echo -e "  ${GREEN}✓${NC} VS Code"
    command_exists python3 && echo -e "  ${GREEN}✓${NC} Python $(python3 --version 2>&1 | cut -d' ' -f2)"
    package_installed gnome-shell-extensions && echo -e "  ${GREEN}✓${NC} GNOME Shell Extensions"
    package_installed gnome-shell-extension-manager && echo -e "  ${GREEN}✓${NC} GNOME Extension Manager"
    package_installed gnome-tweaks && echo -e "  ${GREEN}✓${NC} GNOME Tweaks"
    dconf list /org/gnome/shell/extensions/dash-to-dock/ &>/dev/null && echo -e "  ${GREEN}✓${NC} Dash to Dock (configured)"
    (package_installed dbeaver-ce || command_exists dbeaver) && echo -e "  ${GREEN}✓${NC} DBeaver CE"
    command_exists vlc && echo -e "  ${GREEN}✓${NC} VLC Media Player"
    command_exists cloudflared && echo -e "  ${GREEN}✓${NC} Cloudflared $(cloudflared --version 2>&1 | head -1 | cut -d' ' -f3)"
    command_exists docker && echo -e "  ${GREEN}✓${NC} Docker $(docker --version 2>&1 | cut -d' ' -f3 | tr -d ',')"
    command_exists gh && echo -e "  ${GREEN}✓${NC} GitHub CLI $(gh --version 2>/dev/null | head -1 | awk '{print $NF}')"
    (command_exists postman || snap list postman 2>/dev/null | grep -q postman) && echo -e "  ${GREEN}✓${NC} Postman"
    command_exists filezilla && echo -e "  ${GREEN}✓${NC} FileZilla"

    echo ""
    echo -e "${YELLOW}Note: You may need to restart your terminal or run:${NC}"
    echo -e "  source ~/.bashrc"
    echo ""
    echo -e "${GREEN}Setup completed!${NC}"
}

#===============================================================================
# Main
#===============================================================================
main() {
    # Handle special commands first (no root check needed)
    if $SHOW_HELP; then
        show_help
        exit 0
    fi

    if $SHOW_MENU; then
        show_full_menu
        exit 0
    fi

    if $SHOW_BACKUP_GNOME; then
        show_gnome_backup
        exit $?
    fi

    if $RESTORE_GNOME; then
        restore_gnome_settings
        exit $?
    fi

    # Check if any installation option is selected
    local has_install=false
    if $INSTALL_VNC || $INSTALL_NODEJS || $INSTALL_CHROME || \
       $INSTALL_VSCODE || $INSTALL_PYTHON || $INSTALL_GNOME || \
       $INSTALL_DBEAVER || $INSTALL_VLC || $INSTALL_CLOUDFLARED || $INSTALL_DOCKER || \
       $INSTALL_CLAUDE || $INSTALL_GH || $INSTALL_POSTMAN || $INSTALL_FILEZILLA || \
       $INSTALL_RUSTDESK || $DO_CLI_LOGIN || $DO_REMOVE_FIREFOX || $APPLY_JETSON_FIX; then
        has_install=true
    fi

    # If no options provided, show interactive menu
    if ! $has_install; then
        show_interactive_install_menu
        run_installations
        exit 0
    fi

    # Run installations with command-line flags
    run_installations
}

# Run main function
main "$@"
