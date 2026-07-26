#!/bin/bash

#===============================================================================
# Ubuntu Post-Installation Setup Script
# Version: 2.5.0 (rev-53)
# Author: enginyilmaaz
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
SCRIPT_REVISION="153"
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
INSTALL_ANYDESK=false
INSTALL_TEAMVIEWER=false
INSTALL_REMOTE=false
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
INSTALL_CODEX=false
INSTALL_KIMI=false
INSTALL_GROK=false
INSTALL_GEMINI=false
INSTALL_QWEN=false
INSTALL_GLM=false
INSTALL_OPENCODE=false
INSTALL_AICLI=false
INSTALL_JTOP=false
INSTALL_GH=false
INSTALL_POSTMAN=false
INSTALL_FILEZILLA=false
DO_CLI_LOGIN=false
DO_REMOVE_FIREFOX=false
DO_DEBLOAT=false

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
        --vnc|--realvnc)
            INSTALL_VNC=true
            ;;
        --rustdesk)
            INSTALL_RUSTDESK=true
            ;;
        --anydesk)
            INSTALL_ANYDESK=true
            ;;
        --teamviewer)
            INSTALL_TEAMVIEWER=true
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
        --codex)
            INSTALL_CODEX=true
            ;;
        --kimi|--kimi-code)
            INSTALL_KIMI=true
            ;;
        --grok)
            INSTALL_GROK=true
            ;;
        --gemini|--gemini-cli)
            INSTALL_GEMINI=true
            ;;
        --qwen|--qwen-code)
            INSTALL_QWEN=true
            ;;
        --glm|--glm-code|--zai)
            INSTALL_GLM=true
            ;;
        --glm-opencode|--opencode)
            INSTALL_OPENCODE=true
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
        --debloat)
            DO_DEBLOAT=true
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
    INSTALL_ANYDESK=true
    INSTALL_TEAMVIEWER=true
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

# Silence GNOME's update-notifier briefly so its popup doesn't open a
# browser tab mid-script. Returns a value the caller passes back to the
# matching _resume function.
_pause_update_notifier() {
    pkill -f update-notifier 2>/dev/null || true
    sudo systemctl stop update-notifier-download.timer update-notifier-motd.timer 2>/dev/null || true
}
_resume_update_notifier() {
    sudo systemctl start update-notifier-download.timer update-notifier-motd.timer 2>/dev/null || true
}

# Safe apt-get update - tolerates repo errors and asks user on failure.
# Also pauses GNOME's update-notifier so its popup doesn't open a browser tab.
safe_apt_update() {
    _pause_update_notifier
    if ! sudo apt-get update 2>&1 | tee /tmp/apt-update-output.tmp; then
        local errors
        errors=$(grep -i "err\|failed\|error" /tmp/apt-update-output.tmp 2>/dev/null || true)
        if [ -n "$errors" ]; then
            handle_error "apt-get update encountered errors:\n$errors"
        fi
    fi
    rm -f /tmp/apt-update-output.tmp
    _resume_update_notifier
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
    echo -e "  ${YELLOW}--codex / --kimi / --grok / --gemini / --qwen / --glm / --glm-opencode${NC}"
    echo "      Other AI CLI tools (interactive menu groups these under 'AI CLI Tools')"
    echo "      - Codex (OpenAI), Kimi Code (Moonshot), Grok (xAI),"
    echo "        Gemini (Google), Qwen Code (Alibaba), GLM Code (z.ai),"
    echo "        GLM With OpenCode (OpenCode + z.ai GLM-5.2)"
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

    # Wayland status
    if [ -f /etc/gdm3/custom.conf ]; then
        if grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf 2>/dev/null; then
            echo -e "  Wayland:      ${GREEN}Disabled${NC} (X11)"
        else
            echo -e "  Wayland:      ${YELLOW}Enabled${NC}"
        fi
    fi
    echo ""
}

# GNOME Tweaks sub-menu selections (global so install_gnome_extensions can read them)
GNOME_SUB_EXTENSIONS=false; GNOME_SUB_UPDATE=false; GNOME_SUB_TWEAKS_APP=false; GNOME_SUB_DOCK=false
GNOME_SUB_SCRIPT=false; GNOME_SUB_WAYLAND=false; GNOME_SUB_SSH=false
GNOME_SUB_ALIASES=false; GNOME_SUB_ENGLISH=false
GNOME_SUB_SCREEN=false; GNOME_SUB_HIDDEN=false; GNOME_SUB_KB_TR=false; GNOME_SUB_KB_EN=false
GNOME_SUB_VSCREEN=false; GNOME_SUB_AUTOLOGIN=false; GNOME_SUB_HOSTNAME=false
GNOME_SUB_NO_IBUS=false; GNOME_SUB_APPORT=false; GNOME_SUB_CHEESE=false; GNOME_SUB_CLEANUP2Y=false
# Hostname value collected before install starts (when Tweaks + Change Hostname selected)
NEW_HOSTNAME=""

# ---- Status detection helpers (shared by main menu + sub-menus) -------------
# Returns 0 if the given GNOME tweak key is currently APPLIED on the system.
# Keys that can't be reliably detected (Update System, Change Hostname,
# English Language, Dash to Dock) always return 1 (unknown / not-applied).
gnome_tweak_applied() {
    case "$1" in
        GNOME_SUB_EXTENSIONS) package_installed gnome-shell-extension-manager || package_installed gnome-shell-extensions ;;
        GNOME_SUB_TWEAKS_APP) package_installed gnome-tweaks ;;
        GNOME_SUB_SCRIPT)     [ -d "$HOME/.local/share/gnome-shell/extensions/script-launcher@enginyilmaaz" ] ;;
        GNOME_SUB_WAYLAND)    grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf 2>/dev/null ;;
        GNOME_SUB_SSH)        systemctl is-active ssh &>/dev/null ;;
        GNOME_SUB_ALIASES)    grep -q "^# BEGIN smai-aliases" "$HOME/.bashrc" 2>/dev/null ;;
        GNOME_SUB_SCREEN)     [ "$(gsettings get org.gnome.desktop.session idle-delay 2>/dev/null)" = "uint32 0" ] ;;
        GNOME_SUB_HIDDEN)     [ "$(gsettings get org.gtk.Settings.FileChooser show-hidden 2>/dev/null)" = "true" ] ;;
        GNOME_SUB_KB_TR)      gsettings get org.gnome.desktop.input-sources sources 2>/dev/null | grep -q "'tr'" ;;
        GNOME_SUB_KB_EN)      gsettings get org.gnome.desktop.input-sources sources 2>/dev/null | grep -q "'us'" ;;
        GNOME_SUB_NO_IBUS)    systemctl --user is-enabled org.freedesktop.IBus.session.GNOME 2>/dev/null | grep -q "masked" ;;
        GNOME_SUB_APPORT)     systemctl is-active apport &>/dev/null ;;
        GNOME_SUB_CHEESE)     command_exists cheese ;;
        GNOME_SUB_CLEANUP2Y)  [ "$(gsettings get org.gnome.desktop.privacy old-files-age 2>/dev/null)" = "uint32 730" ] ;;
        GNOME_SUB_VSCREEN)    virtual_screen_installed ;;
        GNOME_SUB_AUTOLOGIN)  autologin_enabled ;;
        *) return 1 ;;
    esac
}

# Returns 0 if the given Remote sub-menu key's tool is installed.
remote_installed() {
    case "$1" in
        REMOTE_SUB_VNC)        command_exists vncserver-x11 || command_exists vncserver || \
                               package_installed realvnc-rvncconnect || package_installed realvnc-connect || \
                               package_installed realvnc-vnc-server || \
                               [ -f /usr/bin/vncserver-x11 ] || [ -d /usr/share/vnc ] ;;
        REMOTE_SUB_ANYDESK)    command_exists anydesk || package_installed anydesk ;;
        REMOTE_SUB_RUSTDESK)   command_exists rustdesk ;;
        REMOTE_SUB_TEAMVIEWER) command_exists teamviewer || package_installed teamviewer ;;
        *) return 1 ;;
    esac
}

# Version the script would install for RealVNC on THIS system (arch/OS aware).
# Must mirror the URLs in install_realvnc().
realvnc_target_version() {
    if [ "$DEB_ARCH" = "amd64" ]; then
        if [ "$OS_VERSION" = "22.04" ] || [ "$OS_CODENAME" = "jammy" ]; then echo "7.13.1"; else echo "8.2.2"; fi
    elif [ "$DEB_ARCH" = "arm64" ]; then
        if [ "$OS_VERSION" = "22.04" ] || [ "$OS_CODENAME" = "jammy" ]; then echo "7.13.1"; else echo "7.17.0"; fi
    elif [ "$DEB_ARCH" = "armhf" ]; then echo "7.17.0"
    else echo ""; fi
}

# Returns 0 if an apt-managed package has a newer candidate than installed.
# Uses the local apt cache only (no network), so it reflects the last apt update.
_apt_upgradable() {
    local pkg="$1" inst cand
    inst=$(apt-cache policy "$pkg" 2>/dev/null | awk '/Installed:/{print $2}')
    cand=$(apt-cache policy "$pkg" 2>/dev/null | awk '/Candidate:/{print $2}')
    [ -n "$inst" ] && [ "$inst" != "(none)" ] && [ -n "$cand" ] && [ "$cand" != "(none)" ] && \
        dpkg --compare-versions "$inst" lt "$cand"
}

# Returns 0 if the tool is installed AND a newer version is available.
# RealVNC: compare installed deb version vs arch-aware target.
# AnyDesk/TeamViewer: apt candidate vs installed. RustDesk always installs
# GitHub-latest at run time, so we can't know offline -> never flagged.
remote_update_available() {
    case "$1" in
        REMOTE_SUB_VNC)
            local cur tgt
            cur=$(dpkg-query -W -f='${Version}' realvnc-rvncconnect 2>/dev/null)
            [ -z "$cur" ] && cur=$(dpkg-query -W -f='${Version}' realvnc-vnc-server 2>/dev/null)
            tgt=$(realvnc_target_version)
            [ -n "$cur" ] && [ -n "$tgt" ] && dpkg --compare-versions "$cur" lt "$tgt" ;;
        REMOTE_SUB_ANYDESK)    _apt_upgradable anydesk ;;
        REMOTE_SUB_TEAMVIEWER) _apt_upgradable teamviewer ;;
        *) return 1 ;;
    esac
}

# Returns 0 if the given AI CLI sub-menu key's tool is installed.
aicli_installed() {
    case "$1" in
        AICLI_SUB_CLAUDE) command_exists claude ;;
        AICLI_SUB_CODEX)  command_exists codex ;;
        AICLI_SUB_KIMI)   command_exists kimi ;;
        AICLI_SUB_GROK)   command_exists grok ;;
        AICLI_SUB_GEMINI) command_exists gemini ;;
        AICLI_SUB_QWEN)   command_exists qwen ;;
        AICLI_SUB_GLM)    command_exists chelper ;;
        AICLI_SUB_OPENCODE) command_exists opencode ;;
        *) return 1 ;;
    esac
}

# Returns 0 if a debloat item is already removed (debloated).
# Special-marker items (__...__) are contextual actions, never "done".
bloat_is_done() {
    local pkgs="$1"
    case "$pkgs" in
        __*) return 1 ;;
    esac
    local p base
    for p in $pkgs; do
        base="${p%\*}"
        if dpkg -l "$p" 2>/dev/null | grep -q "^ii" || \
           dpkg -l "${base}*" 2>/dev/null | grep -q "^ii"; then
            return 1   # at least one package still installed → not done
        fi
    done
    return 0           # none installed → already debloated
}

# Aggregate marker for the main menu group items: prints "", "some <word>" or
# "all <word>" based on how many sub-items are in the given state.
group_marker() {
    local done_n="$1" total_n="$2" word="$3"
    if [ "$done_n" -le 0 ]; then
        echo ""
    elif [ "$done_n" -ge "$total_n" ]; then
        echo "all $word"
    else
        echo "some $word"
    fi
}

# Debloat sub-menu selections (global so debloat_system can read them)
declare -a DEBLOAT_SELECTED_PKGS=()
declare -a DEBLOAT_SELECTED_NAMES=()

# AI CLI Tools sub-menu selections (global, preserved across reopens)
# Remote Support Tools sub-menu selections (global, preserved across reopens)
REMOTE_SUB_VNC=false; REMOTE_SUB_ANYDESK=false; REMOTE_SUB_RUSTDESK=false; REMOTE_SUB_TEAMVIEWER=false

# AI CLI Tools sub-menu selections (global, preserved across reopens)
AICLI_SUB_CLAUDE=false; AICLI_SUB_CODEX=false; AICLI_SUB_KIMI=false
AICLI_SUB_GROK=false; AICLI_SUB_GEMINI=false; AICLI_SUB_QWEN=false; AICLI_SUB_GLM=false
AICLI_SUB_OPENCODE=false

# Remote Support Tools sub-menu
show_remote_submenu() {
    local -a R_NAMES=() R_DESCS=() R_KEYS=()
    R_NAMES+=("RealVNC Connect"); R_DESCS+=("RealVNC Connect (commercial, free plan)"); R_KEYS+=("REMOTE_SUB_VNC")
    R_NAMES+=("AnyDesk");         R_DESCS+=("AnyDesk (fast, lightweight)");             R_KEYS+=("REMOTE_SUB_ANYDESK")
    R_NAMES+=("RustDesk");        R_DESCS+=("RustDesk (open source, self-host)");       R_KEYS+=("REMOTE_SUB_RUSTDESK")
    R_NAMES+=("TeamViewer");      R_DESCS+=("TeamViewer (commercial, free personal)");  R_KEYS+=("REMOTE_SUB_TEAMVIEWER")

    local TOTAL_R=${#R_NAMES[@]}
    local -a RSELECTED=() RINSTALLED=() RUPDATE=()
    local ri
    for ((ri=0; ri<TOTAL_R; ri++)); do
        if eval "\$${R_KEYS[$ri]}"; then RSELECTED+=(1); else RSELECTED+=(0); fi
        if remote_installed "${R_KEYS[$ri]}" 2>/dev/null; then RINSTALLED+=(1); else RINSTALLED+=(0); fi
        if remote_update_available "${R_KEYS[$ri]}" 2>/dev/null; then RUPDATE+=(1); else RUPDATE+=(0); fi
    done
    local rcursor=0
    tput civis 2>/dev/null || true

    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                 ${GREEN}Remote Support Tools - Select Options${CYAN}                     ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}     Use ↑↓ arrows to navigate, SPACE to toggle${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""

        for ((ri=0; ri<TOTAL_R; ri++)); do
            local rname="${R_NAMES[$ri]}"
            local rnum=$(printf "%2d" $((ri + 1)))
            local rcheck="[ ]" rline="   "
            [ "${RSELECTED[$ri]}" = "1" ] && rcheck="${GREEN}[✓]${NC}"
            [ "$rcursor" = "$ri" ] && rline=" ${CYAN}▶${NC}"
            local rmark=""
            if [ "${RUPDATE[$ri]}" = "1" ]; then
                rmark="  ${RED}**update available${NC}"
            elif [ "${RINSTALLED[$ri]}" = "1" ]; then
                rmark="  ${YELLOW}**installed${NC}"
            fi
            if [ "${RSELECTED[$ri]}" = "1" ]; then
                echo -e "${rline} ${BLUE}[$rnum]${NC} $rcheck ${GREEN}$rname${NC}$rmark"
            else
                echo -e "${rline} ${BLUE}[$rnum]${NC} $rcheck $rname$rmark"
            fi
        done

        echo ""
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
        local rcount=0 rsel_names=""
        for ((ri=0; ri<TOTAL_R; ri++)); do
            [ "${RSELECTED[$ri]}" = "1" ] && { rcount=$((rcount+1)); rsel_names+="${R_NAMES[$ri]}, "; }
        done
        if [ $rcount -gt 0 ]; then
            echo -e "  ${GREEN}Selected ($rcount):${NC} ${rsel_names%, }"
        else
            echo -e "  ${YELLOW}Selected: None${NC}"
        fi
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${CYAN}CONTROLS:${NC}  ${YELLOW}↑↓${NC}=Move  ${YELLOW}SPACE${NC}=Toggle  ${YELLOW}a${NC}=All  ${YELLOW}n${NC}=None  ${GREEN}c/ESC${NC}=Save+Back  ${RED}q${NC}=Discard"
        echo ""

        IFS= read -rsn1 rkey < /dev/tty 2>/dev/null || rkey=""
        if [ "$rkey" = $'\x1b' ]; then
            read -rsn2 -t 0.1 rrest < /dev/tty 2>/dev/null || rrest=""
            rkey="${rkey}${rrest}"
            if [ "$rkey" = $'\x1b' ]; then rkey='c'; fi
        fi

        case "$rkey" in
            $'\x1b[A'|'k') [ $rcursor -gt 0 ] && rcursor=$((rcursor - 1)) ;;
            $'\x1b[B'|'j') [ $rcursor -lt $((TOTAL_R - 1)) ] && rcursor=$((rcursor + 1)) ;;
            ' ')
                if [ "${RSELECTED[$rcursor]}" = "1" ]; then RSELECTED[$rcursor]=0; else RSELECTED[$rcursor]=1; fi
                ;;
            'a'|'A') for ((ri=0; ri<TOTAL_R; ri++)); do RSELECTED[$ri]=1; done ;;
            'n'|'N') for ((ri=0; ri<TOTAL_R; ri++)); do RSELECTED[$ri]=0; done ;;
            'c'|'C'|'')
                tput cnorm 2>/dev/null || true
                for ((ri=0; ri<TOTAL_R; ri++)); do
                    if [ "${RSELECTED[$ri]}" = "1" ]; then eval "${R_KEYS[$ri]}=true"; else eval "${R_KEYS[$ri]}=false"; fi
                done
                return 0
                ;;
            'q'|'Q')
                tput cnorm 2>/dev/null || true
                return 1
                ;;
        esac
    done
}

# VS Code sub-menu selections (extensions + settings tweak). Settings on by
# default to preserve the previous "auto-apply settings" behavior.
VSCODE_SUB_CLAUDE=false; VSCODE_SUB_CODEX=false; VSCODE_SUB_PYTHON=false
VSCODE_SUB_PYLANCE=false; VSCODE_SUB_GITLENS=false; VSCODE_SUB_PRETTIER=false
VSCODE_SUB_ESLINT=false; VSCODE_SUB_DOCKER=false; VSCODE_SUB_ICONS=false
VSCODE_SUB_SETTINGS=true

# Returns 0 if a VS Code extension id is installed (or, for __SETTINGS__, if
# our recommended settings.json has already been written).
vscode_ext_installed() {
    if [ "$1" = "__SETTINGS__" ]; then
        [ -f "$HOME/.config/Code/User/settings.json" ] && \
            grep -q '"editor.fontSize"' "$HOME/.config/Code/User/settings.json" 2>/dev/null
        return
    fi
    command_exists code || return 1
    code --list-extensions 2>/dev/null | grep -qix "$1"
}

# VS Code sub-menu - returns 0 on confirm (save), 1 on discard.
show_vscode_submenu() {
    local -a V_NAMES=() V_IDS=() V_KEYS=()
    V_NAMES+=("Claude Code");         V_IDS+=("anthropic.claude-code");       V_KEYS+=("VSCODE_SUB_CLAUDE")
    V_NAMES+=("Codex / ChatGPT");     V_IDS+=("openai.chatgpt");              V_KEYS+=("VSCODE_SUB_CODEX")
    V_NAMES+=("Python");              V_IDS+=("ms-python.python");            V_KEYS+=("VSCODE_SUB_PYTHON")
    V_NAMES+=("Pylance");             V_IDS+=("ms-python.vscode-pylance");    V_KEYS+=("VSCODE_SUB_PYLANCE")
    V_NAMES+=("GitLens");             V_IDS+=("eamodio.gitlens");             V_KEYS+=("VSCODE_SUB_GITLENS")
    V_NAMES+=("Prettier");            V_IDS+=("esbenp.prettier-vscode");      V_KEYS+=("VSCODE_SUB_PRETTIER")
    V_NAMES+=("ESLint");              V_IDS+=("dbaeumer.vscode-eslint");      V_KEYS+=("VSCODE_SUB_ESLINT")
    V_NAMES+=("Docker");              V_IDS+=("ms-azuretools.vscode-docker"); V_KEYS+=("VSCODE_SUB_DOCKER")
    V_NAMES+=("Material Icon Theme"); V_IDS+=("pkief.material-icon-theme");   V_KEYS+=("VSCODE_SUB_ICONS")
    V_NAMES+=("Apply Settings/Tweaks"); V_IDS+=("__SETTINGS__");             V_KEYS+=("VSCODE_SUB_SETTINGS")

    local TOTAL_V=${#V_NAMES[@]}
    local -a VSELECTED=() VINSTALLED=()
    local vi
    for ((vi=0; vi<TOTAL_V; vi++)); do
        if eval "\$${V_KEYS[$vi]}"; then VSELECTED+=(1); else VSELECTED+=(0); fi
        if vscode_ext_installed "${V_IDS[$vi]}" 2>/dev/null; then VINSTALLED+=(1); else VINSTALLED+=(0); fi
    done
    local vcursor=0
    tput civis 2>/dev/null || true

    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                 ${GREEN}VS Code - Extensions & Tweaks${CYAN}                             ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}     Use ↑↓ arrows to navigate, SPACE to toggle${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""

        for ((vi=0; vi<TOTAL_V; vi++)); do
            local vname="${V_NAMES[$vi]}"
            local vnum=$(printf "%2d" $((vi + 1)))
            local vcheck="[ ]" vline="   "
            [ "${VSELECTED[$vi]}" = "1" ] && vcheck="${GREEN}[✓]${NC}"
            [ "$vcursor" = "$vi" ] && vline=" ${CYAN}▶${NC}"
            local vmark=""
            [ "${VINSTALLED[$vi]}" = "1" ] && vmark="  ${YELLOW}**installed${NC}"
            if [ "${VSELECTED[$vi]}" = "1" ]; then
                echo -e "${vline} ${BLUE}[$vnum]${NC} $vcheck ${GREEN}$vname${NC}$vmark"
            else
                echo -e "${vline} ${BLUE}[$vnum]${NC} $vcheck $vname$vmark"
            fi
        done

        echo ""
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
        local vcount=0 vsel_names=""
        for ((vi=0; vi<TOTAL_V; vi++)); do
            [ "${VSELECTED[$vi]}" = "1" ] && { vcount=$((vcount+1)); vsel_names+="${V_NAMES[$vi]}, "; }
        done
        if [ $vcount -gt 0 ]; then
            echo -e "  ${GREEN}Selected ($vcount):${NC} ${vsel_names%, }"
        else
            echo -e "  ${YELLOW}Selected: None${NC}"
        fi
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${CYAN}CONTROLS:${NC}  ${YELLOW}↑↓${NC}=Move  ${YELLOW}SPACE${NC}=Toggle  ${YELLOW}a${NC}=All  ${YELLOW}n${NC}=None  ${GREEN}c/ESC${NC}=Save+Back  ${RED}q${NC}=Discard"
        echo ""

        IFS= read -rsn1 vkey < /dev/tty 2>/dev/null || vkey=""
        if [ "$vkey" = $'\x1b' ]; then
            read -rsn2 -t 0.1 vrest < /dev/tty 2>/dev/null || vrest=""
            vkey="${vkey}${vrest}"
            if [ "$vkey" = $'\x1b' ]; then vkey='c'; fi
        fi

        case "$vkey" in
            $'\x1b[A'|'k') [ $vcursor -gt 0 ] && vcursor=$((vcursor - 1)) ;;
            $'\x1b[B'|'j') [ $vcursor -lt $((TOTAL_V - 1)) ] && vcursor=$((vcursor + 1)) ;;
            ' ')
                if [ "${VSELECTED[$vcursor]}" = "1" ]; then VSELECTED[$vcursor]=0; else VSELECTED[$vcursor]=1; fi
                ;;
            'a'|'A') for ((vi=0; vi<TOTAL_V; vi++)); do VSELECTED[$vi]=1; done ;;
            'n'|'N') for ((vi=0; vi<TOTAL_V; vi++)); do VSELECTED[$vi]=0; done ;;
            'c'|'C'|'')
                tput cnorm 2>/dev/null || true
                for ((vi=0; vi<TOTAL_V; vi++)); do
                    if [ "${VSELECTED[$vi]}" = "1" ]; then eval "${V_KEYS[$vi]}=true"; else eval "${V_KEYS[$vi]}=false"; fi
                done
                return 0
                ;;
            'q'|'Q')
                tput cnorm 2>/dev/null || true
                return 1
                ;;
        esac
    done
}

# AI CLI Tools sub-menu - returns 0 on confirm (save), 1 on discard.
# Initializes from the global AICLI_SUB_* so reopening keeps prior picks.
show_aicli_submenu() {
    local -a AI_NAMES=()
    local -a AI_DESCS=()
    local -a AI_KEYS=()

    AI_NAMES+=("Claude Code"); AI_DESCS+=("Anthropic Claude Code CLI (native installer)"); AI_KEYS+=("AICLI_SUB_CLAUDE")
    AI_NAMES+=("Codex");       AI_DESCS+=("OpenAI Codex CLI (npm @openai/codex)");          AI_KEYS+=("AICLI_SUB_CODEX")
    AI_NAMES+=("Kimi Code");   AI_DESCS+=("Moonshot AI Kimi Code CLI (npm @moonshot-ai/kimi-code)"); AI_KEYS+=("AICLI_SUB_KIMI")
    AI_NAMES+=("Grok");        AI_DESCS+=("xAI Grok CLI (official x.ai installer)");        AI_KEYS+=("AICLI_SUB_GROK")
    AI_NAMES+=("Gemini CLI");  AI_DESCS+=("Google Gemini CLI (npm @google/gemini-cli)");    AI_KEYS+=("AICLI_SUB_GEMINI")
    AI_NAMES+=("Qwen CLI");    AI_DESCS+=("Alibaba Qwen Code CLI (npm @qwen-code/qwen-code)"); AI_KEYS+=("AICLI_SUB_QWEN")
    AI_NAMES+=("GLM Code");    AI_DESCS+=("z.ai GLM Coding helper (npm @z_ai/coding-helper → chelper)"); AI_KEYS+=("AICLI_SUB_GLM")
    AI_NAMES+=("GLM With OpenCode"); AI_DESCS+=("OpenCode agent, z.ai GLM-5.2 default (npm opencode-ai)"); AI_KEYS+=("AICLI_SUB_OPENCODE")

    local TOTAL_AI=${#AI_NAMES[@]}
    local -a ASELECTED=()
    local -a AINSTALLED=()
    local ai
    # Restore previous selections from globals (don't forget what user picked)
    for ((ai=0; ai<TOTAL_AI; ai++)); do
        if eval "\$${AI_KEYS[$ai]}"; then
            ASELECTED+=(1)
        else
            ASELECTED+=(0)
        fi
        if aicli_installed "${AI_KEYS[$ai]}" 2>/dev/null; then
            AINSTALLED+=(1)
        else
            AINSTALLED+=(0)
        fi
    done
    local acursor=0

    tput civis 2>/dev/null || true

    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    ${GREEN}AI CLI Tools - Select Options${CYAN}                          ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}     Use ↑↓ arrows to navigate, SPACE to toggle${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""

        for ((ai=0; ai<TOTAL_AI; ai++)); do
            local aname="${AI_NAMES[$ai]}"
            local adesc="${AI_DESCS[$ai]}"
            local anum=$(printf "%2d" $((ai + 1)))
            local acheck="[ ]"
            local aline="   "

            if [ "${ASELECTED[$ai]}" = "1" ]; then
                acheck="${GREEN}[✓]${NC}"
            fi
            if [ "$acursor" = "$ai" ]; then
                aline=" ${CYAN}▶${NC}"
            fi
            local amark=""
            [ "${AINSTALLED[$ai]}" = "1" ] && amark="  ${YELLOW}**installed${NC}"
            if [ "${ASELECTED[$ai]}" = "1" ]; then
                echo -e "${aline} ${BLUE}[$anum]${NC} $acheck ${GREEN}$aname${NC} - $adesc$amark"
            else
                echo -e "${aline} ${BLUE}[$anum]${NC} $acheck $aname - $adesc$amark"
            fi
        done

        echo ""
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"

        local acount=0
        local asel_names=""
        for ((ai=0; ai<TOTAL_AI; ai++)); do
            if [ "${ASELECTED[$ai]}" = "1" ]; then
                acount=$((acount + 1))
                asel_names="${asel_names}${AI_NAMES[$ai]}, "
            fi
        done

        if [ $acount -gt 0 ]; then
            asel_names="${asel_names%, }"
            echo -e "  ${GREEN}Selected ($acount):${NC} $asel_names"
        else
            echo -e "  ${YELLOW}Selected: None${NC}"
        fi

        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${CYAN}CONTROLS:${NC}  ${YELLOW}↑↓${NC}=Move  ${YELLOW}SPACE${NC}=Toggle  ${YELLOW}a${NC}=All  ${YELLOW}n${NC}=None  ${GREEN}c/ESC${NC}=Save+Back  ${RED}q${NC}=Discard"
        echo ""

        IFS= read -rsn1 akey < /dev/tty 2>/dev/null || akey=""
        if [ "$akey" = $'\x1b' ]; then
            read -rsn2 -t 0.1 arest < /dev/tty 2>/dev/null || arest=""
            akey="${akey}${arest}"
            if [ "$akey" = $'\x1b' ]; then
                # Lone ESC: save selections (act like 'c') and return
                akey='c'
            fi
        fi

        case "$akey" in
            $'\x1b[A'|'k')
                if [ $acursor -gt 0 ]; then acursor=$((acursor - 1)); fi
                ;;
            $'\x1b[B'|'j')
                if [ $acursor -lt $((TOTAL_AI - 1)) ]; then acursor=$((acursor + 1)); fi
                ;;
            ' ')
                if [ "${ASELECTED[$acursor]}" = "1" ]; then
                    ASELECTED[$acursor]=0
                else
                    ASELECTED[$acursor]=1
                fi
                ;;
            'a'|'A')
                for ((ai=0; ai<TOTAL_AI; ai++)); do ASELECTED[$ai]=1; done
                ;;
            'n'|'N')
                for ((ai=0; ai<TOTAL_AI; ai++)); do ASELECTED[$ai]=0; done
                ;;
            'c'|'C'|'')
                tput cnorm 2>/dev/null || true
                for ((ai=0; ai<TOTAL_AI; ai++)); do
                    if [ "${ASELECTED[$ai]}" = "1" ]; then
                        eval "${AI_KEYS[$ai]}=true"
                    else
                        eval "${AI_KEYS[$ai]}=false"
                    fi
                done
                return 0
                ;;
            'q'|'Q')
                tput cnorm 2>/dev/null || true
                return 1
                ;;
            [1-9])
                local anum_key=$((akey - 1))
                if [ $anum_key -lt $TOTAL_AI ]; then
                    if [ "${ASELECTED[$anum_key]}" = "1" ]; then
                        ASELECTED[$anum_key]=0
                    else
                        ASELECTED[$anum_key]=1
                    fi
                    acursor=$anum_key
                fi
                ;;
        esac
    done
}

# GNOME Tweaks sub-menu - returns 0 on confirm, 1 on cancel
show_gnome_submenu() {
    local -a TWEAK_NAMES=()
    local -a TWEAK_DESCS=()
    local -a TWEAK_KEYS=()

    TWEAK_NAMES+=("Extensions");        TWEAK_DESCS+=("Extension Manager + Shell Extensions + AppIndicator");  TWEAK_KEYS+=("GNOME_SUB_EXTENSIONS")
    TWEAK_NAMES+=("Update System");     TWEAK_DESCS+=("sudo apt update && sudo apt upgrade -y");               TWEAK_KEYS+=("GNOME_SUB_UPDATE")
    TWEAK_NAMES+=("GNOME Tweaks");      TWEAK_DESCS+=("GNOME Tweaks App + Browser Connector");                 TWEAK_KEYS+=("GNOME_SUB_TWEAKS_APP")
    TWEAK_NAMES+=("Dash to Dock");      TWEAK_DESCS+=("Dock settings, single workspace, performance mode");    TWEAK_KEYS+=("GNOME_SUB_DOCK")
    TWEAK_NAMES+=("Script Launcher");   TWEAK_DESCS+=("Right-click context menu (Claude, Codex, VS Code)");    TWEAK_KEYS+=("GNOME_SUB_SCRIPT")
    TWEAK_NAMES+=("Disable Wayland");   TWEAK_DESCS+=("Switch to X11 (VNC/RDP compatibility)");                TWEAK_KEYS+=("GNOME_SUB_WAYLAND")
    TWEAK_NAMES+=("OpenSSH Server");    TWEAK_DESCS+=("Install + auto-start SSH server (port 22)");            TWEAK_KEYS+=("GNOME_SUB_SSH")
    TWEAK_NAMES+=("Change Hostname");   TWEAK_DESCS+=("Set computer's hostname (asked before install starts)"); TWEAK_KEYS+=("GNOME_SUB_HOSTNAME")
    TWEAK_NAMES+=("CLI Aliases");       TWEAK_DESCS+=("Bash aliases (claude-skip, codex-skip, etc.)");         TWEAK_KEYS+=("GNOME_SUB_ALIASES")
    TWEAK_NAMES+=("English Language");  TWEAK_DESCS+=("Set system language to English (US)");                   TWEAK_KEYS+=("GNOME_SUB_ENGLISH")
    TWEAK_NAMES+=("Screen Off: Never"); TWEAK_DESCS+=("Disable screen timeout + auto suspend");                TWEAK_KEYS+=("GNOME_SUB_SCREEN")
    TWEAK_NAMES+=("Show Hidden Files"); TWEAK_DESCS+=("Show hidden files in file manager");                    TWEAK_KEYS+=("GNOME_SUB_HIDDEN")
    TWEAK_NAMES+=("Keyboard: Turkish Q"); TWEAK_DESCS+=("Add Turkish Q keyboard layout");                      TWEAK_KEYS+=("GNOME_SUB_KB_TR")
    TWEAK_NAMES+=("Keyboard: English Q"); TWEAK_DESCS+=("Add English (US) keyboard layout");                   TWEAK_KEYS+=("GNOME_SUB_KB_EN")
    TWEAK_NAMES+=("IBus Leak Fix");      TWEAK_DESCS+=("Disable ibus-daemon, use XKB only (fix memory leak)");   TWEAK_KEYS+=("GNOME_SUB_NO_IBUS")
    TWEAK_NAMES+=("Activate Apport");    TWEAK_DESCS+=("Install + enable Ubuntu crash reporting (apport)");      TWEAK_KEYS+=("GNOME_SUB_APPORT")
    # Camera (cheese) - only listed if NOT already installed
    if ! dpkg -l cheese 2>/dev/null | grep -q "^ii"; then
        TWEAK_NAMES+=("Install Camera (Cheese)"); TWEAK_DESCS+=("Install cheese webcam app");                       TWEAK_KEYS+=("GNOME_SUB_CHEESE")
    fi
    # Note: "Restore Desktop Meta" tweak removed by user request. If anyone
    # really needs it: sudo apt install --no-install-recommends ubuntu-desktop
    TWEAK_NAMES+=("Virtual Screen 1080p"); TWEAK_DESCS+=("Create virtual 1920x1080 display (for VNC/RDP/headless)"); TWEAK_KEYS+=("GNOME_SUB_VSCREEN")
    TWEAK_NAMES+=("Cleanup Period: 2Y");   TWEAK_DESCS+=("Auto-cleanup 730 days (2Y); Tweaks default is 365 days/1Y"); TWEAK_KEYS+=("GNOME_SUB_CLEANUP2Y")
    TWEAK_NAMES+=("GDM Auto-Login");       TWEAK_DESCS+=("Auto-login to GUI on boot (needed for VNC tray icon)");   TWEAK_KEYS+=("GNOME_SUB_AUTOLOGIN")

    local TOTAL_TWEAKS=${#TWEAK_NAMES[@]}
    local -a TSELECTED=()
    local -a TAPPLIED=()
    for ((ti=0; ti<TOTAL_TWEAKS; ti++)); do
        TSELECTED+=(0)
        if gnome_tweak_applied "${TWEAK_KEYS[$ti]}" 2>/dev/null; then
            TAPPLIED+=(1)
        else
            TAPPLIED+=(0)
        fi
    done
    local tcursor=0

    tput civis 2>/dev/null || true

    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    ${GREEN}GNOME Tweaks - Select Options${CYAN}                          ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}     Use ↑↓ arrows to navigate, SPACE to toggle${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""

        local ti
        for ((ti=0; ti<TOTAL_TWEAKS; ti++)); do
            local tname="${TWEAK_NAMES[$ti]}"
            local tdesc="${TWEAK_DESCS[$ti]}"
            local tnum=$(printf "%2d" $((ti + 1)))
            local tcheck="[ ]"
            local tline="   "

            if [ "${TSELECTED[$ti]}" = "1" ]; then
                tcheck="${GREEN}[✓]${NC}"
            fi
            if [ "$tcursor" = "$ti" ]; then
                tline=" ${CYAN}▶${NC}"
            fi
            local tmark=""
            [ "${TAPPLIED[$ti]}" = "1" ] && tmark="  ${YELLOW}**applied${NC}"
            if [ "${TSELECTED[$ti]}" = "1" ]; then
                echo -e "${tline} ${BLUE}[$tnum]${NC} $tcheck ${GREEN}$tname${NC} - $tdesc$tmark"
            else
                echo -e "${tline} ${BLUE}[$tnum]${NC} $tcheck $tname - $tdesc$tmark"
            fi
        done

        echo ""
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"

        local tcount=0
        local tsel_names=""
        for ((ti=0; ti<TOTAL_TWEAKS; ti++)); do
            if [ "${TSELECTED[$ti]}" = "1" ]; then
                tcount=$((tcount + 1))
                tsel_names="${tsel_names}${TWEAK_NAMES[$ti]}, "
            fi
        done

        if [ $tcount -gt 0 ]; then
            tsel_names="${tsel_names%, }"
            echo -e "  ${GREEN}Selected ($tcount):${NC} $tsel_names"
        else
            echo -e "  ${YELLOW}Selected: None${NC}"
        fi

        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${CYAN}CONTROLS:${NC}  ${YELLOW}↑↓${NC}=Move  ${YELLOW}SPACE${NC}=Toggle  ${YELLOW}a${NC}=All  ${YELLOW}n${NC}=None  ${GREEN}c/ESC${NC}=Save+Back  ${RED}q${NC}=Discard"
        echo ""

        IFS= read -rsn1 tkey < /dev/tty 2>/dev/null || tkey=""
        if [ "$tkey" = $'\x1b' ]; then
            read -rsn2 -t 0.1 trest < /dev/tty 2>/dev/null || trest=""
            tkey="${tkey}${trest}"
            if [ "$tkey" = $'\x1b' ]; then
                # Lone ESC: save current selections (act like 'c') and return.
                # Users press ESC expecting "go back without losing data".
                tkey='c'
            fi
        fi

        case "$tkey" in
            $'\x1b[A'|'k')
                if [ $tcursor -gt 0 ]; then tcursor=$((tcursor - 1)); fi
                ;;
            $'\x1b[B'|'j')
                if [ $tcursor -lt $((TOTAL_TWEAKS - 1)) ]; then tcursor=$((tcursor + 1)); fi
                ;;
            ' ')
                if [ "${TSELECTED[$tcursor]}" = "1" ]; then
                    TSELECTED[$tcursor]=0
                else
                    TSELECTED[$tcursor]=1
                fi
                ;;
            'a'|'A')
                for ((ti=0; ti<TOTAL_TWEAKS; ti++)); do TSELECTED[$ti]=1; done
                ;;
            'n'|'N')
                for ((ti=0; ti<TOTAL_TWEAKS; ti++)); do TSELECTED[$ti]=0; done
                ;;
            'c'|'C'|'')
                tput cnorm 2>/dev/null || true
                for ((ti=0; ti<TOTAL_TWEAKS; ti++)); do
                    if [ "${TSELECTED[$ti]}" = "1" ]; then
                        eval "${TWEAK_KEYS[$ti]}=true"
                    else
                        eval "${TWEAK_KEYS[$ti]}=false"
                    fi
                done
                # If hostname change selected, ask for the new name now
                if $GNOME_SUB_HOSTNAME; then
                    echo ""
                    echo -e "${CYAN}Change Hostname selected.${NC}"
                    echo -e "Current hostname: ${YELLOW}$(hostname)${NC}"
                    read -p "Enter new hostname (or press Enter to skip): " NEW_HOSTNAME < /dev/tty
                    if [ -z "$NEW_HOSTNAME" ]; then
                        GNOME_SUB_HOSTNAME=false
                        echo "Hostname change skipped."
                    fi
                fi
                return 0
                ;;
            'q'|'Q')
                tput cnorm 2>/dev/null || true
                return 1
                ;;
            [1-9])
                local tnum_key=$((tkey - 1))
                if [ $tnum_key -lt $TOTAL_TWEAKS ]; then
                    if [ "${TSELECTED[$tnum_key]}" = "1" ]; then
                        TSELECTED[$tnum_key]=0
                    else
                        TSELECTED[$tnum_key]=1
                    fi
                    tcursor=$tnum_key
                fi
                ;;
        esac
    done
}

# Debloat sub-menu - returns 0 on confirm, 1 on cancel
show_debloat_submenu() {
    local -a BLOAT_NAMES=()
    local -a BLOAT_DESCS=()
    local -a BLOAT_PKGS=()

    if dpkg -l libreoffice-common 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("LibreOffice");       BLOAT_DESCS+=("Office Suite (Writer, Calc, Impress, etc.)"); BLOAT_PKGS+=("libreoffice-*")
    fi
    if dpkg -l gnome-mahjongg 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Mahjongg");          BLOAT_DESCS+=("GNOME Mahjongg Game");                       BLOAT_PKGS+=("gnome-mahjongg")
    fi
    if dpkg -l aisleriot 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Solitaire");         BLOAT_DESCS+=("AisleRiot Solitaire");                       BLOAT_PKGS+=("aisleriot")
    fi
    if dpkg -l gnome-mines 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Mines");             BLOAT_DESCS+=("GNOME Mines Game");                          BLOAT_PKGS+=("gnome-mines")
    fi
    if dpkg -l gnome-sudoku 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Sudoku");            BLOAT_DESCS+=("GNOME Sudoku Game");                         BLOAT_PKGS+=("gnome-sudoku")
    fi
    if dpkg -l xterm 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("XTerm");             BLOAT_DESCS+=("Legacy X Terminal Emulator");                BLOAT_PKGS+=("xterm")
    fi
    if dpkg -l thunderbird 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Thunderbird");       BLOAT_DESCS+=("Mozilla Thunderbird Email Client");          BLOAT_PKGS+=("thunderbird thunderbird-*")
    fi
    if dpkg -l remmina 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Remmina");           BLOAT_DESCS+=("Remmina Remote Desktop Client");             BLOAT_PKGS+=("remmina remmina-*")
    fi
    if dpkg -l gnome-todo 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("GNOME To Do");       BLOAT_DESCS+=("GNOME To Do App");                           BLOAT_PKGS+=("gnome-todo")
    fi
    if dpkg -l transmission-gtk 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Transmission");      BLOAT_DESCS+=("Transmission BitTorrent Client");            BLOAT_PKGS+=("transmission-gtk transmission-common")
    fi
    if dpkg -l shotwell 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Shotwell");          BLOAT_DESCS+=("Shotwell Photo Manager");                    BLOAT_PKGS+=("shotwell shotwell-common")
    fi
    if dpkg -l simple-scan 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Document Scanner");  BLOAT_DESCS+=("Simple Scan Document Scanner");              BLOAT_PKGS+=("simple-scan")
    fi
    if dpkg -l gnome-font-viewer 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Fonts");             BLOAT_DESCS+=("GNOME Font Viewer");                         BLOAT_PKGS+=("gnome-font-viewer")
    fi
    if dpkg -l gucharmap 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Characters");        BLOAT_DESCS+=("Character Map (gucharmap)");                 BLOAT_PKGS+=("gucharmap")
    fi
    if dpkg -l gnome-characters 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("GNOME Characters");  BLOAT_DESCS+=("GNOME Characters App");                      BLOAT_PKGS+=("gnome-characters")
    fi
    if dpkg -l gnome-calendar 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Calendar");          BLOAT_DESCS+=("GNOME Calendar");                            BLOAT_PKGS+=("gnome-calendar")
    fi
    # Calculator (GNOME Calculator)
    if dpkg -l gnome-calculator 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Calculator");        BLOAT_DESCS+=("Remove GNOME Calculator");                  BLOAT_PKGS+=("gnome-calculator")
    fi
    # Printer stack (CUPS + HPLIP + all printer drivers + system-config-printer)
    if dpkg -l cups 2>/dev/null | grep -q "^ii" || dpkg -l hplip 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Printer Stack");     BLOAT_DESCS+=("Remove CUPS + HPLIP + all printer drivers (saves ~200MB)"); BLOAT_PKGS+=("cups cups-bsd cups-client cups-common cups-daemon cups-server-common cups-core-drivers cups-filters cups-filters-core-drivers cups-browsed cups-pk-helper cups-ipp-utils cups-ppdc bluez-cups system-config-printer hplip hplip-data printer-driver-brlaser printer-driver-c2esp printer-driver-foo2zjs printer-driver-m2300w printer-driver-min12xxw printer-driver-pxljr printer-driver-ptouch printer-driver-sag-gdi printer-driver-splix printer-driver-postscript-hp printer-driver-hpcups")
    fi
    # Vim (preinstalled / vim-common)
    if dpkg -l vim 2>/dev/null | grep -q "^ii" || dpkg -l vim-tiny 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Vim");               BLOAT_DESCS+=("Remove vim/vim-tiny editor");                BLOAT_PKGS+=("vim vim-tiny vim-common vim-runtime")
    fi
    # Rhythmbox music player
    if dpkg -l rhythmbox 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Rhythmbox");         BLOAT_DESCS+=("Remove Rhythmbox music player");              BLOAT_PKGS+=("rhythmbox rhythmbox-data rhythmbox-plugins")
    fi
    # Ubuntu Videos (Totem)
    if dpkg -l totem 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Ubuntu Videos");     BLOAT_DESCS+=("Remove Totem video player (GNOME Videos)");   BLOAT_PKGS+=("totem totem-common totem-plugins")
    fi
    # Cheese (camera app) - force-remove because gnome-control-center depends
    # transitively on libcheese-gtk25 → libcheese8 → cheese
    if dpkg -l cheese 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Camera (Cheese)");   BLOAT_DESCS+=("Remove Cheese webcam app (force, keeps Settings)"); BLOAT_PKGS+=("__FORCE__:cheese")
    fi
    # === GNOME tweak rollbacks / removals ===
    # Dash to Dock - restore from backup (only if backup file exists)
    if [ -f "$BACKUP_DIR/gnome-backup/dash-to-dock.dconf" ]; then
        BLOAT_NAMES+=("Restore Dash to Dock"); BLOAT_DESCS+=("Roll back Dash to Dock settings from backup"); BLOAT_PKGS+=("__DTD_RESTORE__")
    fi
    # Script Launcher GNOME extension (only if installed)
    if [ -d "$HOME/.local/share/gnome-shell/extensions/script-launcher@enginyilmaaz" ]; then
        BLOAT_NAMES+=("Script Launcher");      BLOAT_DESCS+=("Remove Script Launcher GNOME extension");     BLOAT_PKGS+=("__SCRIPT_LAUNCHER__")
    fi
    # Extensions stack (Tweaks → Extensions: Extension Manager + Shell Extensions + AppIndicator + Tray Icons)
    if package_installed gnome-shell-extension-manager || package_installed gnome-shell-extensions; then
        BLOAT_NAMES+=("Extensions Stack");     BLOAT_DESCS+=("Remove Extension Manager + Shell Extensions + AppIndicator + Tray Icons"); BLOAT_PKGS+=("__EXTENSIONS_STACK__")
    fi
    # === Language packs (dynamic — list each installed lang pack so user can pick) ===
    local _lang_pkg _lang_code _lang_name
    while read -r _lang_pkg; do
        # Extract code like 'en' from 'language-pack-en'
        _lang_code="${_lang_pkg#language-pack-}"
        case "$_lang_code" in
            en) _lang_name="English" ;;
            tr) _lang_name="Turkish" ;;
            de) _lang_name="German" ;;
            fr) _lang_name="French" ;;
            es) _lang_name="Spanish" ;;
            it) _lang_name="Italian" ;;
            ru) _lang_name="Russian" ;;
            zh-hans) _lang_name="Chinese (Simplified)" ;;
            zh-hant) _lang_name="Chinese (Traditional)" ;;
            ja) _lang_name="Japanese" ;;
            ko) _lang_name="Korean" ;;
            ar) _lang_name="Arabic" ;;
            *)  _lang_name="$_lang_code" ;;
        esac
        # Skip Turkish (user's primary, never remove)
        [ "$_lang_code" = "tr" ] && continue
        BLOAT_NAMES+=("Lang: $_lang_name"); BLOAT_DESCS+=("Remove $_lang_name language packs (4 packages)"); BLOAT_PKGS+=("language-pack-$_lang_code language-pack-$_lang_code-base language-pack-gnome-$_lang_code language-pack-gnome-$_lang_code-base")
    done < <(dpkg -l 'language-pack-*' 2>/dev/null | awk '/^ii / && $2 !~ /^language-pack-gnome/ && $2 !~ /-base$/ {print $2}')
    # XKB layout removal (extra keyboard layouts the user no longer wants)
    local _xkb_sources
    _xkb_sources=$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null)
    # Iterate over each xkb code in the list, offer to drop any non-tr layout
    if [[ "$_xkb_sources" =~ \( ]]; then
        local _xkb_code
        for _xkb_code in $(echo "$_xkb_sources" | grep -oP "'xkb', '[^']+'" | grep -oP "'[a-zA-Z0-9_+-]+'" | grep -v "'xkb'" | tr -d "'"); do
            # Only suggest removing 'us' (English) here, since the user explicitly
            # asked about English. Skip 'tr'.
            [ "$_xkb_code" = "tr" ] && continue
            local _xkb_label
            case "$_xkb_code" in
                us) _xkb_label="English (US)" ;;
                gb) _xkb_label="English (UK)" ;;
                de) _xkb_label="German" ;;
                fr) _xkb_label="French" ;;
                es) _xkb_label="Spanish" ;;
                *)  _xkb_label="$_xkb_code" ;;
            esac
            BLOAT_NAMES+=("Keyboard: $_xkb_label"); BLOAT_DESCS+=("Drop '$_xkb_code' XKB layout from GNOME (keeps tr)"); BLOAT_PKGS+=("__XKB_DROP__:$_xkb_code")
        done
    fi
    # NOTE: Ubuntu Help (yelp/gnome-user-docs) removed from Debloat by user
    # request — it cascaded to ubuntu-desktop meta and was confusing. Manual:
    #   sudo apt remove yelp gnome-user-docs
    # NOTE: Language Support (language-selector-gnome) is intentionally NOT in
    # this menu — it has a hard rev-dep from gnome-control-center, so removing
    # it KILLS the Settings app. If you really want it gone, do it manually:
    #   sudo dpkg --force-depends --remove language-selector-gnome
    # Power Statistics
    if dpkg -l gnome-power-manager 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Power Statistics");  BLOAT_DESCS+=("Remove GNOME Power Statistics app");         BLOAT_PKGS+=("gnome-power-manager")
    fi
    # Virtual Screen config (not a package, special marker)
    if virtual_screen_installed; then
        BLOAT_NAMES+=("Virtual Screen 1080p"); BLOAT_DESCS+=("Remove virtual 1920x1080 display config");  BLOAT_PKGS+=("__VSCREEN__")
    fi
    # GDM Auto-Login (not a package, special marker)
    if autologin_enabled; then
        BLOAT_NAMES+=("GDM Auto-Login");       BLOAT_DESCS+=("Disable GDM auto-login (require login screen)"); BLOAT_PKGS+=("__AUTOLOGIN__")
    fi
    # === Tools the script installs (only listed if currently installed) ===
    # Claude Code CLI (native install)
    if command_exists claude || [ -d "$HOME/.claude" ]; then
        BLOAT_NAMES+=("Claude Code CLI");      BLOAT_DESCS+=("Remove Claude Code CLI + ~/.claude directory");   BLOAT_PKGS+=("__CLAUDE__")
    fi
    # Codex CLI (npm install)
    if command_exists codex; then
        BLOAT_NAMES+=("Codex CLI");            BLOAT_DESCS+=("Remove Codex CLI (npm uninstall @openai/codex)"); BLOAT_PKGS+=("__CODEX__")
    fi
    # VS Code
    if dpkg -l code 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("VS Code");              BLOAT_DESCS+=("Remove Visual Studio Code");                      BLOAT_PKGS+=("code")
    fi
    # xrdp RDP Server
    if dpkg -l xrdp 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("RDP Server (xrdp)");    BLOAT_DESCS+=("Remove xrdp (port 3389 RDP server)");          BLOAT_PKGS+=("__XRDP__")
    fi
    # === Other apps the script installs (only listed if currently installed) ===
    # RealVNC
    if dpkg -l realvnc-vnc-server 2>/dev/null | grep -q "^ii" || dpkg -l realvnc-rvncconnect 2>/dev/null | grep -q "^ii" || command_exists vncserver-x11; then
        BLOAT_NAMES+=("RealVNC");              BLOAT_DESCS+=("Remove RealVNC Connect (Remote Desktop)");        BLOAT_PKGS+=("__REALVNC__")
    fi
    # AnyDesk
    if dpkg -l anydesk 2>/dev/null | grep -q "^ii" || command_exists anydesk; then
        BLOAT_NAMES+=("AnyDesk");              BLOAT_DESCS+=("Remove AnyDesk (Remote Desktop)");                BLOAT_PKGS+=("anydesk")
    fi
    # RustDesk
    if dpkg -l rustdesk 2>/dev/null | grep -q "^ii" || command_exists rustdesk; then
        BLOAT_NAMES+=("RustDesk");             BLOAT_DESCS+=("Remove RustDesk (Open Source Remote Desktop)");   BLOAT_PKGS+=("rustdesk")
    fi
    # TeamViewer
    if dpkg -l teamviewer 2>/dev/null | grep -q "^ii" || command_exists teamviewer; then
        BLOAT_NAMES+=("TeamViewer");           BLOAT_DESCS+=("Remove TeamViewer");                              BLOAT_PKGS+=("teamviewer")
    fi
    # NodeJS (NVM)
    if [ -d "$HOME/.nvm" ] || command_exists node; then
        BLOAT_NAMES+=("Node.js (NVM)");        BLOAT_DESCS+=("Remove NVM + Node.js (rm -rf ~/.nvm)");           BLOAT_PKGS+=("__NVM__")
    fi
    # Google Chrome
    if dpkg -l google-chrome-stable 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Google Chrome");        BLOAT_DESCS+=("Remove Google Chrome browser");                   BLOAT_PKGS+=("google-chrome-stable")
    fi
    # Chromium
    if dpkg -l chromium 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Chromium");             BLOAT_DESCS+=("Remove Chromium browser");                        BLOAT_PKGS+=("chromium")
    fi
    if snap list chromium &>/dev/null; then
        BLOAT_NAMES+=("Chromium (snap)");      BLOAT_DESCS+=("Remove Chromium snap");                           BLOAT_PKGS+=("__CHROMIUM_SNAP__")
    fi
    # Python
    if dpkg -l python3-pip 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Python 3 pip");         BLOAT_DESCS+=("Remove python3-pip + python3-venv");              BLOAT_PKGS+=("python3-pip python3-venv")
    fi
    # DBeaver
    if dpkg -l dbeaver-ce 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("DBeaver CE");           BLOAT_DESCS+=("Remove DBeaver CE (database tool)");              BLOAT_PKGS+=("dbeaver-ce")
    fi
    # VLC
    if dpkg -l vlc 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("VLC");                  BLOAT_DESCS+=("Remove VLC media player");                        BLOAT_PKGS+=("vlc")
    fi
    # Cloudflared
    if dpkg -l cloudflared 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Cloudflared");          BLOAT_DESCS+=("Remove Cloudflare Tunnel client");                BLOAT_PKGS+=("cloudflared")
    fi
    # Docker
    if dpkg -l docker-ce 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Docker Engine");        BLOAT_DESCS+=("Remove Docker Engine + Compose plugin");          BLOAT_PKGS+=("docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin")
    fi
    # GitHub CLI
    if dpkg -l gh 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("GitHub CLI (gh)");      BLOAT_DESCS+=("Remove GitHub CLI (gh)");                         BLOAT_PKGS+=("gh")
    fi
    # Postman (snap)
    if snap list postman &>/dev/null; then
        BLOAT_NAMES+=("Postman");              BLOAT_DESCS+=("Remove Postman (snap remove)");                   BLOAT_PKGS+=("__POSTMAN_SNAP__")
    fi
    # FileZilla
    if dpkg -l filezilla 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("FileZilla");            BLOAT_DESCS+=("Remove FileZilla (FTP/SFTP client)");             BLOAT_PKGS+=("filezilla")
    fi
    # Firefox (APT deb, including xtradeb PPA version)
    if dpkg -l firefox 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Firefox");              BLOAT_DESCS+=("Remove Firefox APT (deb / xtradeb PPA)");           BLOAT_PKGS+=("firefox")
    fi
    # jtop (Jetson stats) - pip installed
    if command_exists jtop; then
        BLOAT_NAMES+=("jtop");                 BLOAT_DESCS+=("Remove jtop / jetson-stats (pip uninstall)");      BLOAT_PKGS+=("__JTOP__")
    fi
    # Apport - Ubuntu crash reporter (also pops up annoying dialogs)
    if dpkg -l apport 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Apport");               BLOAT_DESCS+=("Remove Apport crash reporter (re-enable from Tweaks)"); BLOAT_PKGS+=("__APPORT__")
    fi
    if dpkg -l firefox-esr 2>/dev/null | grep -q "^ii"; then
        BLOAT_NAMES+=("Firefox ESR");          BLOAT_DESCS+=("Remove Firefox ESR APT");                          BLOAT_PKGS+=("firefox-esr")
    fi

    # === Snap packages (auto-detected, system snaps filtered out) ===
    if command_exists snap; then
        # Skip these system / base snaps even if installed
        local _skip_re='^(core|core18|core20|core22|core24|snapd|bare|gtk-common-themes|gnome-3-[0-9]+-[0-9]+|gnome-42-2204|kf5-5-[0-9]+-qt-5-[0-9]+-core[0-9]+|qt-common|firefox-base|snapd-desktop-integration|chromium|postman)$'
        local _snap_name
        while read -r _snap_name _; do
            [ -z "$_snap_name" ] && continue
            [ "$_snap_name" = "Name" ] && continue
            if [[ ! "$_snap_name" =~ $_skip_re ]]; then
                BLOAT_NAMES+=("Snap: $_snap_name"); BLOAT_DESCS+=("Remove snap package '$_snap_name'"); BLOAT_PKGS+=("__SNAP__:$_snap_name")
            fi
        done < <(snap list 2>/dev/null | tail -n +2)

        # Full snap stack removal (only offered if snapd is installed)
        if dpkg -l snapd 2>/dev/null | grep -q "^ii"; then
            BLOAT_NAMES+=("Remove Snap Completely"); BLOAT_DESCS+=("Remove ALL snaps + snapd + /snap dirs (frees ~300MB, irreversible-ish)"); BLOAT_PKGS+=("__SNAP_PURGE_ALL__")
        fi
    fi
    # NOTE: OpenSSH Server is NOT listed here on purpose — removing it could
    # cut remote access for the user. Use 'sudo apt purge openssh-server' manually
    # only if you have physical/console access.

    # === Already-debloated known apps ===
    # List well-known apps that are NOT installed so the user can SEE what's
    # already gone (shown with **debloated). Only added when not installed, so
    # there's no overlap with the removable items listed above.
    # Format: name|desc|pkgs|detect-pkg
    local -a _gone_apps=(
        "LibreOffice|Office Suite (Writer, Calc, Impress, etc.)|libreoffice-*|libreoffice-common"
        "Mahjongg|GNOME Mahjongg Game|gnome-mahjongg|gnome-mahjongg"
        "Solitaire|AisleRiot Solitaire|aisleriot|aisleriot"
        "Mines|GNOME Mines Game|gnome-mines|gnome-mines"
        "Sudoku|GNOME Sudoku Game|gnome-sudoku|gnome-sudoku"
        "XTerm|Legacy X Terminal Emulator|xterm|xterm"
        "Thunderbird|Mozilla Thunderbird Email Client|thunderbird thunderbird-*|thunderbird"
        "Remmina|Remmina Remote Desktop Client|remmina remmina-*|remmina"
        "GNOME To Do|GNOME To Do App|gnome-todo|gnome-todo"
        "Transmission|Transmission BitTorrent Client|transmission-gtk transmission-common|transmission-gtk"
        "Shotwell|Shotwell Photo Manager|shotwell shotwell-common|shotwell"
        "Document Scanner|Simple Scan Document Scanner|simple-scan|simple-scan"
        "Fonts|GNOME Font Viewer|gnome-font-viewer|gnome-font-viewer"
        "Characters|Character Map (gucharmap)|gucharmap|gucharmap"
        "GNOME Characters|GNOME Characters App|gnome-characters|gnome-characters"
        "Calendar|GNOME Calendar|gnome-calendar|gnome-calendar"
        "Calculator|GNOME Calculator|gnome-calculator|gnome-calculator"
        "Vim|vim/vim-tiny editor|vim vim-tiny vim-common vim-runtime|vim"
        "Rhythmbox|Rhythmbox music player|rhythmbox rhythmbox-data rhythmbox-plugins|rhythmbox"
        "Ubuntu Videos|Totem video player (GNOME Videos)|totem totem-common totem-plugins|totem"
        "Power Statistics|GNOME Power Statistics app|gnome-power-manager|gnome-power-manager"
        "VS Code|Visual Studio Code|code|code"
        "RustDesk|RustDesk (Open Source Remote Desktop)|rustdesk|rustdesk"
        "AnyDesk|AnyDesk (Remote Desktop)|anydesk|anydesk"
        "TeamViewer|TeamViewer|teamviewer|teamviewer"
        "Google Chrome|Google Chrome browser|google-chrome-stable|google-chrome-stable"
        "Python 3 pip|python3-pip + python3-venv|python3-pip python3-venv|python3-pip"
        "DBeaver CE|DBeaver CE (database tool)|dbeaver-ce|dbeaver-ce"
        "VLC|VLC media player|vlc|vlc"
        "Cloudflared|Cloudflare Tunnel client|cloudflared|cloudflared"
        "Docker Engine|Docker Engine + Compose plugin|docker-ce docker-ce-cli containerd.io docker-compose-plugin docker-buildx-plugin|docker-ce"
        "GitHub CLI (gh)|GitHub CLI (gh)|gh|gh"
        "FileZilla|FileZilla (FTP/SFTP client)|filezilla|filezilla"
        "Firefox|Firefox APT (deb / xtradeb PPA)|firefox|firefox"
    )
    local _ga _gan _gad _gap _gadet
    for _ga in "${_gone_apps[@]}"; do
        IFS='|' read -r _gan _gad _gap _gadet <<< "$_ga"
        if ! dpkg -l "$_gadet" 2>/dev/null | grep -q "^ii"; then
            BLOAT_NAMES+=("$_gan"); BLOAT_DESCS+=("$_gad"); BLOAT_PKGS+=("$_gap")
        fi
    done

    local TOTAL_BLOAT=${#BLOAT_NAMES[@]}

    if [ "$TOTAL_BLOAT" -eq 0 ]; then
        echo -e "${GREEN}No bloatware found - system is already clean!${NC}"
        sleep 2
        DEBLOAT_SELECTED_PKGS=()
        DEBLOAT_SELECTED_NAMES=()
        return 0
    fi

    local -a BSELECTED=()
    local -a BLOAT_DONE=()
    for ((bi=0; bi<TOTAL_BLOAT; bi++)); do
        BSELECTED+=(0)
        if bloat_is_done "${BLOAT_PKGS[$bi]}"; then
            BLOAT_DONE+=(1)
        else
            BLOAT_DONE+=(0)
        fi
    done
    local bcursor=0

    tput civis 2>/dev/null || true

    while true; do
        clear
        echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${CYAN}║                    ${RED}Debloat - Remove Bloatware${CYAN}                             ║${NC}"
        echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "${YELLOW}  ${TOTAL_BLOAT} item(s) listed (items marked **debloated are already removed).${NC}"
        echo -e "${YELLOW}  Select what you want to remove (nothing selected by default).${NC}"
        echo ""
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}     Use ↑↓ arrows to navigate, SPACE to toggle${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""

        local bi
        for ((bi=0; bi<TOTAL_BLOAT; bi++)); do
            local bname="${BLOAT_NAMES[$bi]}"
            local bdesc="${BLOAT_DESCS[$bi]}"
            local bnum=$(printf "%2d" $((bi + 1)))
            local bcheck="[ ]"
            local bline="   "

            if [ "${BSELECTED[$bi]}" = "1" ]; then
                bcheck="${RED}[✗]${NC}"
            fi
            if [ "$bcursor" = "$bi" ]; then
                bline=" ${CYAN}▶${NC}"
            fi
            local bmark=""
            [ "${BLOAT_DONE[$bi]}" = "1" ] && bmark="  ${YELLOW}**debloated${NC}"
            if [ "${BSELECTED[$bi]}" = "1" ]; then
                echo -e "${bline} ${BLUE}[$bnum]${NC} $bcheck ${RED}$bname${NC} - $bdesc$bmark"
            else
                echo -e "${bline} ${BLUE}[$bnum]${NC} $bcheck $bname - $bdesc$bmark"
            fi
        done

        echo ""
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"

        local bcount=0
        local bsel_names=""
        for ((bi=0; bi<TOTAL_BLOAT; bi++)); do
            if [ "${BSELECTED[$bi]}" = "1" ]; then
                bcount=$((bcount + 1))
                bsel_names="${bsel_names}${BLOAT_NAMES[$bi]}, "
            fi
        done

        if [ $bcount -gt 0 ]; then
            bsel_names="${bsel_names%, }"
            echo -e "  ${RED}Removing ($bcount):${NC} $bsel_names"
        else
            echo -e "  ${GREEN}Nothing selected for removal${NC}"
        fi

        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
        echo ""
        echo -e "  ${CYAN}CONTROLS:${NC}  ${YELLOW}↑↓${NC}=Move  ${YELLOW}SPACE${NC}=Toggle  ${YELLOW}a${NC}=All  ${YELLOW}n${NC}=None  ${GREEN}c/ESC${NC}=Save+Back  ${RED}q${NC}=Discard"
        echo ""

        IFS= read -rsn1 bkey < /dev/tty 2>/dev/null || bkey=""
        if [ "$bkey" = $'\x1b' ]; then
            read -rsn2 -t 0.1 brest < /dev/tty 2>/dev/null || brest=""
            bkey="${bkey}${brest}"
            if [ "$bkey" = $'\x1b' ]; then
                # Lone ESC: save selections (act like 'c') and return
                bkey='c'
            fi
        fi

        case "$bkey" in
            $'\x1b[A'|'k')
                if [ $bcursor -gt 0 ]; then bcursor=$((bcursor - 1)); fi
                ;;
            $'\x1b[B'|'j')
                if [ $bcursor -lt $((TOTAL_BLOAT - 1)) ]; then bcursor=$((bcursor + 1)); fi
                ;;
            ' ')
                if [ "${BSELECTED[$bcursor]}" = "1" ]; then
                    BSELECTED[$bcursor]=0
                else
                    BSELECTED[$bcursor]=1
                fi
                ;;
            'a'|'A')
                for ((bi=0; bi<TOTAL_BLOAT; bi++)); do BSELECTED[$bi]=1; done
                ;;
            'n'|'N')
                for ((bi=0; bi<TOTAL_BLOAT; bi++)); do BSELECTED[$bi]=0; done
                ;;
            'c'|'C'|'')
                tput cnorm 2>/dev/null || true
                DEBLOAT_SELECTED_PKGS=()
                DEBLOAT_SELECTED_NAMES=()
                for ((bi=0; bi<TOTAL_BLOAT; bi++)); do
                    if [ "${BSELECTED[$bi]}" = "1" ]; then
                        DEBLOAT_SELECTED_PKGS+=("${BLOAT_PKGS[$bi]}")
                        DEBLOAT_SELECTED_NAMES+=("${BLOAT_NAMES[$bi]}")
                    fi
                done
                return 0
                ;;
            'q'|'Q')
                tput cnorm 2>/dev/null || true
                return 1
                ;;
            [1-9])
                local bnum_key=$((bkey - 1))
                if [ $bnum_key -lt $TOTAL_BLOAT ]; then
                    if [ "${BSELECTED[$bnum_key]}" = "1" ]; then
                        BSELECTED[$bnum_key]=0
                    else
                        BSELECTED[$bnum_key]=1
                    fi
                    bcursor=$bnum_key
                fi
                ;;
        esac
    done
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
    APP_NAMES+=("Remote Support Tools"); APP_DESCS+=("RealVNC, AnyDesk, RustDesk, TeamViewer (Enter to expand sub-menu)"); APP_VARS+=("INSTALL_REMOTE")
    APP_NAMES+=("NodeJS");      APP_DESCS+=("NVM + Node.js 22 + Yarn + CLI Tools");  APP_VARS+=("INSTALL_NODEJS")

    # Chrome only on amd64, Chromium on ARM
    if [ "$DEB_ARCH" == "amd64" ]; then
        APP_NAMES+=("Chrome");  APP_DESCS+=("Google Chrome");                         APP_VARS+=("INSTALL_CHROME")
    else
        # If chromium is currently a snap, suggest replacing it with the APT version
        if snap list chromium &>/dev/null; then
            APP_NAMES+=("Chromium"); APP_DESCS+=("Replace Chromium snap with APT (xtradeb PPA)"); APP_VARS+=("INSTALL_CHROME")
        else
            APP_NAMES+=("Chromium"); APP_DESCS+=("Chromium APT (xtradeb PPA, no snap)");          APP_VARS+=("INSTALL_CHROME")
        fi
    fi

    APP_NAMES+=("VS Code");     APP_DESCS+=("Visual Studio Code (Enter: extensions & tweaks)"); APP_VARS+=("INSTALL_VSCODE")
    APP_NAMES+=("Python");      APP_DESCS+=("Python 3 + pip + venv");                 APP_VARS+=("INSTALL_PYTHON")
    APP_NAMES+=("Tweaks");      APP_DESCS+=("Tweaks (Enter to expand sub-menu)");      APP_VARS+=("INSTALL_GNOME")
    APP_NAMES+=("DBeaver");     APP_DESCS+=("DBeaver CE (Database Tool)");            APP_VARS+=("INSTALL_DBEAVER")
    APP_NAMES+=("VLC");         APP_DESCS+=("VLC Media Player");                      APP_VARS+=("INSTALL_VLC")
    APP_NAMES+=("Cloudflared"); APP_DESCS+=("Cloudflare Tunnel Client");              APP_VARS+=("INSTALL_CLOUDFLARED")
    APP_NAMES+=("Docker");      APP_DESCS+=("Docker Engine + Compose");               APP_VARS+=("INSTALL_DOCKER")
    APP_NAMES+=("AI CLI Tools"); APP_DESCS+=("AI CLI Tools (Claude/Codex etc. - Enter to expand sub-menu)"); APP_VARS+=("INSTALL_AICLI")
    APP_NAMES+=("Git & GitHub CLI"); APP_DESCS+=("Git + GitHub CLI (gh)");               APP_VARS+=("INSTALL_GH")
    APP_NAMES+=("Postman");     APP_DESCS+=("Postman (API Testing Tool)");             APP_VARS+=("INSTALL_POSTMAN")
    APP_NAMES+=("FileZilla");   APP_DESCS+=("FileZilla (FTP/SFTP Client)");            APP_VARS+=("INSTALL_FILEZILLA")
    APP_NAMES+=("Debloat");     APP_DESCS+=("Debloat (Enter to expand sub-menu)");    APP_VARS+=("DO_DEBLOAT")

    # ARM Fix - only on Jetson devices (other ARM devices don't need snapd fix)
    # Jetson-only: jtop (jetson-stats) live monitor
    if $IS_JETSON; then
        APP_NAMES+=("jtop");    APP_DESCS+=("jetson-stats (live CPU/GPU/RAM/temp monitor)"); APP_VARS+=("INSTALL_JTOP")
    fi
    if $IS_JETSON && command_exists snap; then
        APP_NAMES+=("ARM Fix"); APP_DESCS+=("Jetson Snapd Fix (Browser Fix)");        APP_VARS+=("APPLY_JETSON_FIX")
    fi

    local TOTAL_ITEMS=${#APP_NAMES[@]}
    local -a SELECTED=()
    for ((idx=0; idx<TOTAL_ITEMS; idx++)); do
        SELECTED+=(0)
    done
    local cursor=0
    local key=""
    local count=0

    # Pre-compute group aggregate states (Remote / Tweaks / AI CLI / Debloat)
    local _gk
    local _rm_inst=0 _rm_total=0
    for _gk in REMOTE_SUB_VNC REMOTE_SUB_ANYDESK REMOTE_SUB_RUSTDESK REMOTE_SUB_TEAMVIEWER; do
        _rm_total=$((_rm_total + 1))
        remote_installed "$_gk" 2>/dev/null && _rm_inst=$((_rm_inst + 1))
    done
    local _tw_applied=0 _tw_total=0
    for _gk in GNOME_SUB_EXTENSIONS GNOME_SUB_TWEAKS_APP GNOME_SUB_SCRIPT GNOME_SUB_WAYLAND \
               GNOME_SUB_SSH GNOME_SUB_ALIASES GNOME_SUB_SCREEN GNOME_SUB_HIDDEN \
               GNOME_SUB_KB_TR GNOME_SUB_KB_EN GNOME_SUB_NO_IBUS GNOME_SUB_APPORT \
               GNOME_SUB_CHEESE GNOME_SUB_CLEANUP2Y GNOME_SUB_VSCREEN GNOME_SUB_AUTOLOGIN; do
        _tw_total=$((_tw_total + 1))
        gnome_tweak_applied "$_gk" 2>/dev/null && _tw_applied=$((_tw_applied + 1))
    done
    local _ai_inst=0 _ai_total=0
    for _gk in AICLI_SUB_CLAUDE AICLI_SUB_CODEX AICLI_SUB_KIMI AICLI_SUB_GROK \
               AICLI_SUB_GEMINI AICLI_SUB_QWEN AICLI_SUB_GLM AICLI_SUB_OPENCODE; do
        _ai_total=$((_ai_total + 1))
        aicli_installed "$_gk" 2>/dev/null && _ai_inst=$((_ai_inst + 1))
    done
    # Debloat: count how many known bloat/app packages are already removed.
    # The universe includes the apps the script can install too, so "all
    # debloated" only shows when literally nothing removable is left.
    local _db_gone=0 _db_total=0 _dbp
    for _dbp in libreoffice-common gnome-mahjongg aisleriot gnome-mines gnome-sudoku \
                thunderbird transmission-gtk shotwell simple-scan rhythmbox totem \
                gnome-todo remmina cups xterm gnome-font-viewer gucharmap \
                gnome-characters gnome-calendar gnome-calculator vim \
                gnome-power-manager code google-chrome-stable chromium python3-pip \
                dbeaver-ce vlc cloudflared docker-ce gh filezilla firefox \
                rustdesk anydesk teamviewer; do
        _db_total=$((_db_total + 1))
        dpkg -l "$_dbp" 2>/dev/null | grep -q "^ii" || _db_gone=$((_db_gone + 1))
    done

    # Pre-compute "installed"/"applied" status markers for each item (once).
    # Shown in the menu so the user sees what's already on the system.
    local -a ITEM_MARK=()
    local _mi
    for ((_mi=0; _mi<TOTAL_ITEMS; _mi++)); do
        ITEM_MARK+=("")
        case "${APP_VARS[$_mi]}" in
            INSTALL_REMOTE)     ITEM_MARK[$_mi]="$(group_marker "$_rm_inst" "$_rm_total" "installed")" ;;
            INSTALL_NODEJS)     { [ -d "$HOME/.nvm" ] && command_exists node; } 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_CHROME)     { command_exists google-chrome || command_exists google-chrome-stable || command_exists chromium-browser || command_exists chromium; } 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_VSCODE)     command_exists code 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_PYTHON)     command_exists python3 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_GNOME)      ITEM_MARK[$_mi]="$(group_marker "$_tw_applied" "$_tw_total" "applied")" ;;
            INSTALL_DBEAVER)    { package_installed dbeaver-ce || command_exists dbeaver; } 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_VLC)        command_exists vlc 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_CLOUDFLARED) command_exists cloudflared 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_DOCKER)     command_exists docker 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_AICLI)      ITEM_MARK[$_mi]="$(group_marker "$_ai_inst" "$_ai_total" "installed")" ;;
            DO_DEBLOAT)         ITEM_MARK[$_mi]="$(group_marker "$_db_gone" "$_db_total" "debloated")" ;;
            INSTALL_GH)         command_exists gh 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_POSTMAN)    { command_exists postman || snap list postman 2>/dev/null | grep -q postman; } 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_FILEZILLA)  command_exists filezilla 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
            INSTALL_JTOP)       command_exists jtop 2>/dev/null && ITEM_MARK[$_mi]="installed" ;;
        esac
    done

    # Hide cursor
    tput civis 2>/dev/null || true

    while true; do
        clear
        show_system_header

        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo -e "${GREEN}     Use ↑↓ arrows to navigate, SPACE to select${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════════════${NC}"
        echo ""

        # Find VS Code selection state for dynamic Claude/Codex descriptions
        local vscode_selected=0
        local _vi
        for ((_vi=0; _vi<TOTAL_ITEMS; _vi++)); do
            if [ "${APP_VARS[$_vi]}" = "INSTALL_VSCODE" ] && [ "${SELECTED[$_vi]}" = "1" ]; then
                vscode_selected=1
                break
            fi
        done

        # Draw menu items
        local i
        for ((i=0; i<TOTAL_ITEMS; i++)); do
            local name="${APP_NAMES[$i]}"
            local desc="${APP_DESCS[$i]}"
            local num_display=$(printf "%2d" $((i + 1)))
            local checkbox="[ ]"
            local line_start="   "

            # Dynamic description for AI CLI Tools based on VS Code selection
            if [ "${APP_VARS[$i]}" = "INSTALL_AICLI" ] && [ "$vscode_selected" = "1" ]; then
                desc="AI CLI Tools + VS Code Extensions (Enter to expand sub-menu)"
            fi

            if [ "${SELECTED[$i]}" = "1" ]; then
                checkbox="${GREEN}[✓]${NC}"
            fi

            if [ "$cursor" = "$i" ]; then
                line_start=" ${CYAN}▶${NC}"
            fi

            local mark_str=""
            if [ -n "${ITEM_MARK[$i]}" ]; then
                mark_str="  ${YELLOW}**${ITEM_MARK[$i]}${NC}"
            fi

            if [ "${SELECTED[$i]}" = "1" ]; then
                echo -e "${line_start} ${BLUE}[$num_display]${NC} $checkbox ${GREEN}$name${NC} - $desc$mark_str"
            else
                echo -e "${line_start} ${BLUE}[$num_display]${NC} $checkbox $name - $desc$mark_str"
            fi
        done

        echo ""
        echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"

        # Count selected and build descriptive string showing sub-picks
        count=0
        local selected_names=""
        for ((i=0; i<TOTAL_ITEMS; i++)); do
            if [ "${SELECTED[$i]}" = "1" ]; then
                count=$((count + 1))
                case "${APP_VARS[$i]}" in
                    INSTALL_REMOTE)
                        local _rm=""
                        $REMOTE_SUB_VNC && _rm+="VNC,"
                        $REMOTE_SUB_ANYDESK && _rm+="AnyDesk,"
                        $REMOTE_SUB_RUSTDESK && _rm+="RustDesk,"
                        $REMOTE_SUB_TEAMVIEWER && _rm+="TV,"
                        _rm="${_rm%,}"
                        if [ -n "$_rm" ]; then
                            selected_names+="Remote[$_rm], "
                        else
                            selected_names+="Remote[none], "
                        fi
                        ;;
                    INSTALL_GNOME)
                        local _tw=""
                        $GNOME_SUB_EXTENSIONS && _tw+="Extensions,"
                        $GNOME_SUB_UPDATE && _tw+="Update,"
                        $GNOME_SUB_TWEAKS_APP && _tw+="Tweaks App,"
                        $GNOME_SUB_DOCK && _tw+="Dock,"
                        $GNOME_SUB_SCRIPT && _tw+="Script,"
                        $GNOME_SUB_WAYLAND && _tw+="Wayland,"
                        $GNOME_SUB_SSH && _tw+="SSH,"
                        $GNOME_SUB_ALIASES && _tw+="Aliases,"
                        $GNOME_SUB_SCREEN && _tw+="Screen,"
                        $GNOME_SUB_KB_TR && _tw+="KB:TR,"
                        $GNOME_SUB_KB_EN && _tw+="KB:EN,"
                        $GNOME_SUB_VSCREEN && _tw+="VScreen,"
                        $GNOME_SUB_AUTOLOGIN && _tw+="AutoLogin,"
                        $GNOME_SUB_CLEANUP2Y && _tw+="2Y,"
                        _tw="${_tw%,}"
                        if [ -n "$_tw" ]; then
                            selected_names+="Tweaks[$_tw], "
                        else
                            selected_names+="Tweaks[none], "
                        fi
                        ;;
                    INSTALL_AICLI)
                        local _ai=""
                        $AICLI_SUB_CLAUDE && _ai+="Claude,"
                        $AICLI_SUB_CODEX && _ai+="Codex,"
                        $AICLI_SUB_KIMI && _ai+="Kimi,"
                        $AICLI_SUB_GROK && _ai+="Grok,"
                        $AICLI_SUB_GEMINI && _ai+="Gemini,"
                        $AICLI_SUB_QWEN && _ai+="Qwen,"
                        $AICLI_SUB_GLM && _ai+="GLM,"
                        $AICLI_SUB_OPENCODE && _ai+="OpenCode,"
                        _ai="${_ai%,}"
                        if [ -n "$_ai" ]; then
                            selected_names+="AI[$_ai], "
                        else
                            selected_names+="AI[none], "
                        fi
                        ;;
                    DO_DEBLOAT)
                        local _dbc=${#DEBLOAT_SELECTED_NAMES[@]}
                        if [ "$_dbc" -gt 0 ]; then
                            selected_names+="Debloat[${_dbc} items], "
                        else
                            selected_names+="Debloat[none], "
                        fi
                        ;;
                    *)
                        selected_names+="${APP_NAMES[$i]}, "
                        ;;
                esac
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
        echo -e "  ${CYAN}CONTROLS:${NC}  ${YELLOW}↑↓${NC}=Move  ${YELLOW}SPACE${NC}=Toggle  ${YELLOW}ENTER${NC}=Sub-menu  ${YELLOW}a${NC}=All  ${YELLOW}n${NC}=None  ${GREEN}c${NC}=Confirm  ${RED}q${NC}=Quit"
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
                    # Auto-select ARM Fix when VNC is selected (only on Jetson)
                    if [ "${APP_VARS[$cursor]}" = "INSTALL_REMOTE" ] && $IS_JETSON; then
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
            '') # Enter - open sub-menu for current item (if it has one)
                if [ "${APP_VARS[$cursor]}" = "INSTALL_REMOTE" ]; then
                    SELECTED[$cursor]=1
                    show_remote_submenu || true
                elif [ "${APP_VARS[$cursor]}" = "INSTALL_GNOME" ]; then
                    SELECTED[$cursor]=1
                    show_gnome_submenu || true
                elif [ "${APP_VARS[$cursor]}" = "DO_DEBLOAT" ]; then
                    SELECTED[$cursor]=1
                    show_debloat_submenu || true
                elif [ "${APP_VARS[$cursor]}" = "INSTALL_AICLI" ]; then
                    SELECTED[$cursor]=1
                    show_aicli_submenu || true
                elif [ "${APP_VARS[$cursor]}" = "INSTALL_VSCODE" ]; then
                    SELECTED[$cursor]=1
                    show_vscode_submenu || true
                fi
                ;;
            'c'|'C') # Confirm and start installation
                if [ $count -eq 0 ]; then
                    echo -e "${RED}Please select at least one application!${NC}"
                    sleep 1
                    continue
                fi

                # Detect conflicting picks: Apport selected in Tweaks (Activate)
                # AND Debloat (Remove) — they'd cancel out. Same for Snap install
                # markers vs Debloat snap removal. Warn the user.
                local _conflicts=""
                if $GNOME_SUB_APPORT; then
                    for _dn in "${DEBLOAT_SELECTED_NAMES[@]}"; do
                        [ "$_dn" = "Apport" ] && _conflicts+="Apport (Tweaks Activate vs Debloat Remove)\n"
                    done
                fi
                if [ -n "$_conflicts" ]; then
                    tput cnorm 2>/dev/null || true
                    echo ""
                    echo -e "${YELLOW}⚠  You picked the same item in both Tweaks and Debloat:${NC}"
                    echo -e "${YELLOW}$_conflicts${NC}"
                    echo -e "${YELLOW}They cancel each other out — net effect: nothing changes.${NC}"
                    echo ""
                    read -p "Continue anyway? (y/n): " _conf_ok < /dev/tty
                    if [[ ! "$_conf_ok" =~ ^[Yy]$ ]]; then
                        tput civis 2>/dev/null || true
                        continue
                    fi
                fi

                tput cnorm 2>/dev/null || true
                clear

                # Show summary of what will be installed
                echo -e "${CYAN}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
                echo -e "${CYAN}║                    ${GREEN}Installation Summary${CYAN}                                  ║${NC}"
                echo -e "${CYAN}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
                echo ""
                echo -e "${GREEN}The following will be installed/configured:${NC}"
                echo ""
                for ((i=0; i<TOTAL_ITEMS; i++)); do
                    if [ "${SELECTED[$i]}" = "1" ]; then
                        case "${APP_VARS[$i]}" in
                            INSTALL_REMOTE)
                                local remote_list=""
                                $REMOTE_SUB_VNC && remote_list+="RealVNC, "
                                $REMOTE_SUB_ANYDESK && remote_list+="AnyDesk, "
                                $REMOTE_SUB_RUSTDESK && remote_list+="RustDesk, "
                                $REMOTE_SUB_TEAMVIEWER && remote_list+="TeamViewer, "
                                remote_list="${remote_list%, }"
                                if [ -n "$remote_list" ]; then
                                    echo -e "  ${GREEN}✓${NC} ${GREEN}Remote Support:${NC}"
                                    echo "$remote_list" | tr ',' '\n' | while IFS= read -r item; do
                                        item="${item## }"
                                        [ -n "$item" ] && echo -e "       ${CYAN}•${NC} $item"
                                    done
                                else
                                    echo -e "  ${YELLOW}!${NC} ${GREEN}Remote Support:${NC} (no sub-items selected - will skip)"
                                fi
                                ;;
                            INSTALL_VSCODE)
                                echo -e "  ${GREEN}✓${NC} ${GREEN}VS Code${NC}"
                                local vsc_list=""
                                $VSCODE_SUB_CLAUDE   && vsc_list+="Claude Code ext, "
                                $VSCODE_SUB_CODEX    && vsc_list+="Codex/ChatGPT ext, "
                                $VSCODE_SUB_PYTHON   && vsc_list+="Python ext, "
                                $VSCODE_SUB_PYLANCE  && vsc_list+="Pylance ext, "
                                $VSCODE_SUB_GITLENS  && vsc_list+="GitLens ext, "
                                $VSCODE_SUB_PRETTIER && vsc_list+="Prettier ext, "
                                $VSCODE_SUB_ESLINT   && vsc_list+="ESLint ext, "
                                $VSCODE_SUB_DOCKER   && vsc_list+="Docker ext, "
                                $VSCODE_SUB_ICONS    && vsc_list+="Material Icons, "
                                $VSCODE_SUB_SETTINGS && vsc_list+="Settings/Tweaks, "
                                vsc_list="${vsc_list%, }"
                                if [ -n "$vsc_list" ]; then
                                    echo "$vsc_list" | tr ',' '\n' | while IFS= read -r item; do
                                        item="${item## }"
                                        [ -n "$item" ] && echo -e "       ${CYAN}•${NC} $item"
                                    done
                                fi
                                ;;
                            INSTALL_GNOME)
                                # List actual Tweaks sub-menu picks
                                local tweaks_list=""
                                $GNOME_SUB_EXTENSIONS  && tweaks_list+="Extensions, "
                                $GNOME_SUB_UPDATE      && tweaks_list+="Update System, "
                                $GNOME_SUB_TWEAKS_APP  && tweaks_list+="GNOME Tweaks App, "
                                $GNOME_SUB_DOCK        && tweaks_list+="Dash to Dock, "
                                $GNOME_SUB_SCRIPT      && tweaks_list+="Script Launcher, "
                                $GNOME_SUB_WAYLAND     && tweaks_list+="Disable Wayland, "
                                $GNOME_SUB_SSH         && tweaks_list+="OpenSSH Server, "
                                $GNOME_SUB_ALIASES     && tweaks_list+="CLI Aliases, "
                                $GNOME_SUB_ENGLISH     && tweaks_list+="English Language, "
                                $GNOME_SUB_SCREEN      && tweaks_list+="Screen Off: Never, "
                                $GNOME_SUB_HIDDEN      && tweaks_list+="Show Hidden Files, "
                                $GNOME_SUB_KB_TR       && tweaks_list+="Keyboard: Turkish Q, "
                                $GNOME_SUB_KB_EN       && tweaks_list+="Keyboard: English Q, "
                                $GNOME_SUB_VSCREEN     && tweaks_list+="Virtual Screen 1080p, "
                                $GNOME_SUB_AUTOLOGIN   && tweaks_list+="GDM Auto-Login, "
                                $GNOME_SUB_HOSTNAME    && tweaks_list+="Change Hostname → $NEW_HOSTNAME, "
                                $GNOME_SUB_NO_IBUS     && tweaks_list+="IBus Leak Fix, "
                                $GNOME_SUB_APPORT      && tweaks_list+="Activate Apport, "
                                $GNOME_SUB_CHEESE      && tweaks_list+="Install Cheese, "
                                $GNOME_SUB_CLEANUP2Y   && tweaks_list+="Cleanup Period: 2Y, "
                                tweaks_list="${tweaks_list%, }"
                                if [ -n "$tweaks_list" ]; then
                                    echo -e "  ${GREEN}✓${NC} ${GREEN}Tweaks:${NC}"
                                    # Word-wrap by splitting on comma
                                    echo "$tweaks_list" | tr ',' '\n' | while IFS= read -r item; do
                                        item="${item## }"
                                        [ -n "$item" ] && echo -e "       ${CYAN}•${NC} $item"
                                    done
                                else
                                    echo -e "  ${YELLOW}!${NC} ${GREEN}Tweaks:${NC} (no sub-items selected - will skip)"
                                fi
                                ;;
                            DO_DEBLOAT)
                                # List actual Debloat sub-menu picks
                                if [ "${#DEBLOAT_SELECTED_NAMES[@]}" -gt 0 ]; then
                                    echo -e "  ${RED}✗${NC} ${RED}Debloat (will remove):${NC}"
                                    for _dn in "${DEBLOAT_SELECTED_NAMES[@]}"; do
                                        echo -e "       ${RED}•${NC} $_dn"
                                    done
                                else
                                    echo -e "  ${YELLOW}!${NC} ${RED}Debloat:${NC} (no items selected - will skip)"
                                fi
                                ;;
                            INSTALL_AICLI)
                                # List actual AI CLI Tools sub-menu picks
                                local aicli_list=""
                                $AICLI_SUB_CLAUDE && aicli_list+="Claude Code, "
                                $AICLI_SUB_CODEX  && aicli_list+="Codex, "
                                $AICLI_SUB_KIMI   && aicli_list+="Kimi Code, "
                                $AICLI_SUB_GROK   && aicli_list+="Grok, "
                                $AICLI_SUB_GEMINI && aicli_list+="Gemini CLI, "
                                $AICLI_SUB_QWEN   && aicli_list+="Qwen CLI, "
                                $AICLI_SUB_GLM    && aicli_list+="GLM Code, "
                                $AICLI_SUB_OPENCODE && aicli_list+="GLM With OpenCode, "
                                aicli_list="${aicli_list%, }"
                                if [ -n "$aicli_list" ]; then
                                    echo -e "  ${GREEN}✓${NC} ${GREEN}AI CLI Tools:${NC}"
                                    echo "$aicli_list" | tr ',' '\n' | while IFS= read -r item; do
                                        item="${item## }"
                                        [ -n "$item" ] && echo -e "       ${CYAN}•${NC} $item"
                                    done
                                else
                                    echo -e "  ${YELLOW}!${NC} ${GREEN}AI CLI Tools:${NC} (no sub-items selected - will skip)"
                                fi
                                ;;
                            *)
                                echo -e "  ${GREEN}✓${NC} ${APP_NAMES[$i]} - ${APP_DESCS[$i]}"
                                ;;
                        esac
                    fi
                done
                echo ""
                echo -e "${YELLOW}───────────────────────────────────────────────────────────────${NC}"
                echo ""

                read -p "Proceed with installation? (y/n): " confirm_choice < /dev/tty
                if [[ ! "$confirm_choice" =~ ^[Yy]$ ]]; then
                    echo -e "${YELLOW}Cancelled, returning to menu...${NC}"
                    sleep 1
                    tput civis 2>/dev/null || true
                    continue
                fi

                # Set flags
                for ((i=0; i<TOTAL_ITEMS; i++)); do
                    if [ "${SELECTED[$i]}" = "1" ]; then
                        eval "${APP_VARS[$i]}=true"
                    fi
                done
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
        if command_exists vncserver-x11 || package_installed realvnc-rvncconnect || package_installed realvnc-connect || package_installed realvnc-vnc-server; then
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

    { command_exists vncserver-x11 || package_installed realvnc-rvncconnect || package_installed realvnc-connect; } && echo -e "  ${GREEN}✓${NC} RealVNC"
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
    # NOTE: INSTALL_GNOME (Tweaks) is intentionally NOT here - its sub-menu
    # handles per-item idempotency itself.
    local -a CHECKS=(
        "INSTALL_VNC|RealVNC|command_exists vncserver-x11 || command_exists vncserver || package_installed realvnc-rvncconnect || package_installed realvnc-connect || package_installed realvnc-vnc-server || [ -f /usr/bin/vncserver-x11 ]"
        "INSTALL_RUSTDESK|RustDesk|command_exists rustdesk"
        "INSTALL_ANYDESK|AnyDesk|command_exists anydesk || package_installed anydesk"
        "INSTALL_TEAMVIEWER|TeamViewer|command_exists teamviewer || package_installed teamviewer"
        "INSTALL_NODEJS|Node.js + NVM|[ -d \"\$HOME/.nvm\" ] && command_exists node"
        "INSTALL_CHROME|Chrome/Chromium|command_exists google-chrome || command_exists google-chrome-stable || command_exists chromium-browser || command_exists chromium"
        "INSTALL_VSCODE|VS Code|command_exists code"
        "INSTALL_PYTHON|Python 3|command_exists python3"
        "INSTALL_DBEAVER|DBeaver|package_installed dbeaver-ce || command_exists dbeaver"
        "INSTALL_VLC|VLC|command_exists vlc"
        "INSTALL_CLOUDFLARED|Cloudflared|command_exists cloudflared"
        "INSTALL_DOCKER|Docker|command_exists docker"
        "INSTALL_CLAUDE|Claude Code|command_exists claude"
        "INSTALL_CODEX|Codex|command_exists codex"
        "INSTALL_KIMI|Kimi Code|command_exists kimi"
        "INSTALL_GROK|Grok|command_exists grok"
        "INSTALL_GEMINI|Gemini CLI|command_exists gemini"
        "INSTALL_QWEN|Qwen CLI|command_exists qwen"
        "INSTALL_GLM|GLM Code (z.ai)|command_exists chelper"
        "INSTALL_OPENCODE|GLM With OpenCode|command_exists opencode"
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

    # Expand Remote Support sub-menu picks into individual install flags.
    if $INSTALL_REMOTE; then
        $REMOTE_SUB_VNC        && INSTALL_VNC=true
        $REMOTE_SUB_ANYDESK    && INSTALL_ANYDESK=true
        $REMOTE_SUB_RUSTDESK   && INSTALL_RUSTDESK=true
        $REMOTE_SUB_TEAMVIEWER && INSTALL_TEAMVIEWER=true
    fi

    # Expand AI CLI Tools sub-menu picks into individual install flags.
    if $INSTALL_AICLI; then
        $AICLI_SUB_CLAUDE && INSTALL_CLAUDE=true
        $AICLI_SUB_CODEX  && INSTALL_CODEX=true
        $AICLI_SUB_KIMI   && INSTALL_KIMI=true
        $AICLI_SUB_GROK   && INSTALL_GROK=true
        $AICLI_SUB_GEMINI && INSTALL_GEMINI=true
        $AICLI_SUB_QWEN   && INSTALL_QWEN=true
        $AICLI_SUB_GLM    && INSTALL_GLM=true
        $AICLI_SUB_OPENCODE && INSTALL_OPENCODE=true
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
    if $INSTALL_VSCODE; then
        install_vscode || handle_error "VS Code installation failed"
    elif command_exists code && { $VSCODE_SUB_CLAUDE || $VSCODE_SUB_CODEX || $VSCODE_SUB_PYTHON || \
         $VSCODE_SUB_PYLANCE || $VSCODE_SUB_GITLENS || $VSCODE_SUB_PRETTIER || $VSCODE_SUB_ESLINT || \
         $VSCODE_SUB_DOCKER || $VSCODE_SUB_ICONS; }; then
        # VS Code already installed and user picked extensions/tweaks only
        install_vscode_extensions || true
    fi
    if $INSTALL_PYTHON; then install_python || handle_error "Python installation failed"; fi
    if $INSTALL_GNOME; then install_gnome_extensions || handle_error "GNOME extensions installation failed"; fi
    if $INSTALL_DBEAVER; then install_dbeaver || handle_error "DBeaver installation failed"; fi
    if $INSTALL_VLC; then install_vlc || handle_error "VLC installation failed"; fi
    if $INSTALL_CLOUDFLARED; then install_cloudflared || handle_error "Cloudflared installation failed"; fi
    if $INSTALL_DOCKER; then install_docker || handle_error "Docker installation failed"; fi
    if $INSTALL_CLAUDE; then install_claude_code || handle_error "Claude Code installation failed"; fi
    if $INSTALL_CODEX; then install_codex || handle_error "Codex installation failed"; fi
    if $INSTALL_KIMI; then install_kimi || handle_error "Kimi Code installation failed"; fi
    if $INSTALL_GROK; then install_grok || handle_error "Grok installation failed"; fi
    if $INSTALL_GEMINI; then install_gemini || handle_error "Gemini CLI installation failed"; fi
    if $INSTALL_QWEN; then install_qwen || handle_error "Qwen CLI installation failed"; fi
    if $INSTALL_GLM; then install_glm || handle_error "GLM Code installation failed"; fi
    if $INSTALL_OPENCODE; then install_glm_opencode || handle_error "GLM With OpenCode installation failed"; fi
    if $INSTALL_JTOP; then install_jtop || handle_error "jtop installation failed"; fi
    if $INSTALL_GH; then install_gh || handle_error "GitHub CLI installation failed"; fi
    if $INSTALL_POSTMAN; then install_postman || handle_error "Postman installation failed"; fi
    if $INSTALL_FILEZILLA; then install_filezilla || handle_error "FileZilla installation failed"; fi
    if $INSTALL_RUSTDESK; then install_rustdesk || handle_error "RustDesk installation failed"; fi
    if $INSTALL_ANYDESK; then install_anydesk || handle_error "AnyDesk installation failed"; fi
    if $INSTALL_TEAMVIEWER; then install_teamviewer || handle_error "TeamViewer installation failed"; fi

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

    # Debloat (remove unwanted preinstalled apps)
    if $DO_DEBLOAT; then debloat_system || handle_error "Debloat failed"; fi

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
    local download_url="" arch_suffix=""
    local fallback_ver="1.4.7"

    if [ "$DEB_ARCH" == "amd64" ]; then
        arch_suffix="x86_64"
    else
        arch_suffix="aarch64"
    fi

    # Try to get latest version from GitHub API
    local latest_ver
    latest_ver=$(curl -fsSL -m 10 https://api.github.com/repos/rustdesk/rustdesk/releases/latest 2>/dev/null | grep -oP '"tag_name":\s*"\K[^"]+')
    [ -z "$latest_ver" ] && latest_ver="$fallback_ver"

    download_url="https://github.com/rustdesk/rustdesk/releases/download/${latest_ver}/rustdesk-${latest_ver}-${arch_suffix}.deb"
    log_info "Downloading RustDesk ${latest_ver} (${arch_suffix})..."

    if ! retry_curl_download "$download_url" "$temp_file" "Downloading RustDesk"; then
        # Fallback to known-good version
        download_url="https://github.com/rustdesk/rustdesk/releases/download/${fallback_ver}/rustdesk-${fallback_ver}-${arch_suffix}.deb"
        retry_curl_download "$download_url" "$temp_file" "Downloading RustDesk (fallback)"
    fi

    if [ ! -f "$temp_file" ]; then
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
# 1.6 AnyDesk Installation
#===============================================================================
install_anydesk() {
    log_step "1.6 Installing AnyDesk"

    if command_exists anydesk || package_installed anydesk; then
        log_warning "AnyDesk already installed, skipping..."
        return 0
    fi

    local temp_file="/tmp/anydesk.deb"

    # AnyDesk provides latest at a stable URL per arch
    local download_url
    if [ "$DEB_ARCH" == "amd64" ]; then
        download_url="https://download.anydesk.com/linux/anydesk_6.4.0-1_amd64.deb"
    elif [ "$DEB_ARCH" == "arm64" ]; then
        download_url="https://download.anydesk.com/linux/anydesk_6.4.0-1_arm64.deb"
    else
        log_warning "Unsupported architecture ($DEB_ARCH) for AnyDesk."
        return 1
    fi

    # Try latest generic URL first (resolves to newest), fall back to versioned
    if retry_curl_download "https://download.anydesk.com/linux/anydesk_${DEB_ARCH}.deb" "$temp_file" "Downloading AnyDesk (latest)"; then
        log_info "Got latest AnyDesk build"
    elif retry_curl_download "$download_url" "$temp_file" "Downloading AnyDesk (fallback)"; then
        log_info "Using fallback AnyDesk build"
    else
        log_warning "AnyDesk download failed after all attempts"
        return 1
    fi

    log_info "Installing AnyDesk deb package..."
    sudo DEBIAN_FRONTEND=noninteractive dpkg -i "$temp_file" 2>/dev/null || \
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -f -y
    rm -f "$temp_file"

    log_success "AnyDesk installed successfully"
}

#===============================================================================
# 1.7 TeamViewer Installation
#===============================================================================
install_teamviewer() {
    log_step "1.7 Installing TeamViewer"

    if command_exists teamviewer || package_installed teamviewer; then
        log_warning "TeamViewer already installed, skipping..."
        return 0
    fi

    local temp_file="/tmp/teamviewer.deb"

    # TeamViewer provides latest at a stable URL per arch
    local download_url
    if [ "$DEB_ARCH" == "amd64" ]; then
        download_url="https://download.teamviewer.com/download/linux/teamviewer_amd64.deb"
    elif [ "$DEB_ARCH" == "arm64" ]; then
        download_url="https://download.teamviewer.com/download/linux/teamviewer_arm64.deb"
    else
        log_warning "Unsupported architecture ($DEB_ARCH) for TeamViewer."
        return 1
    fi

    if ! retry_curl_download "$download_url" "$temp_file" "Downloading TeamViewer"; then
        log_warning "TeamViewer download failed after all attempts"
        return 1
    fi

    log_info "Installing TeamViewer deb package..."
    sudo DEBIAN_FRONTEND=noninteractive dpkg -i "$temp_file" 2>/dev/null || \
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -f -y
    rm -f "$temp_file"

    sudo systemctl enable teamviewerd.service 2>/dev/null || true
    sudo systemctl start teamviewerd.service 2>/dev/null || true

    log_success "TeamViewer installed successfully"
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

}

#===============================================================================
# Codex CLI Installation (requires Node.js)
#===============================================================================
install_codex() {
    log_step "Installing Codex CLI (OpenAI)"

    # Ensure Node.js + npm available; install NVM Node.js if missing
    if ! command_exists npm; then
        log_info "Codex requires Node.js. Installing NVM + Node.js first..."
        install_nvm_nodejs
    fi

    # Re-source nvm so npm is available in current shell
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true

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
# Kimi Code CLI Installation (Moonshot AI - npm)
#===============================================================================
install_kimi() {
    log_step "Installing Kimi Code CLI (Moonshot AI)"

    if ! command_exists npm; then
        log_info "Kimi Code requires Node.js. Installing NVM + Node.js first..."
        install_nvm_nodejs
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true

    if command_exists kimi; then
        log_warning "Kimi Code CLI already installed, skipping..."
    else
        if retry_npm_install @moonshot-ai/kimi-code; then
            log_success "Kimi Code CLI installed successfully (run: kimi)"
        else
            log_warning "Kimi Code CLI installation skipped after 3 failed attempts"
        fi
    fi
}

#===============================================================================
# Grok CLI Installation (xAI - official installer)
#===============================================================================
install_grok() {
    log_step "Installing Grok CLI (xAI)"

    if command_exists grok; then
        log_warning "Grok CLI already installed, skipping..."
        return 0
    fi

    log_info "Installing Grok CLI via official xAI installer..."
    if curl -fsSL https://x.ai/cli/install.sh | bash; then
        # Installer drops binary into ~/.grok/bin or ~/.local/bin; make sure PATH covers it
        for gdir in "$HOME/.grok/bin" "$HOME/.local/bin"; do
            if [ -x "$gdir/grok" ]; then
                export PATH="$gdir:$PATH"
                if ! grep -q "$gdir" "$HOME/.bashrc" 2>/dev/null; then
                    echo "export PATH=\"$gdir:\$PATH\"  # Added by ubuntu-setup-script (grok)" >> "$HOME/.bashrc"
                fi
            fi
        done
        hash -r 2>/dev/null
        if command_exists grok; then
            log_success "Grok CLI installed successfully (run: grok)"
        else
            log_warning "Grok CLI installed but 'grok' not found in PATH. Try: source ~/.bashrc"
        fi
    else
        log_warning "Grok CLI installation failed"
        return 1
    fi
}

#===============================================================================
# Gemini CLI Installation (Google - npm)
#===============================================================================
install_gemini() {
    log_step "Installing Gemini CLI (Google)"

    if ! command_exists npm; then
        log_info "Gemini CLI requires Node.js. Installing NVM + Node.js first..."
        install_nvm_nodejs
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true

    if command_exists gemini; then
        log_warning "Gemini CLI already installed, skipping..."
    else
        if retry_npm_install @google/gemini-cli; then
            log_success "Gemini CLI installed successfully (run: gemini)"
        else
            log_warning "Gemini CLI installation skipped after 3 failed attempts"
        fi
    fi
}

#===============================================================================
# Qwen Code CLI Installation (Alibaba - npm)
#===============================================================================
install_qwen() {
    log_step "Installing Qwen Code CLI (Alibaba)"

    if ! command_exists npm; then
        log_info "Qwen CLI requires Node.js. Installing NVM + Node.js first..."
        install_nvm_nodejs
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true

    if command_exists qwen; then
        log_warning "Qwen CLI already installed, skipping..."
    else
        if retry_npm_install @qwen-code/qwen-code; then
            log_success "Qwen Code CLI installed successfully (run: qwen)"
        else
            log_warning "Qwen CLI installation skipped after 3 failed attempts"
        fi
    fi
}

install_glm() {
    log_step "Installing GLM Code helper (z.ai)"

    if ! command_exists npm; then
        log_info "GLM Code requires Node.js. Installing NVM + Node.js first..."
        install_nvm_nodejs
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true

    if command_exists chelper; then
        log_warning "GLM Code helper already installed, skipping..."
    else
        if retry_npm_install @z_ai/coding-helper; then
            log_success "GLM Code helper installed (run: chelper)"
            log_info "  Subscribe + get API key: https://z.ai/subscribe"
        else
            log_warning "GLM Code installation skipped after 3 failed attempts"
        fi
    fi
}

install_glm_opencode() {
    log_step "Installing GLM With OpenCode (z.ai GLM-5.2)"

    if ! command_exists npm; then
        log_info "OpenCode requires Node.js. Installing NVM + Node.js first..."
        install_nvm_nodejs
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true

    # 1) Install OpenCode (npm preferred, official installer as fallback)
    if command_exists opencode; then
        log_warning "OpenCode already installed, skipping install..."
    else
        if retry_npm_install opencode-ai; then
            log_success "OpenCode installed (run: opencode)"
        else
            log_warning "npm install failed, trying official installer..."
            if curl -fsSL https://opencode.ai/install | bash; then
                export PATH="$HOME/.opencode/bin:$PATH"
                log_success "OpenCode installed via official installer"
            else
                log_warning "GLM With OpenCode installation skipped after all attempts"
                return 0
            fi
        fi
    fi

    # 2) Preconfigure z.ai GLM-5.2 as the default model (no API key stored here)
    local oc_dir="$HOME/.config/opencode"
    local oc_cfg="$oc_dir/opencode.json"
    mkdir -p "$oc_dir"
    if [ -f "$oc_cfg" ]; then
        if grep -q '"zai"' "$oc_cfg" 2>/dev/null; then
            log_info "OpenCode already has a z.ai provider configured, leaving it as-is."
        else
            log_warning "Existing opencode.json found - not overwriting it."
            log_info "  To default to GLM-5.2, add a 'zai' provider: https://docs.z.ai/scenario-example/develop-tools/opencode"
        fi
    else
        cat > "$oc_cfg" <<'OPENCODE_JSON'
{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "zai": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Z.ai (GLM)",
      "options": {
        "baseURL": "https://api.z.ai/api/coding/paas/v4",
        "apiKey": "{env:ZAI_API_KEY}"
      },
      "models": {
        "glm-5.2": { "name": "GLM-5.2" },
        "glm-5-turbo": { "name": "GLM-5-Turbo" }
      }
    }
  },
  "model": "zai/glm-5.2"
}
OPENCODE_JSON
        log_success "OpenCode configured: default model = z.ai GLM-5.2"
    fi

    # 3) Auth is left to the user at runtime - this script stores no secret
    log_info "  Set your z.ai key (GLM Coding Plan) to start:"
    log_info "    export ZAI_API_KEY=<your-key>    (add to ~/.bashrc to persist)"
    log_info "  Subscribe + get API key: https://z.ai/subscribe"
    log_info "  Then run: opencode   (defaults to GLM-5.2; use /models to switch)"
    log_info "  Note: general (non-Coding-Plan) keys use baseURL .../api/paas/v4"
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

#===============================================================================
# jtop / jetson-stats (Jetson-only live system monitor)
#===============================================================================
install_jtop() {
    log_step "Installing jtop (jetson-stats)"

    if ! $IS_JETSON; then
        log_warning "Not a Jetson device, skipping jtop..."
        return 0
    fi

    # Needs pip3
    if ! command_exists pip3; then
        log_info "Installing python3-pip (required for jtop)..."
        sudo apt-get install -y python3-pip 2>&1 | tail -3
    fi

    if command_exists jtop; then
        log_warning "jtop already installed, upgrading..."
        sudo -H pip3 install -U jetson-stats 2>&1 | tail -3
    else
        sudo -H pip3 install jetson-stats 2>&1 | tail -3
    fi

    if command_exists jtop; then
        log_success "jtop installed. Run with: sudo jtop"
        log_info "  → service jtop start  (enables daemon for non-sudo access)"
    else
        log_warning "jtop installation could not be verified"
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
        log_warning "Browser already installed, skipping installation..."
        BROWSER_INSTALLED=true

        # Still configure search engines for Chromium (in case they're missing)
        if command_exists chromium-browser || command_exists chromium; then
            configure_chromium_search_engines
        fi

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

        # If a Chromium snap exists, remove it first so the APT version becomes
        # the only one (avoids /snap/bin/chromium vs /usr/bin/chromium confusion).
        if snap list chromium &>/dev/null; then
            log_info "Removing existing Chromium snap before installing APT version..."
            sudo snap remove --purge chromium 2>/dev/null || true
            log_success "Chromium snap removed"
        fi

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

            # Configure Chromium search engines via managed policy
            configure_chromium_search_engines

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

# Configure Chromium search engines via managed policy (Google default + DuckDuckGo)
configure_chromium_search_engines() {
    log_info "Configuring Chromium search engines (Google + DuckDuckGo)..."

    # Create policy directories for both chromium and chromium-browser
    local policy_dirs=(
        "/etc/chromium/policies/managed"
        "/etc/chromium-browser/policies/managed"
    )

    for policy_dir in "${policy_dirs[@]}"; do
        sudo mkdir -p "$policy_dir"

        sudo tee "$policy_dir/search-engines.json" > /dev/null << 'SEARCH_POLICY'
{
    "DefaultSearchProviderEnabled": true,
    "DefaultSearchProviderName": "Google",
    "DefaultSearchProviderSearchURL": "https://www.google.com/search?q={searchTerms}",
    "DefaultSearchProviderSuggestURL": "https://www.google.com/complete/search?output=chrome&q={searchTerms}",
    "DefaultSearchProviderIconURL": "https://www.google.com/favicon.ico",
    "DefaultSearchProviderKeyword": "google.com",
    "ManagedSearchEngines": [
        {
            "name": "Google",
            "keyword": "google.com",
            "search_url": "https://www.google.com/search?q={searchTerms}",
            "suggest_url": "https://www.google.com/complete/search?output=chrome&q={searchTerms}",
            "favicon_url": "https://www.google.com/favicon.ico",
            "is_default": true
        },
        {
            "name": "DuckDuckGo",
            "keyword": "duckduckgo.com",
            "search_url": "https://duckduckgo.com/?q={searchTerms}",
            "suggest_url": "https://duckduckgo.com/ac/?q={searchTerms}&type=list",
            "favicon_url": "https://duckduckgo.com/favicon.ico"
        },
        {
            "name": "Bing",
            "keyword": "bing.com",
            "search_url": "https://www.bing.com/search?q={searchTerms}",
            "suggest_url": "https://www.bing.com/osjson.aspx?query={searchTerms}",
            "favicon_url": "https://www.bing.com/favicon.ico"
        },
        {
            "name": "Yahoo",
            "keyword": "yahoo.com",
            "search_url": "https://search.yahoo.com/search?p={searchTerms}",
            "favicon_url": "https://www.yahoo.com/favicon.ico"
        }
    ]
}
SEARCH_POLICY
    done

    log_success "Chromium search engines configured (Google default + DuckDuckGo, Bing, Yahoo)"
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
    log_info "Installing VS Code Extensions for selected tools..."

    if ! command_exists code; then
        log_warning "VS Code not installed, skipping extensions"
        return
    fi

    # Helper: install one extension id (idempotent) if not already present.
    _vscode_install_ext() {
        local id="$1" label="$2"
        if code --list-extensions 2>/dev/null | grep -qix "$id"; then
            log_warning "$label extension already installed, skipping..."
        else
            log_info "Installing $label extension..."
            code --install-extension "$id" --force 2>/dev/null || \
                log_warning "Could not install $label extension"
        fi
    }

    # Each extension installs when picked in the VS Code sub-menu OR (for the
    # AI/Python ones) when the matching CLI/tool was selected (backward compat).
    { $VSCODE_SUB_CLAUDE   || $INSTALL_CLAUDE; } && _vscode_install_ext "anthropic.claude-code"       "Claude Code"
    { $VSCODE_SUB_CODEX    || $INSTALL_CODEX;  } && _vscode_install_ext "openai.chatgpt"              "Codex / ChatGPT"
    { $VSCODE_SUB_PYTHON   || $INSTALL_PYTHON; } && _vscode_install_ext "ms-python.python"            "Python"
    $VSCODE_SUB_PYLANCE   && _vscode_install_ext "ms-python.vscode-pylance"    "Pylance"
    $VSCODE_SUB_GITLENS   && _vscode_install_ext "eamodio.gitlens"             "GitLens"
    $VSCODE_SUB_PRETTIER  && _vscode_install_ext "esbenp.prettier-vscode"      "Prettier"
    $VSCODE_SUB_ESLINT    && _vscode_install_ext "dbaeumer.vscode-eslint"      "ESLint"
    $VSCODE_SUB_DOCKER    && _vscode_install_ext "ms-azuretools.vscode-docker" "Docker"
    $VSCODE_SUB_ICONS     && _vscode_install_ext "pkief.material-icon-theme"   "Material Icon Theme"

    log_success "VS Code extensions installation completed"

    # Configure VS Code user settings (only if the tweak is selected)
    if $VSCODE_SUB_SETTINGS; then
        configure_vscode_settings
    fi
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
    log_step "Tweaks"

    if ! command_exists gnome-shell; then
        log_warning "GNOME Shell not detected, skipping extensions installation..."
        return
    fi

    # Selections already made in show_gnome_submenu(), read from globals

    # 0. Update system packages first (so subsequent installs use fresh index)
    if $GNOME_SUB_UPDATE; then
        _pause_update_notifier
        log_info "Running: sudo apt update"
        sudo apt-get update
        log_info "Running: sudo apt upgrade -y"
        sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
        _resume_update_notifier
        log_success "System packages updated"
    fi

    # 1. Extensions (Extension Manager + Shell Extensions + AppIndicator)
    if $GNOME_SUB_EXTENSIONS; then
        log_info "Installing GNOME Shell Extensions packages..."

        if package_installed gnome-shell-extension-manager; then
            log_warning "Extension Manager already installed, skipping..."
        else
            sudo apt-get install -y gnome-shell-extension-manager 2>/dev/null || \
            log_warning "Extension Manager not available in repositories"
        fi

        if package_installed gnome-shell-extensions; then
            log_warning "GNOME Shell Extensions already installed, skipping..."
        else
            sudo apt-get install -y gnome-shell-extensions
            log_success "GNOME Shell Extensions installed"
        fi

        if package_installed gnome-browser-connector; then
            log_warning "GNOME Browser Connector already installed, skipping..."
        else
            sudo apt-get install -y gnome-browser-connector 2>/dev/null || \
            sudo apt-get install -y chrome-gnome-shell 2>/dev/null || \
            log_warning "Browser connector not available"
        fi

        log_info "Installing AppIndicator extension (system tray)..."
        if ! package_installed gnome-shell-extension-appindicator; then
            sudo apt-get install -y gnome-shell-extension-appindicator 2>/dev/null || \
            log_warning "AppIndicator package not available"
        fi
        force_enable_extension "appindicatorsupport@rgcjonas.gmail.com"
        force_enable_extension "ubuntu-appindicators@ubuntu.com"
        log_success "AppIndicator (system tray) enabled"

        # Tray Icons: Reloaded - for LEGACY XEmbed tray icons (RealVNC, etc.)
        # AppIndicator only handles modern StatusNotifier protocol; legacy apps
        # like RealVNC use XEmbed which needs this separate extension.
        install_tray_icons_reloaded
    fi

    # 2. GNOME Tweaks app
    if $GNOME_SUB_TWEAKS_APP; then
        if package_installed gnome-tweaks; then
            log_warning "GNOME Tweaks already installed, skipping..."
        else
            sudo apt-get install -y gnome-tweaks
            log_success "GNOME Tweaks installed"
        fi
    fi

    # 3. Dash to Dock + workspace + power + settings
    if $GNOME_SUB_DOCK; then
        configure_dash_to_dock
    fi

    # 4. Script Launcher (Nautilus right-click)
    if $GNOME_SUB_SCRIPT; then
        install_gnome_script_launcher
    fi

    # 5. Screen timeout
    if $GNOME_SUB_SCREEN; then
        log_info "Disabling screen timeout (set to never)..."
        gsettings set org.gnome.desktop.session idle-delay 0
        gsettings set org.gnome.desktop.screensaver lock-enabled false
        gsettings set org.gnome.desktop.screensaver idle-activation-enabled false
        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-ac-type 'nothing'
        gsettings set org.gnome.settings-daemon.plugins.power sleep-inactive-battery-type 'nothing'
        log_success "Screen timeout disabled (never turns off)"
    fi

    # 6. Show hidden files
    if $GNOME_SUB_HIDDEN; then
        log_info "Enabling show hidden files in file manager..."
        gsettings set org.gtk.Settings.FileChooser show-hidden true 2>/dev/null
        gsettings set org.gtk.gtk4.Settings.FileChooser show-hidden true 2>/dev/null
        dconf write /org/gtk/settings/file-chooser/show-hidden true 2>/dev/null
        dconf write /org/gtk/gtk4/settings/file-chooser/show-hidden true 2>/dev/null
        gsettings set org.gnome.nautilus.preferences show-hidden-files true 2>/dev/null
        log_success "Show hidden files enabled"
    fi

    # 7. English language
    if $GNOME_SUB_ENGLISH; then
        log_info "Setting system language to English (US)..."
        sudo apt-get install -y language-pack-en language-pack-en-base language-pack-gnome-en language-pack-gnome-en-base 2>/dev/null || true
        sudo locale-gen en_US.UTF-8 2>/dev/null || true
        sudo update-locale \
            LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8 \
            LC_CTYPE=en_US.UTF-8 LC_NUMERIC=en_US.UTF-8 LC_TIME=en_US.UTF-8 \
            LC_COLLATE=en_US.UTF-8 LC_MONETARY=en_US.UTF-8 LC_MESSAGES=en_US.UTF-8 \
            LC_PAPER=en_US.UTF-8 LC_NAME=en_US.UTF-8 LC_ADDRESS=en_US.UTF-8 \
            LC_TELEPHONE=en_US.UTF-8 LC_MEASUREMENT=en_US.UTF-8 LC_IDENTIFICATION=en_US.UTF-8 2>/dev/null || true
        sudo localectl set-locale LANG=en_US.UTF-8 LANGUAGE=en_US:en 2>/dev/null || true
        dconf write /system/locale/region "'en_US.UTF-8'" 2>/dev/null || true
        gsettings set org.gnome.system.locale region 'en_US.UTF-8' 2>/dev/null || true
        local current_user
        current_user=$(whoami)
        local accounts_file="/var/lib/AccountsService/users/$current_user"
        if [ -f "$accounts_file" ]; then
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
        export LANG=en_US.UTF-8
        export LANGUAGE=en_US:en
        export LC_ALL=en_US.UTF-8
        log_success "System language set to English (US)"
    fi

    # 8. Keyboard layouts
    if $GNOME_SUB_KB_TR && $GNOME_SUB_KB_EN; then
        log_info "Setting keyboard layouts: Turkish Q + English (US)..."
        gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'tr'), ('xkb', 'us')]" 2>/dev/null || true
        sudo localectl set-x11-keymap tr,us pc105 "" "" 2>/dev/null || true
        log_success "Keyboard layouts set: Turkish Q + English (US)"
    elif $GNOME_SUB_KB_TR; then
        log_info "Setting keyboard layout: Turkish Q..."
        gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'tr')]" 2>/dev/null || true
        sudo localectl set-x11-keymap tr pc105 "" "" 2>/dev/null || true
        log_success "Keyboard layout set: Turkish Q"
    elif $GNOME_SUB_KB_EN; then
        log_info "Setting keyboard layout: English (US)..."
        gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us')]" 2>/dev/null || true
        sudo localectl set-x11-keymap us pc105 "" "" 2>/dev/null || true
        log_success "Keyboard layout set: English (US)"
    fi

    # 9. Disable Wayland
    if $GNOME_SUB_WAYLAND; then
        disable_wayland
    fi

    # 10. OpenSSH Server
    if $GNOME_SUB_SSH; then
        enable_ssh_server
    fi

    # 11. CLI Aliases
    if $GNOME_SUB_ALIASES; then
        setup_cli_shortcuts
    fi

    # 12. Virtual Screen 1080p
    if $GNOME_SUB_VSCREEN; then
        setup_virtual_screen
    fi

    # 13. GDM Auto-Login
    if $GNOME_SUB_AUTOLOGIN; then
        enable_autologin
    fi

    # 14. Hostname change (uses value collected at confirm time)
    if $GNOME_SUB_HOSTNAME && [ -n "$NEW_HOSTNAME" ]; then
        log_info "Setting hostname to: $NEW_HOSTNAME"
        sudo hostnamectl set-hostname "$NEW_HOSTNAME" 2>/dev/null || true
        sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$NEW_HOSTNAME/" /etc/hosts 2>/dev/null || true
        log_success "Hostname set to: $NEW_HOSTNAME (takes effect on next login)"
    fi

    # 15. IBus Leak Fix - disable ibus-daemon, use XKB only
    if $GNOME_SUB_NO_IBUS; then
        log_info "Disabling ibus-daemon (XKB-only mode)..."
        # Ensure xkb-only sources are set (covers both TR/EN if either selected,
        # otherwise leave whatever the user has)
        local _src
        _src=$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null)
        if [ -z "$_src" ] || [ "$_src" = "@a(ss) []" ]; then
            gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'tr'), ('xkb', 'us')]" 2>/dev/null || true
        fi
        # Mask the user systemd unit so ibus-daemon never starts again
        systemctl --user mask org.freedesktop.IBus.session.GNOME 2>/dev/null || true
        # Kill any currently running ibus-daemon
        pkill -f ibus-daemon 2>/dev/null || true
        log_success "IBus disabled. TR/EN keyboard still switchable with Super+Space."
        log_info "  Note: Chinese/Japanese/Korean IME won't work, but you don't use them."
    fi

    # 16. Activate Apport - install + enable Ubuntu crash reporting
    if $GNOME_SUB_APPORT; then
        log_info "Activating Apport (crash reporting)..."
        if ! package_installed apport; then
            sudo apt-get install -y apport apport-gtk 2>&1 | tail -3
        fi
        # Enable in /etc/default/apport
        if [ -f /etc/default/apport ]; then
            sudo sed -i 's/^enabled=.*/enabled=1/' /etc/default/apport
        fi
        sudo systemctl enable apport.service 2>/dev/null || true
        sudo systemctl start apport.service 2>/dev/null || true
        log_success "Apport enabled and started"
    fi

    # 18. Install Cheese (camera app)
    if $GNOME_SUB_CHEESE; then
        log_info "Installing Cheese (webcam app)..."
        _pause_update_notifier
        sudo apt-get install -y --no-install-recommends cheese 2>&1 | tail -3
        _resume_update_notifier
        log_success "Cheese installed"
    fi

    # 19. Cleanup period: default 365 days (1 year), or 730 (2 years) if 2Y selected.
    # Always applied when Tweaks runs so the system baseline is 1 year, not 30 days.
    local _cleanup_age=365
    $GNOME_SUB_CLEANUP2Y && _cleanup_age=730
    log_info "Setting auto-cleanup period to $_cleanup_age days..."
    gsettings set org.gnome.desktop.privacy old-files-age "$_cleanup_age" 2>/dev/null || true
    gsettings set org.gnome.desktop.privacy remove-old-temp-files true 2>/dev/null || true
    gsettings set org.gnome.desktop.privacy remove-old-trash-files true 2>/dev/null || true
    log_success "Cleanup period set to $_cleanup_age days"


    log_success "GNOME Tweaks setup completed"
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
# Tray Icons: Reloaded - Legacy XEmbed tray icon support (RealVNC, etc.)
#===============================================================================
install_tray_icons_reloaded() {
    log_info "Installing Tray Icons: Reloaded extension (for RealVNC legacy tray)..."

    local ext_uuid="trayIconsReloaded@selfmade.pl"
    local ext_dir="$HOME/.local/share/gnome-shell/extensions/$ext_uuid"

    if [ -d "$ext_dir" ]; then
        log_info "Tray Icons: Reloaded already installed"
        force_enable_extension "$ext_uuid"
        return 0
    fi

    local gnome_ver
    gnome_ver=$(gnome-shell --version 2>/dev/null | awk '{print $3}' | cut -d. -f1)

    # Query extensions.gnome.org API for compatible version
    local ext_info
    ext_info=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${ext_uuid}&shell_version=${gnome_ver}" 2>/dev/null)

    if [ -z "$ext_info" ]; then
        log_warning "Could not query extensions.gnome.org for Tray Icons: Reloaded"
        return 1
    fi

    # Extract version pk (download URL is built from pk for trayIconsReloaded)
    local version_pk
    version_pk=$(echo "$ext_info" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for ver, info in data.get('shell_version_map', {}).items():
    print(info.get('pk', ''))
    break
" 2>/dev/null)

    if [ -z "$version_pk" ]; then
        log_warning "No compatible Tray Icons: Reloaded version for GNOME $gnome_ver"
        return 1
    fi

    local download_url="https://extensions.gnome.org/download-extension/${ext_uuid}.shell-extension.zip?version_tag=${version_pk}"
    local zip_file="/tmp/tray-icons-reloaded.zip"
    if ! curl -fsSL -o "$zip_file" "$download_url" 2>/dev/null; then
        log_warning "Failed to download Tray Icons: Reloaded"
        return 1
    fi

    # Manual extract (gnome-extensions install requires running shell with matching DBus)
    mkdir -p "$ext_dir"
    unzip -o "$zip_file" -d "$ext_dir" > /dev/null 2>&1
    chmod -R u+rwX,g+rX,o+rX "$ext_dir"
    if [ -d "$ext_dir/schemas" ] && command_exists glib-compile-schemas; then
        glib-compile-schemas "$ext_dir/schemas/" 2>/dev/null
    fi
    rm -f "$zip_file"

    log_success "Tray Icons: Reloaded installed"
    force_enable_extension "$ext_uuid"
    log_info "Tray Icons: Reloaded enabled (RealVNC notification icon appears after logout/login)"
}

#===============================================================================
# Script Launcher GNOME Extension (from extensions.gnome.org)
#===============================================================================
install_gnome_script_launcher() {
    log_info "Installing Script Launcher GNOME extension (extensions.gnome.org)..."

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
    local temp_zip="/tmp/script-launcher.zip"

    # Resolve the compatible version from extensions.gnome.org (same method as
    # install_tray_icons_reloaded): info API -> shell_version_map -> pk -> version_tag
    local ext_info version_pk
    ext_info=$(curl -fsSL "https://extensions.gnome.org/extension-info/?uuid=${ext_uuid}&shell_version=${gnome_version}" 2>/dev/null)
    version_pk=$(echo "$ext_info" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for ver, info in data.get('shell_version_map', {}).items():
    print(info.get('pk', ''))
    break
" 2>/dev/null)
    if [ -z "$version_pk" ]; then
        log_warning "No compatible Script Launcher version for GNOME $gnome_version, skipping..."
        return
    fi
    local zip_url="https://extensions.gnome.org/download-extension/${ext_uuid}.shell-extension.zip?version_tag=${version_pk}"

    # Check if already installed
    if [ -d "$ext_dir" ]; then
        log_info "Script Launcher already installed, updating..."
        rm -rf "$ext_dir"
    fi

    # Download latest release
    if ! retry_curl_download "$zip_url" "$temp_zip" "Downloading Script Launcher from extensions.gnome.org"; then
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

    # Set power profile (performance if available, otherwise balanced)
    if command_exists powerprofilesctl; then
        if powerprofilesctl set performance 2>/dev/null; then
            log_success "Power profile set to Performance"
        else
            powerprofilesctl set balanced 2>/dev/null || true
            log_success "Power profile set to Balanced (performance not available)"
        fi
    fi
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
# GDM Auto-Login - Required for VNC tray icon to appear on headless systems
#===============================================================================
enable_autologin() {
    log_info "Enabling GDM auto-login (required for VNC notification tray icon)..."

    local target_user="${SUDO_USER:-$USER}"
    if [ -z "$target_user" ] || [ "$target_user" = "root" ]; then
        target_user=$(logname 2>/dev/null || whoami)
    fi
    if [ -z "$target_user" ] || [ "$target_user" = "root" ]; then
        log_warning "Could not determine target user for auto-login, skipping..."
        return
    fi

    local gdm_config="/etc/gdm3/custom.conf"
    if [ ! -f "$gdm_config" ]; then
        log_warning "GDM config not found ($gdm_config), skipping auto-login setup"
        return
    fi

    # Backup once
    if [ ! -f "${gdm_config}.before-autologin.bak" ]; then
        sudo cp "$gdm_config" "${gdm_config}.before-autologin.bak" 2>/dev/null || true
    fi

    # Use python for safe ini editing
    sudo python3 << PYEOF
import configparser
config = configparser.ConfigParser()
config.optionxform = str  # preserve case
config.read('$gdm_config')
if 'daemon' not in config:
    config['daemon'] = {}
config['daemon']['AutomaticLoginEnable'] = 'true'
config['daemon']['AutomaticLogin'] = '$target_user'
with open('$gdm_config', 'w') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

    log_success "GDM auto-login enabled for user: $target_user (GUI starts on boot → VNC tray icon appears)"
}

disable_autologin() {
    log_info "Disabling GDM auto-login..."

    local gdm_config="/etc/gdm3/custom.conf"
    if [ ! -f "$gdm_config" ]; then
        log_info "GDM config not found, nothing to disable"
        return
    fi

    sudo python3 << PYEOF
import configparser
config = configparser.ConfigParser()
config.optionxform = str
config.read('$gdm_config')
if 'daemon' in config:
    config['daemon'].pop('AutomaticLoginEnable', None)
    config['daemon'].pop('AutomaticLogin', None)
with open('$gdm_config', 'w') as f:
    config.write(f, space_around_delimiters=False)
PYEOF

    log_success "GDM auto-login disabled"
}

autologin_enabled() {
    grep -q "^AutomaticLoginEnable[[:space:]]*=[[:space:]]*true" /etc/gdm3/custom.conf 2>/dev/null
}

#===============================================================================
# Virtual Screen Setup (1920x1080) - For headless / VNC / RDP usage
#===============================================================================
setup_virtual_screen() {
    log_info "Setting up virtual screen 1920x1080..."

    local backup_date
    backup_date=$(date +%Y%m%d_%H%M%S)

    if $IS_JETSON; then
        # Jetson NVIDIA Tegra method: use xorg.conf with virtual screen
        log_info "Detected Jetson - using NVIDIA Tegra xorg.conf method"

        # Backup existing xorg.conf
        if [ -f /etc/X11/xorg.conf ] && ! grep -q "Virtual1080p" /etc/X11/xorg.conf 2>/dev/null; then
            sudo cp /etc/X11/xorg.conf "/etc/X11/xorg.conf.before-virtual1080p.${backup_date}" 2>/dev/null || true
        fi

        sudo tee /etc/X11/xorg.conf > /dev/null << 'XORGEOF'
# 1920x1080 virtual display for headless Jetson (NVIDIA Tegra)

Section "ServerLayout"
    Identifier "Layout0"
    Screen 0 "Screen0"
EndSection

Section "Module"
    Disable     "dri"
    SubSection  "extmod"
        Option  "omit xfree86-dga"
    EndSubSection
EndSection

Section "Monitor"
    Identifier "Monitor0"
    VendorName "Unknown"
    ModelName  "Virtual1080p"
    HorizSync 28.0 - 80.0
    VertRefresh 48.0 - 75.0
    Modeline "1920x1080" 148.50  1920 2008 2052 2200  1080 1084 1089 1125 +hsync +vsync
    Option "DPMS"
EndSection

Section "Device"
    Identifier  "Tegra0"
    Driver      "nvidia"
    Option      "AllowEmptyInitialConfiguration" "true"
    Option      "ConnectedMonitor" "DP-0"
    Option      "ModeValidation" "DP-0: AllowNonEdidModes, NoEdidModes, NoVesaModes"
    Option      "UseEDID" "false"
EndSection

Section "Screen"
    Identifier "Screen0"
    Device     "Tegra0"
    Monitor    "Monitor0"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1920x1080"
        Virtual 1920 1080
    EndSubSection
EndSection
XORGEOF

        # Autostart script to force resolution after login
        sudo tee /etc/xdg/autostart/jetson-1080p.desktop > /dev/null << 'AUTOEOF'
[Desktop Entry]
Type=Application
Name=Jetson 1080p Resolution
Exec=sh -c "xrandr --output DP-0 --mode 1920x1080 2>/dev/null || xrandr --output HDMI-0 --mode 1920x1080 2>/dev/null || true"
NoDisplay=true
X-GNOME-Autostart-enabled=true
AUTOEOF

        log_success "Jetson virtual screen 1920x1080 configured (restart GDM or reboot to apply)"

    else
        # x64 and non-Jetson ARM: use xrandr autostart method
        log_info "Using xrandr autostart method (universal)"

        sudo tee /etc/xdg/autostart/virtual-1080p.desktop > /dev/null << 'AUTOEOF'
[Desktop Entry]
Type=Application
Name=Virtual 1080p Resolution
Exec=sh -c "PRIMARY=$(xrandr | awk '/ connected/ {print $1; exit}'); if [ -n \"$PRIMARY\" ]; then if ! xrandr | grep -q '1920x1080'; then MODELINE=$(cvt 1920 1080 60 | grep Modeline | sed 's/Modeline //; s/\"1920x1080_60.00\"/1920x1080/'); xrandr --newmode $MODELINE 2>/dev/null; xrandr --addmode \"$PRIMARY\" 1920x1080 2>/dev/null; fi; xrandr --output \"$PRIMARY\" --mode 1920x1080 2>/dev/null || true; fi"
NoDisplay=true
X-GNOME-Autostart-enabled=true
AUTOEOF

        log_success "Virtual screen 1920x1080 configured via xrandr autostart"
    fi
}

remove_virtual_screen() {
    log_info "Removing virtual screen configuration..."

    local restored=false

    # Restore NVIDIA Tegra default xorg.conf if our virtual config exists
    if [ -f /etc/X11/xorg.conf ] && grep -q "Virtual1080p" /etc/X11/xorg.conf 2>/dev/null; then
        local backup_date
        backup_date=$(date +%Y%m%d)
        sudo cp /etc/X11/xorg.conf "/etc/X11/xorg.conf.virtual1080p.bak.${backup_date}" 2>/dev/null || true

        # Restore from .orig if exists, otherwise write NVIDIA default minimal config
        if [ -f /etc/X11/xorg.conf.orig ]; then
            sudo cp /etc/X11/xorg.conf.orig /etc/X11/xorg.conf
            log_info "Restored /etc/X11/xorg.conf from .orig"
        else
            sudo tee /etc/X11/xorg.conf > /dev/null << 'XORGORIG'
# NVIDIA Tegra minimal configuration

Section "Module"
    Disable     "dri"
    SubSection  "extmod"
        Option  "omit xfree86-dga"
    EndSubSection
EndSection

Section "Device"
    Identifier  "Tegra0"
    Driver      "nvidia"
    Option      "AllowEmptyInitialConfiguration" "true"
EndSection
XORGORIG
            log_info "Restored /etc/X11/xorg.conf to NVIDIA minimal default"
        fi
        restored=true
    fi

    # Remove autostart entries
    if [ -f /etc/xdg/autostart/jetson-1080p.desktop ]; then
        sudo rm -f /etc/xdg/autostart/jetson-1080p.desktop
        log_info "Removed /etc/xdg/autostart/jetson-1080p.desktop"
        restored=true
    fi
    if [ -f /etc/xdg/autostart/virtual-1080p.desktop ]; then
        sudo rm -f /etc/xdg/autostart/virtual-1080p.desktop
        log_info "Removed /etc/xdg/autostart/virtual-1080p.desktop"
        restored=true
    fi

    if $restored; then
        log_success "Virtual screen configuration removed (restart GDM or reboot to apply)"
    else
        log_info "No virtual screen configuration found, nothing to remove"
    fi
}

virtual_screen_installed() {
    if [ -f /etc/X11/xorg.conf ] && grep -q "Virtual1080p" /etc/X11/xorg.conf 2>/dev/null; then
        return 0
    fi
    if [ -f /etc/xdg/autostart/jetson-1080p.desktop ] || [ -f /etc/xdg/autostart/virtual-1080p.desktop ]; then
        return 0
    fi
    return 1
}

#===============================================================================
# CLI Shortcuts: Bash Aliases + Nautilus Right-Click Actions
#===============================================================================
setup_cli_shortcuts() {
    log_info "Setting up CLI shortcuts and Nautilus context menu actions..."

    local bashrc="$HOME/.bashrc"

    # --- Bash Aliases ---
    # Remove old versions (both legacy single-line and marker-based)
    sed -i '/^alias claude-skip=/d' "$bashrc" 2>/dev/null
    sed -i '/^alias ccskip=/d' "$bashrc" 2>/dev/null
    sed -i '/^alias codex-skip=/d' "$bashrc" 2>/dev/null
    sed -i '/^alias cxskip=/d' "$bashrc" 2>/dev/null
    sed -i '/^# Claude Code aliases/d' "$bashrc" 2>/dev/null
    sed -i '/^# Codex aliases/d' "$bashrc" 2>/dev/null
    sed -i '/^# BEGIN smai-aliases/,/^# END smai-aliases/d' "$bashrc" 2>/dev/null

    # Add aliases only for selected tools (Claude / Codex CLIs)
    # Detect what's actually selected/installed (skip aliases for things not present)
    local _claude_avail=false _codex_avail=false
    if $INSTALL_CLAUDE || command_exists claude; then _claude_avail=true; fi
    if $INSTALL_CODEX  || command_exists codex;  then _codex_avail=true;  fi

    {
        echo ""
        echo "# BEGIN smai-aliases"
        if $_claude_avail; then
            echo "alias claude-skip='claude --dangerously-skip-permissions --effort max'"
            echo "alias ccskip='claude --dangerously-skip-permissions --effort max'"
        fi
        if $_codex_avail; then
            echo "alias codex-skip='codex --sandbox danger-full-access -c model_reasoning_effort=\"xhigh\"'"
            echo "alias cxskip='codex --sandbox danger-full-access -c model_reasoning_effort=\"xhigh\"'"
        fi
        echo "# END smai-aliases"
    } >> "$bashrc"

    local _alias_list=""
    if $_claude_avail; then _alias_list+="claude-skip, ccskip"; fi
    if $_codex_avail; then
        [ -n "$_alias_list" ] && _alias_list+=", "
        _alias_list+="codex-skip, cxskip"
    fi
    if [ -n "$_alias_list" ]; then
        log_success "Aliases added: $_alias_list"
    else
        log_info "No aliases added (neither Claude Code nor Codex selected/installed)"
    fi

    # --- npm/yarn/pnpm package.json scripts tab-completion ---
    # Clean up any leftover node-scripts-completion from previous versions
    sed -i '/^# BEGIN node-scripts-completion/,/^# END node-scripts-completion/d' "$bashrc" 2>/dev/null
    sed -i '/^# Node package scripts tab-completion/,/^complete -F _node_package_scripts_complete pnpm$/d' "$bashrc" 2>/dev/null
    sed -i '/COMP_WORDS\|COMPREPLY\|compgen\|local cur prev scripts\|_node_package_scripts_complete/d' "$bashrc" 2>/dev/null

    # Load aliases into current shell session immediately
    source "$bashrc" 2>/dev/null || true
    log_info "Aliases and completions loaded into current session"

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


def _have(cmd):
    """Return True if cmd is available on PATH (check at runtime)."""
    import shutil
    return shutil.which(cmd) is not None


def _build_actions():
    """Only include menu items for tools actually installed."""
    actions = []
    if _have('claude'):
        actions.append(('SmaiOpenClaude', 'Open in Claude Code', CLAUDE_CMD, True))
    if _have('codex'):
        actions.append(('SmaiOpenCodex',  'Open in Codex CLI',   CODEX_CMD,  True))
    if _have('code'):
        actions.append(('SmaiOpenVscode', 'Open in VS Code',     'code',     False))
    return tuple(actions)


ACTIONS = _build_actions()


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
    if package_installed realvnc-rvncconnect || \
       package_installed realvnc-connect || \
       package_installed realvnc-vnc-server || \
       command_exists vncserver-x11 || \
       command_exists vncserver || \
       [ -f /usr/bin/vncserver-x11 ] || \
       [ -d /usr/share/vnc ]; then
        log_warning "RealVNC already installed."
        read -p "Reinstall from scratch? (y/n): " reinstall_choice < /dev/tty
        if [[ "$reinstall_choice" =~ ^[Yy]$ ]]; then
            log_info "Removing existing RealVNC installation..."
            sudo apt-get remove -y realvnc-rvncconnect realvnc-connect realvnc-vnc-server 2>/dev/null
            sudo rm -f /etc/apt/sources.list.d/*realvnc* /etc/apt/sources.list.d/*vnc*
            sudo rm -f /usr/share/keyrings/*realvnc* /etc/apt/trusted.gpg.d/*realvnc*
            sudo rm -rf /usr/share/vnc /usr/bin/vncserver-x11 /usr/bin/vncserver
            log_success "Old RealVNC removed, reinstalling..."
        else
            log_info "Keeping existing installation, skipping..."
            disable_wayland
            return
        fi
    fi

    local temp_file="/tmp/realvnc-connect.deb"
    local download_url

    if [ "$DEB_ARCH" == "amd64" ]; then
        if [ "$OS_VERSION" = "22.04" ] || [ "$OS_CODENAME" = "jammy" ]; then
            download_url="https://downloads.realvnc.com/download/file/vnc.files/VNC-Server-7.13.1-Linux-x64.deb"
            log_info "Ubuntu 22.04 (x64) - installing RealVNC 7.13.1..."
        else
            download_url="https://downloads.realvnc.com/download/file/realvnc-connect/RealVNC-Connect-8.2.2-Linux-x64.deb"
        fi
    elif [ "$DEB_ARCH" == "arm64" ]; then
        if [ "$OS_VERSION" = "22.04" ] || [ "$OS_CODENAME" = "jammy" ]; then
            download_url="https://downloads.realvnc.com/download/file/vnc.files/VNC-Server-7.13.1-Linux-ARM64.deb"
            log_info "Ubuntu 22.04 (ARM64) - installing RealVNC 7.13.1..."
        else
            download_url="https://downloads.realvnc.com/download/file/vnc.files/VNC-Server-7.17.0-Linux-ARM64.deb"
            log_info "ARM64 - installing RealVNC 7.17.0..."
        fi
    elif [ "$DEB_ARCH" == "armhf" ]; then
        download_url="https://downloads.realvnc.com/download/file/vnc.files/VNC-Server-7.17.0-Linux-ARM.deb"
        log_info "ARM (armhf) - installing RealVNC 7.17.0..."
    else
        log_warning "Unsupported architecture ($DEB_ARCH) for RealVNC. Install manually from https://www.realvnc.com/en/connect/download/vnc/"
        return 1
    fi

    if ! retry_curl_download "$download_url" "$temp_file" "Downloading RealVNC Connect deb"; then
        log_warning "RealVNC installation skipped after 3 failed attempts. Install manually from https://www.realvnc.com/en/connect/download/vnc/"
    else
        log_info "Installing RealVNC Connect..."

        if [ "$OS_VERSION" = "22.04" ] || [ "$OS_CODENAME" = "jammy" ]; then
            sudo apt-get install -y libxtst6 libxdamage1 policykit-1 2>/dev/null || true
            sudo DEBIAN_FRONTEND=noninteractive dpkg -i "$temp_file" 2>/dev/null || \
                sudo DEBIAN_FRONTEND=noninteractive apt-get install -f -y --no-upgrade
            sudo DEBIAN_FRONTEND=noninteractive dpkg -i --force-downgrade "$temp_file" 2>/dev/null || true
            sudo apt-mark hold realvnc-vnc-server realvnc-connect realvnc-vnc-viewer 2>/dev/null || true
            log_info "RealVNC version held (apt-mark hold) to prevent upgrade"
        else
            sudo DEBIAN_FRONTEND=noninteractive dpkg -i "$temp_file" 2>/dev/null || \
                sudo DEBIAN_FRONTEND=noninteractive apt-get install -f -y
        fi
        rm -f "$temp_file"

        # Enable and start VNC service (7.x: vncserver-x11-serviced, 8.x: rvncserver-x11-serviced)
        sudo systemctl enable vncserver-x11-serviced.service 2>/dev/null || true
        sudo systemctl start vncserver-x11-serviced.service 2>/dev/null || true
        sudo systemctl enable rvncserver-x11-serviced.service 2>/dev/null || true
        sudo systemctl start rvncserver-x11-serviced.service 2>/dev/null || true

        log_success "RealVNC Connect installed successfully"
    fi

    # Disable Wayland for VNC compatibility
    disable_wayland

    # Virtual screen and auto-login are NOT auto-applied here.
    # They are opt-in via the GNOME Tweaks sub-menu (selected by default there).
    # On Jetson headless they are needed; on normal PCs with monitor they aren't.
    if $IS_JETSON && (! virtual_screen_installed || ! autologin_enabled); then
        log_info "Jetson detected: if you're headless (no monitor), also select GNOME Tweaks"
        log_info "  → 'Virtual Screen 1080p' and 'GDM Auto-Login' to get tray icon working."
    fi
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
# Debloat - Remove unwanted preinstalled bloatware apps
#===============================================================================
debloat_system() {
    log_step "Debloat - Removing Bloatware"

    local total_pkgs=${#DEBLOAT_SELECTED_PKGS[@]}
    if [ "$total_pkgs" -eq 0 ]; then
        log_info "No packages selected for removal, skipping debloat."
        return 0
    fi

    log_info "Removing $total_pkgs selected bloatware package(s)..."
    local removed_count=0
    local bi
    for ((bi=0; bi<total_pkgs; bi++)); do
        log_info "Removing ${DEBLOAT_SELECTED_NAMES[$bi]}..."
        # Special markers handled separately (not real apt packages)
        case "${DEBLOAT_SELECTED_PKGS[$bi]}" in
            "__VSCREEN__")
                remove_virtual_screen
                ;;
            "__AUTOLOGIN__")
                disable_autologin
                ;;
            "__XRDP__")
                sudo systemctl stop xrdp xrdp-sesman 2>/dev/null || true
                sudo systemctl disable xrdp xrdp-sesman 2>/dev/null || true
                sudo apt-get remove -y xrdp 2>/dev/null || true
                log_info "xrdp (RDP server) removed"
                ;;
            "__CLAUDE__")
                # 1) Binary + ~/.claude dir + PATH entries
                rm -f "$HOME/.claude/bin/claude" "$HOME/.local/bin/claude" 2>/dev/null
                rm -rf "$HOME/.claude" 2>/dev/null
                command_exists npm && npm uninstall -g @anthropic-ai/claude-code 2>/dev/null || true
                for rcfile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
                    [ -f "$rcfile" ] && sed -i '/\.claude\/bin/d; /# Added by Claude/d' "$rcfile" 2>/dev/null
                done
                # 2) Bash aliases (claude-skip, ccskip)
                sed -i '/^alias claude-skip=/d; /^alias ccskip=/d' "$HOME/.bashrc" 2>/dev/null
                # 3) VS Code extension
                if command_exists code; then
                    code --uninstall-extension anthropic.claude-code 2>/dev/null || true
                    code --uninstall-extension saoudrizwan.claude-dev 2>/dev/null || true
                fi
                # 4) Context menu — auto-hides at runtime via shutil.which('claude')
                log_info "Claude Code CLI removed (binary, aliases, VS Code extension)"
                ;;
            "__CODEX__")
                # 1) npm uninstall
                command_exists npm && npm uninstall -g @openai/codex 2>/dev/null || true
                # 2) Bash aliases (codex-skip, cxskip)
                sed -i '/^alias codex-skip=/d; /^alias cxskip=/d' "$HOME/.bashrc" 2>/dev/null
                # 3) VS Code extension
                if command_exists code; then
                    code --uninstall-extension openai.chatgpt 2>/dev/null || true
                    code --uninstall-extension gencay.vscode-chatgpt 2>/dev/null || true
                fi
                # 4) Context menu — auto-hides at runtime via shutil.which('codex')
                log_info "Codex CLI removed (npm package, aliases, VS Code extension)"
                ;;
            "__REALVNC__")
                sudo systemctl stop vncserver-x11-serviced rvncserver-x11-serviced 2>/dev/null || true
                sudo systemctl disable vncserver-x11-serviced rvncserver-x11-serviced 2>/dev/null || true
                sudo apt-mark unhold realvnc-vnc-server realvnc-connect realvnc-rvncconnect realvnc-vnc-viewer 2>/dev/null || true
                sudo apt-get remove -y realvnc-vnc-server realvnc-connect realvnc-rvncconnect realvnc-vnc-viewer 2>/dev/null || true
                log_info "RealVNC removed"
                ;;
            "__NVM__")
                rm -rf "$HOME/.nvm" 2>/dev/null
                for rcfile in "$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.profile"; do
                    [ -f "$rcfile" ] && sed -i '/NVM_DIR/d; /nvm.sh/d; /bash_completion/d' "$rcfile" 2>/dev/null
                done
                log_info "NVM + Node.js removed (~/.nvm deleted)"
                ;;
            "__CHROMIUM_SNAP__")
                sudo snap remove --purge chromium 2>/dev/null || true
                log_info "Chromium snap removed"
                ;;
            "__POSTMAN_SNAP__")
                sudo snap remove --purge postman 2>/dev/null || true
                log_info "Postman snap removed"
                ;;
            "__SNAP__:"*)
                local _snap_to_remove="${DEBLOAT_SELECTED_PKGS[$bi]#__SNAP__:}"
                sudo snap remove --purge "$_snap_to_remove" 2>/dev/null || true
                log_info "Snap '$_snap_to_remove' removed"
                ;;
            "__JTOP__")
                # Stop the jtop systemd service if it exists
                sudo systemctl stop jtop 2>/dev/null || true
                sudo systemctl disable jtop 2>/dev/null || true
                sudo -H pip3 uninstall -y jetson-stats 2>/dev/null || true
                log_info "jtop / jetson-stats removed"
                ;;
            "__FORCE__:"*)
                # Force-remove ONLY this package using dpkg, leaving any
                # dependent packages in a broken-deps state but installed.
                # Used for packages whose reverse-deps include desktop core
                # (e.g. cheese ← libcheese-gtk25 ← gnome-control-center).
                local _force_pkg="${DEBLOAT_SELECTED_PKGS[$bi]#__FORCE__:}"
                log_info "Force-removing '$_force_pkg' (dependents stay installed)..."
                sudo dpkg --force-depends --remove "$_force_pkg" 2>/dev/null || true
                log_success "'$_force_pkg' removed. apt may warn about broken deps - harmless."
                ;;
            "__DTD_RESTORE__")
                if [ -f "$BACKUP_DIR/gnome-backup/dash-to-dock.dconf" ]; then
                    log_info "Restoring Dash to Dock settings from backup..."
                    dconf load /org/gnome/shell/extensions/dash-to-dock/ < "$BACKUP_DIR/gnome-backup/dash-to-dock.dconf"
                    log_success "Dash to Dock restored. Log out / shell restart for full effect."
                else
                    log_warning "No backup found at $BACKUP_DIR/gnome-backup/dash-to-dock.dconf"
                fi
                ;;
            "__SCRIPT_LAUNCHER__")
                local _sl_uuid="script-launcher@enginyilmaaz"
                gnome-extensions disable "$_sl_uuid" 2>/dev/null || true
                rm -rf "$HOME/.local/share/gnome-shell/extensions/$_sl_uuid"
                # Remove from enabled-extensions list
                local _en
                _en=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null)
                if [ -n "$_en" ] && [ "$_en" != "@as []" ]; then
                    local _new
                    _new=$(echo "$_en" | sed "s/, *'$_sl_uuid'//g; s/'$_sl_uuid', *//g; s/'$_sl_uuid'//g; s/\[ *,/[/; s/, *\]/]/")
                    gsettings set org.gnome.shell enabled-extensions "$_new" 2>/dev/null || true
                fi
                log_info "Script Launcher GNOME extension removed"
                ;;
            "__EXTENSIONS_STACK__")
                # 1) Remove the apt packages
                sudo apt-get remove -y gnome-shell-extension-manager gnome-shell-extensions \
                    gnome-shell-extension-appindicator gnome-browser-connector 2>/dev/null || true
                # 2) Remove Tray Icons: Reloaded (third-party extension)
                rm -rf "$HOME/.local/share/gnome-shell/extensions/trayIconsReloaded@selfmade.pl"
                # 3) Clean the enabled-extensions list of related UUIDs
                local _uuids="appindicatorsupport@rgcjonas.gmail.com ubuntu-appindicators@ubuntu.com trayIconsReloaded@selfmade.pl"
                local _en _new
                _en=$(gsettings get org.gnome.shell enabled-extensions 2>/dev/null)
                if [ -n "$_en" ] && [ "$_en" != "@as []" ]; then
                    _new="$_en"
                    for _u in $_uuids; do
                        _new=$(echo "$_new" | sed "s/, *'$_u'//g; s/'$_u', *//g; s/'$_u'//g; s/\[ *,/[/; s/, *\]/]/")
                    done
                    gsettings set org.gnome.shell enabled-extensions "$_new" 2>/dev/null || true
                fi
                log_info "Extensions stack removed (Manager / Shell Extensions / AppIndicator / Tray Icons)"
                ;;
            "__XKB_DROP__:"*)
                local _drop_code="${DEBLOAT_SELECTED_PKGS[$bi]#__XKB_DROP__:}"
                log_info "Removing '$_drop_code' from GNOME keyboard layouts..."
                # Rebuild sources list without the dropped code
                local _curr _new
                _curr=$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null)
                # Use python to safely filter
                _new=$(python3 -c "
import sys, ast
s = ast.literal_eval('''$_curr''')
filtered = [t for t in s if t[1] != '$_drop_code']
print(repr(filtered).replace('[', '[').replace(']', ']'))
" 2>/dev/null)
                if [ -n "$_new" ]; then
                    gsettings set org.gnome.desktop.input-sources sources "$_new" 2>/dev/null || true
                    log_success "XKB layout '$_drop_code' removed from GNOME"
                fi
                ;;
            "__APPORT__")
                sudo systemctl stop apport.service 2>/dev/null || true
                sudo systemctl disable apport.service 2>/dev/null || true
                # Set enabled=0 in case the package is reinstalled later
                if [ -f /etc/default/apport ]; then
                    sudo sed -i 's/^enabled=.*/enabled=0/' /etc/default/apport
                fi
                sudo apt-get remove -y apport apport-gtk apport-symptoms 2>/dev/null || true
                log_info "Apport removed (re-enable via Tweaks → Activate Apport)"
                ;;
            "__SNAP_PURGE_ALL__")
                # Snapshot what we're about to nuke (for the rollback log)
                local _snap_log="$HOME/Desktop/snap-removal-$(date +%Y%m%d_%H%M%S).txt"
                mkdir -p "$HOME/Desktop" 2>/dev/null || true
                {
                    echo "SNAP REMOVAL LOG"
                    echo "Date: $(date)"
                    echo ""
                    echo "Snaps that were installed before removal:"
                    snap list 2>/dev/null
                    echo ""
                    echo "Disk usage before removal:"
                    sudo du -sh /snap /var/snap /var/lib/snapd 2>/dev/null
                    echo ""
                    echo "To restore snap functionality:"
                    echo "  sudo apt install snapd gnome-software-plugin-snap"
                    echo "  sudo systemctl enable --now snapd snapd.socket snapd.seeded"
                    echo "  # then reinstall the snaps you want (e.g. sudo snap install <name>)"
                } > "$_snap_log"
                log_info "Saved snap rollback note to: $_snap_log"

                # 1) Remove all user snaps (snap-store, postman, etc.) - in reverse install order
                log_info "Removing all user snaps..."
                while read -r _sn _; do
                    [ -z "$_sn" ] || [ "$_sn" = "Name" ] && continue
                    # skip base snaps (they have to be removed last)
                    [[ "$_sn" =~ ^(core|core18|core20|core22|core24|snapd|bare)$ ]] && continue
                    sudo snap remove --purge "$_sn" 2>/dev/null || true
                done < <(snap list 2>/dev/null | tail -n +2)

                # 2) Remove base snaps
                log_info "Removing base snaps (core / core18 / etc.)..."
                for _base in core22 core20 core18 core24 core bare snapd; do
                    sudo snap remove --purge "$_base" 2>/dev/null || true
                done

                # 3) Stop + disable services BEFORE purging the package
                log_info "Stopping snapd services..."
                sudo systemctl disable --now snapd.service snapd.socket snapd.seeded 2>/dev/null || true
                sudo apt-mark unhold snapd 2>/dev/null || true

                # 4) Purge the snapd package + GNOME software plugin
                log_info "Purging snapd package..."
                sudo apt-get purge -y snapd gnome-software-plugin-snap 2>/dev/null || true

                # 5) Clean up leftover directories
                log_info "Cleaning up /snap, /var/snap, /var/lib/snapd..."
                sudo rm -rf /snap /var/snap /var/lib/snapd "$HOME/snap" 2>/dev/null || true

                # 6) Prevent snap from being reinstalled accidentally via apt
                log_info "Adding apt preference to block snapd reinstall..."
                sudo tee /etc/apt/preferences.d/nosnap.pref > /dev/null << 'NOSNAPEOF'
Package: snapd
Pin: release a=*
Pin-Priority: -10
NOSNAPEOF

                log_success "Snap stack completely removed. Rollback note: $_snap_log"
                ;;
            *)
                # Normal apt-get remove. Truly dangerous items (Language Support
                # → kills gnome-control-center) are pre-filtered out of the
                # Debloat list, so this is safe.
                # shellcheck disable=SC2086
                sudo apt-get remove -y ${DEBLOAT_SELECTED_PKGS[$bi]} 2>/dev/null || true
                ;;
        esac
        removed_count=$((removed_count + 1))
    done
    sudo apt-get autoclean 2>/dev/null || true
    log_success "Debloat completed: $removed_count item(s) removed"
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

    echo ""

    # Helper: show status for a selected item
    # Usage: show_item FLAG "Label" check_command
    show_selected() {
        local flag="$1" label="$2" installed="$3"
        if $flag; then
            if $installed; then
                echo -e "  ${GREEN}✓${NC} $label"
            else
                echo -e "  ${RED}✗${NC} $label (failed)"
            fi
        fi
    }

    # Reload NVM for checks
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    # VNC
    # Remote Support Tools
    show_selected $INSTALL_VNC "RealVNC Connect" "$({ package_installed realvnc-rvncconnect || package_installed realvnc-connect || command_exists vncserver-x11; } && echo true || echo false)"
    show_selected $INSTALL_ANYDESK "AnyDesk" "$({ command_exists anydesk || package_installed anydesk; } && echo true || echo false)"
    show_selected $INSTALL_TEAMVIEWER "TeamViewer" "$({ command_exists teamviewer || package_installed teamviewer; } && echo true || echo false)"

    # Node.js
    if $INSTALL_NODEJS; then
        local node_ok=false
        [ -d "$HOME/.nvm" ] && command_exists node && node_ok=true
        if $node_ok; then
            echo -e "  ${GREEN}✓${NC} Node.js $(node -v) + NVM"
            command_exists yarn && echo -e "  ${GREEN}✓${NC} Yarn $(yarn -v)"
            command_exists codex && echo -e "  ${GREEN}✓${NC} Codex CLI"
        else
            echo -e "  ${RED}✗${NC} Node.js (failed)"
        fi
    fi

    # Chrome/Chromium
    if $INSTALL_CHROME; then
        if command_exists google-chrome || command_exists google-chrome-stable; then
            echo -e "  ${GREEN}✓${NC} Google Chrome"
        elif command_exists chromium-browser || command_exists chromium; then
            echo -e "  ${GREEN}✓${NC} Chromium"
        else
            echo -e "  ${RED}✗${NC} Browser (failed)"
        fi
    fi

    # VS Code
    show_selected $INSTALL_VSCODE "VS Code" "$(command_exists code && echo true || echo false)"

    # Python
    if $INSTALL_PYTHON; then
        if command_exists python3; then
            echo -e "  ${GREEN}✓${NC} Python $(python3 --version 2>&1 | cut -d' ' -f2)"
        else
            echo -e "  ${RED}✗${NC} Python (failed)"
        fi
    fi

    # Tweaks - show ONLY what was selected in this run (not all that exist)
    if $INSTALL_GNOME; then
        local any_tweak=false
        $GNOME_SUB_UPDATE     && any_tweak=true
        $GNOME_SUB_EXTENSIONS && any_tweak=true
        $GNOME_SUB_TWEAKS_APP && any_tweak=true
        $GNOME_SUB_DOCK       && any_tweak=true
        $GNOME_SUB_SCRIPT     && any_tweak=true
        $GNOME_SUB_WAYLAND    && any_tweak=true
        $GNOME_SUB_SSH        && any_tweak=true
        $GNOME_SUB_ALIASES    && any_tweak=true
        $GNOME_SUB_ENGLISH    && any_tweak=true
        $GNOME_SUB_SCREEN     && any_tweak=true
        $GNOME_SUB_HIDDEN     && any_tweak=true
        $GNOME_SUB_KB_TR      && any_tweak=true
        $GNOME_SUB_KB_EN      && any_tweak=true
        $GNOME_SUB_VSCREEN    && any_tweak=true
        $GNOME_SUB_AUTOLOGIN  && any_tweak=true
        $GNOME_SUB_HOSTNAME   && any_tweak=true
        $GNOME_SUB_NO_IBUS    && any_tweak=true
        $GNOME_SUB_APPORT     && any_tweak=true
        $GNOME_SUB_CHEESE     && any_tweak=true
        $GNOME_SUB_CLEANUP2Y && any_tweak=true

        if $any_tweak; then
            echo -e "  ${GREEN}✓${NC} Tweaks"
            $GNOME_SUB_UPDATE     && echo -e "    ${GREEN}✓${NC} Update System (apt update + upgrade)"
            $GNOME_SUB_EXTENSIONS && package_installed gnome-shell-extensions &>/dev/null && echo -e "    ${GREEN}✓${NC} Extensions (Extension Manager + AppIndicator + Tray Icons)"
            $GNOME_SUB_TWEAKS_APP && package_installed gnome-tweaks &>/dev/null         && echo -e "    ${GREEN}✓${NC} GNOME Tweaks App"
            $GNOME_SUB_DOCK       && echo -e "    ${GREEN}✓${NC} Dash to Dock"
            $GNOME_SUB_SCRIPT     && [ -d "$HOME/.local/share/gnome-shell/extensions/script-launcher@enginyilmaaz" ] && echo -e "    ${GREEN}✓${NC} Script Launcher"
            $GNOME_SUB_WAYLAND    && grep -q "^WaylandEnable=false" /etc/gdm3/custom.conf 2>/dev/null && echo -e "    ${GREEN}✓${NC} Wayland Disabled"
            $GNOME_SUB_SSH        && systemctl is-active ssh &>/dev/null                && echo -e "    ${GREEN}✓${NC} OpenSSH Server"
            $GNOME_SUB_ALIASES    && grep -q "^# BEGIN smai-aliases" "$HOME/.bashrc" 2>/dev/null && echo -e "    ${GREEN}✓${NC} CLI Aliases"
            $GNOME_SUB_ENGLISH    && echo -e "    ${GREEN}✓${NC} English Language"
            $GNOME_SUB_SCREEN     && echo -e "    ${GREEN}✓${NC} Screen Off: Never"
            $GNOME_SUB_HIDDEN     && echo -e "    ${GREEN}✓${NC} Show Hidden Files"
            $GNOME_SUB_KB_TR      && echo -e "    ${GREEN}✓${NC} Keyboard: Turkish Q"
            $GNOME_SUB_KB_EN      && echo -e "    ${GREEN}✓${NC} Keyboard: English Q"
            $GNOME_SUB_VSCREEN    && virtual_screen_installed && echo -e "    ${GREEN}✓${NC} Virtual Screen 1080p"
            $GNOME_SUB_AUTOLOGIN  && autologin_enabled        && echo -e "    ${GREEN}✓${NC} GDM Auto-Login"
            $GNOME_SUB_HOSTNAME   && [ -n "$NEW_HOSTNAME" ]   && echo -e "    ${GREEN}✓${NC} Hostname → $NEW_HOSTNAME"
            $GNOME_SUB_NO_IBUS    && echo -e "    ${GREEN}✓${NC} IBus disabled (XKB-only)"
            $GNOME_SUB_APPORT     && systemctl is-active apport &>/dev/null && echo -e "    ${GREEN}✓${NC} Apport activated"
            $GNOME_SUB_CHEESE     && command_exists cheese && echo -e "    ${GREEN}✓${NC} Cheese installed"
            $GNOME_SUB_CLEANUP2Y  && echo -e "    ${GREEN}✓${NC} Cleanup Period: 2 years (730 days)"
        fi
    fi

    # DBeaver
    show_selected $INSTALL_DBEAVER "DBeaver CE" "$(package_installed dbeaver-ce || command_exists dbeaver && echo true || echo false)"

    # VLC
    show_selected $INSTALL_VLC "VLC Media Player" "$(command_exists vlc && echo true || echo false)"

    # Cloudflared
    if $INSTALL_CLOUDFLARED; then
        if command_exists cloudflared; then
            echo -e "  ${GREEN}✓${NC} Cloudflared $(cloudflared --version 2>&1 | head -1 | cut -d' ' -f3)"
        else
            echo -e "  ${RED}✗${NC} Cloudflared (failed)"
        fi
    fi

    # Docker
    if $INSTALL_DOCKER; then
        if command_exists docker; then
            echo -e "  ${GREEN}✓${NC} Docker $(docker --version 2>&1 | cut -d' ' -f3 | tr -d ',')"
        else
            echo -e "  ${RED}✗${NC} Docker (failed)"
        fi
    fi

    # AI CLI Tools
    show_selected $INSTALL_CLAUDE "Claude Code" "$(command_exists claude && echo true || echo false)"
    show_selected $INSTALL_CODEX  "Codex"       "$(command_exists codex && echo true || echo false)"
    show_selected $INSTALL_KIMI   "Kimi Code"   "$(command_exists kimi && echo true || echo false)"
    show_selected $INSTALL_GROK   "Grok"        "$(command_exists grok && echo true || echo false)"
    show_selected $INSTALL_GEMINI "Gemini CLI"  "$(command_exists gemini && echo true || echo false)"
    show_selected $INSTALL_QWEN   "Qwen CLI"    "$(command_exists qwen && echo true || echo false)"
    show_selected $INSTALL_GLM    "GLM Code"    "$(command_exists chelper && echo true || echo false)"
    show_selected $INSTALL_OPENCODE "GLM With OpenCode" "$(command_exists opencode && echo true || echo false)"

    # Git & GitHub CLI
    if $INSTALL_GH; then
        if command_exists gh; then
            echo -e "  ${GREEN}✓${NC} Git & GitHub CLI $(gh --version 2>/dev/null | head -1 | awk '{print $NF}')"
        else
            echo -e "  ${RED}✗${NC} Git & GitHub CLI (failed)"
        fi
    fi

    # Postman
    show_selected $INSTALL_POSTMAN "Postman" "$(command_exists postman && echo true || echo false)"

    # FileZilla
    show_selected $INSTALL_FILEZILLA "FileZilla" "$(command_exists filezilla && echo true || echo false)"

    # Debloat
    if $DO_DEBLOAT; then
        echo -e "  ${GREEN}✓${NC} Debloat (bloatware removed)"
    fi

    # RustDesk
    show_selected $INSTALL_RUSTDESK "RustDesk" "$(command_exists rustdesk && echo true || echo false)"

    echo ""
    echo -e "${YELLOW}Note: You may need to log out/in for all changes to take effect${NC}"
    echo ""
    echo -e "${GREEN}Setup completed!${NC}"
}

#===============================================================================
# Main
#===============================================================================
#===============================================================================
# Self-update check: compare local SCRIPT_REVISION against latest gist version
#===============================================================================
check_for_update() {
    # Skip if running from a git checkout (devs don't want auto-overwrite)
    if [ -t 0 ] && [ -f "$0" ] && [ -d "$(dirname "$0")/.git" ]; then
        return 0
    fi

    # Skip if SKIP_UPDATE_CHECK=1
    [ "${SKIP_UPDATE_CHECK:-0}" = "1" ] && return 0

    # Need curl or wget
    local fetcher=""
    if command_exists curl; then fetcher=curl
    elif command_exists wget; then fetcher=wget
    else return 0
    fi

    # Bit.ly caches for 90s, GitHub Gist raw also has CDN cache. Use the Gist API
    # which returns the file content + always-fresh metadata. This is the only
    # reliable way to get the absolute latest revision.
    local gist_id="deb328012eaa1d74e050724db74d2377"
    local api_url="https://api.github.com/gists/${gist_id}"
    local cb="?_=$(date +%s%N)"

    echo -e "${CYAN}Checking for script updates...${NC}" >&2

    local raw_url remote_rev api_json
    if [ "$fetcher" = "curl" ]; then
        api_json=$(curl -fsSL --max-time 10 \
            -H "Cache-Control: no-cache, no-store" \
            -H "Pragma: no-cache" \
            -H "Accept: application/vnd.github+json" \
            "${api_url}${cb}" 2>/dev/null)
    else
        api_json=$(wget -qO- --timeout=10 --no-cache \
            --header="Cache-Control: no-cache, no-store" \
            --header="Accept: application/vnd.github+json" \
            "${api_url}${cb}" 2>/dev/null)
    fi

    if [ -z "$api_json" ]; then
        echo -e "${YELLOW}Could not reach gist API, continuing with rev-$SCRIPT_REVISION${NC}" >&2
        return 0
    fi

    # Extract raw_url (always points to the latest revision of the file)
    raw_url=$(echo "$api_json" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
    print(d['files']['ubuntu-setup.sh']['raw_url'])
except Exception:
    pass
" 2>/dev/null)

    if [ -z "$raw_url" ]; then
        echo -e "${YELLOW}Could not parse gist API, continuing with rev-$SCRIPT_REVISION${NC}" >&2
        return 0
    fi

    # Fetch the file content (raw_url has the commit SHA so no cache issues)
    local remote_content
    if [ "$fetcher" = "curl" ]; then
        remote_content=$(curl -fsSL --max-time 30 \
            -H "Cache-Control: no-cache, no-store" "$raw_url" 2>/dev/null)
    else
        remote_content=$(wget -qO- --timeout=30 --no-cache "$raw_url" 2>/dev/null)
    fi

    remote_rev=$(echo "$remote_content" | grep -m1 '^SCRIPT_REVISION=' | \
                 sed -E 's/^SCRIPT_REVISION="?([0-9]+)"?.*/\1/')

    if [ -z "$remote_rev" ] || ! [[ "$remote_rev" =~ ^[0-9]+$ ]]; then
        echo -e "${YELLOW}Could not detect remote revision, continuing with rev-$SCRIPT_REVISION${NC}" >&2
        return 0
    fi

    if [ "$remote_rev" -le "$SCRIPT_REVISION" ]; then
        echo -e "${GREEN}You're on the latest rev-$SCRIPT_REVISION${NC}" >&2
        return 0
    fi

    echo "" >&2
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════╗${NC}" >&2
    echo -e "${YELLOW}║  Update available: rev-${SCRIPT_REVISION} → rev-${remote_rev}${NC}" >&2
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════╝${NC}" >&2
    echo "" >&2

    read -p "Download and run the latest version now? (y/n): " upd_choice < /dev/tty
    if [[ ! "$upd_choice" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Continuing with rev-$SCRIPT_REVISION${NC}" >&2
        return 0
    fi

    local new_script="/tmp/ubuntu-setup-rev${remote_rev}.sh"
    # We already have the content, just write it out
    echo "$remote_content" > "$new_script"

    if [ ! -s "$new_script" ]; then
        echo -e "${RED}Failed to save new script, continuing with rev-$SCRIPT_REVISION${NC}" >&2
        return 0
    fi

    chmod +x "$new_script"
    # Set SKIP_UPDATE_CHECK so the new run doesn't loop
    export SKIP_UPDATE_CHECK=1
    echo -e "${GREEN}Re-launching with rev-$remote_rev...${NC}" >&2
    echo "" >&2
    exec bash "$new_script" "$@"
}

#===============================================================================
# Critical-package health check
# If a previous run accidentally pulled out core desktop packages, offer to fix.
#===============================================================================
check_critical_packages() {
    # Only check on Ubuntu desktop systems (skip headless servers)
    command_exists gnome-shell || return 0

    # Only flag REAL app binaries — missing one of these = actual breakage.
    # ubuntu-desktop / ubuntu-desktop-minimal are intentionally skipped here
    # because they're meta-packages (no files). If the user wants those back
    # they can pick "Restore Ubuntu Desktop Meta" from the Tweaks menu.
    local -a missing_critical=()
    package_installed gnome-control-center || missing_critical+=("gnome-control-center")
    package_installed gnome-terminal       || missing_critical+=("gnome-terminal")
    package_installed nautilus             || missing_critical+=("nautilus")
    package_installed gnome-shell          || missing_critical+=("gnome-shell")

    if [ "${#missing_critical[@]}" -eq 0 ]; then
        return 0
    fi

    echo ""
    echo -e "${RED}╔═══════════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  Core desktop app(s) missing                                                  ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${YELLOW}These real apps are NOT installed (probably a cascading apt-purge previously):${NC}"
    for p in "${missing_critical[@]}"; do
        case "$p" in
            gnome-control-center) echo -e "  ${RED}✗${NC} $p  → Settings app" ;;
            gnome-terminal)       echo -e "  ${RED}✗${NC} $p  → Terminal app" ;;
            nautilus)             echo -e "  ${RED}✗${NC} $p  → Files app" ;;
            gnome-shell)          echo -e "  ${RED}✗${NC} $p  → GNOME Shell itself" ;;
            *)                    echo -e "  ${RED}✗${NC} $p" ;;
        esac
    done
    echo ""
    read -p "Reinstall them now? (y/n): " crit_choice < /dev/tty
    if [[ "$crit_choice" =~ ^[Yy]$ ]]; then
        _pause_update_notifier
        sudo apt-get update -qq
        # --no-install-recommends so we don't accidentally drag back bloatware
        # via any transitive Recommends chains.
        sudo apt-get install -y --no-install-recommends "${missing_critical[@]}" 2>&1 | tail -5
        _resume_update_notifier
        log_success "Reinstalled: ${missing_critical[*]}"
    else
        log_warning "Skipped — to fix later: sudo apt install --no-install-recommends ${missing_critical[*]}"
    fi
}

main() {
    # Self-update check (skipped for git checkouts and when SKIP_UPDATE_CHECK=1)
    check_for_update "$@"

    # Sanity check: warn if the desktop is missing core pieces
    check_critical_packages

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
       $INSTALL_RUSTDESK || $INSTALL_ANYDESK || $INSTALL_TEAMVIEWER || \
       $DO_CLI_LOGIN || $DO_REMOVE_FIREFOX || $APPLY_JETSON_FIX || $DO_DEBLOAT; then
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
