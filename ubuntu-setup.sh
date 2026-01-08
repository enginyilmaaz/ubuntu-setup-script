#!/bin/bash

#===============================================================================
# Ubuntu Post-Installation Setup Script
# Author: Auto-generated
# Description: Automates Ubuntu post-installation setup including:
#   - NVM, Node.js 22, Yarn
#   - CLI tools (Codex, Gemini CLI, Claude CLI)
#   - Chrome, Cursor, VSCode with extensions
#   - Python 3, RealVNC Connect
#   - Firefox removal
#===============================================================================

set -e

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
        log_error "Cannot detect OS. This script is designed for Ubuntu."
        exit 1
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
            log_error "Unsupported architecture: $ARCH"
            exit 1
            ;;
    esac

    log_info "OS: $OS_NAME $OS_VERSION ($OS_CODENAME)"
    log_info "Architecture: $ARCH ($DEB_ARCH)"

    # Check if Ubuntu
    if [[ "$ID" != "ubuntu" && "$ID_LIKE" != *"ubuntu"* ]]; then
        log_warning "This script is optimized for Ubuntu. Some features may not work correctly."
    fi
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

#===============================================================================
# 1. NVM, Node.js 22, Yarn Installation
#===============================================================================
install_nvm_nodejs() {
    log_step "1. Installing NVM, Node.js 22, and Yarn"

    # 1.0 Install NVM
    log_info "1.0 Installing NVM..."
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

    # 1.1 Install Node.js 22
    log_info "1.1 Installing Node.js 22..."
    if command_exists node && [[ "$(node -v)" == v22* ]]; then
        log_warning "Node.js 22 already installed ($(node -v)), skipping..."
    else
        nvm install 22
        nvm use 22
        nvm alias default 22
        log_success "Node.js 22 installed successfully ($(node -v))"
    fi

    # 1.2 Install Yarn globally
    log_info "1.2 Installing Yarn globally..."
    if command_exists yarn; then
        log_warning "Yarn already installed ($(yarn -v)), skipping..."
    else
        npm install -g yarn
        log_success "Yarn installed successfully ($(yarn -v))"
    fi

    # 1.3 Install Codex CLI
    log_info "1.3 Installing Codex CLI (OpenAI)..."
    if command_exists codex; then
        log_warning "Codex CLI already installed, skipping..."
    else
        npm install -g @openai/codex
        log_success "Codex CLI installed successfully"
    fi

    # 1.4 Install Gemini CLI
    log_info "1.4 Installing Gemini CLI..."
    if command_exists gemini; then
        log_warning "Gemini CLI already installed, skipping..."
    else
        npm install -g @google/gemini-cli
        log_success "Gemini CLI installed successfully"
    fi

    # 1.5 Install Claude CLI
    log_info "1.5 Installing Claude CLI..."
    if command_exists claude; then
        log_warning "Claude CLI already installed, skipping..."
    else
        npm install -g @anthropic-ai/claude-code
        log_success "Claude CLI installed successfully"
    fi
}

#===============================================================================
# 2. Google Chrome Installation
#===============================================================================
install_chrome() {
    log_step "2. Installing Google Chrome"

    if command_exists google-chrome || command_exists google-chrome-stable; then
        log_warning "Google Chrome already installed, skipping..."
        return
    fi

    log_info "Downloading Google Chrome..."
    local temp_deb="/tmp/google-chrome.deb"

    download_file "https://dl.google.com/linux/direct/google-chrome-stable_current_${DEB_ARCH}.deb" "$temp_deb"

    log_info "Installing Google Chrome..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$temp_deb"

    rm -f "$temp_deb"
    log_success "Google Chrome installed successfully"
}

#===============================================================================
# 3. Cursor IDE Installation
#===============================================================================
install_cursor() {
    log_step "3. Installing Cursor IDE"

    if command_exists cursor; then
        log_warning "Cursor already installed, skipping..."
        return
    fi

    log_info "Downloading Cursor..."
    local temp_file="/tmp/cursor.appimage"

    # Cursor uses AppImage format
    if [ "$DEB_ARCH" == "amd64" ]; then
        download_file "https://downloader.cursor.sh/linux/appImage/x64" "$temp_file"
    else
        download_file "https://downloader.cursor.sh/linux/appImage/arm64" "$temp_file"
    fi

    log_info "Installing Cursor..."
    chmod +x "$temp_file"

    # Move to /opt and create symlink
    sudo mkdir -p /opt/cursor
    sudo mv "$temp_file" /opt/cursor/cursor.appimage
    sudo ln -sf /opt/cursor/cursor.appimage /usr/local/bin/cursor

    # Create desktop entry
    cat << EOF | sudo tee /usr/share/applications/cursor.desktop
[Desktop Entry]
Name=Cursor
Comment=Cursor AI IDE
Exec=/opt/cursor/cursor.appimage --no-sandbox %F
Icon=cursor
Terminal=false
Type=Application
Categories=Development;IDE;
StartupWMClass=Cursor
EOF

    log_success "Cursor installed successfully"
}

#===============================================================================
# 4. Visual Studio Code Installation
#===============================================================================
install_vscode() {
    log_step "4. Installing Visual Studio Code"

    if command_exists code; then
        log_warning "VS Code already installed, skipping installation..."
    else
        log_info "Downloading Visual Studio Code..."
        local temp_deb="/tmp/vscode.deb"

        download_file "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-${DEB_ARCH}" "$temp_deb"

        log_info "Installing VS Code..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$temp_deb"

        rm -f "$temp_deb"
        log_success "VS Code installed successfully"
    fi

    # Install extensions
    install_vscode_extensions
}

install_vscode_extensions() {
    log_info "4.1-4.3 Installing VS Code Extensions..."

    # 4.1 Gemini Code Assist
    log_info "4.1 Installing Gemini Code Assist extension..."
    if code --list-extensions 2>/dev/null | grep -qi "google.geminicodeassist"; then
        log_warning "Gemini Code Assist already installed, skipping..."
    else
        code --install-extension google.geminicodeassist --force 2>/dev/null || log_warning "Could not install Gemini extension"
    fi

    # 4.2 Claude Code (Claude Dev)
    log_info "4.2 Installing Claude Code extension..."
    if code --list-extensions 2>/dev/null | grep -qi "anthropic.claude-code"; then
        log_warning "Claude Code already installed, skipping..."
    else
        code --install-extension anthropic.claude-code --force 2>/dev/null || \
        code --install-extension saoudrizwan.claude-dev --force 2>/dev/null || \
        log_warning "Could not install Claude extension"
    fi

    # 4.3 ChatGPT/Codex Extension
    log_info "4.3 Installing ChatGPT extension..."
    if code --list-extensions 2>/dev/null | grep -qi "openai.chatgpt"; then
        log_warning "ChatGPT extension already installed, skipping..."
    else
        code --install-extension openai.chatgpt --force 2>/dev/null || \
        code --install-extension gencay.vscode-chatgpt --force 2>/dev/null || \
        log_warning "Could not install ChatGPT extension"
    fi

    log_success "VS Code extensions installation completed"
}

#===============================================================================
# 5. Python 3 Installation
#===============================================================================
install_python() {
    log_step "5. Installing Python 3"

    if command_exists python3; then
        log_warning "Python 3 already installed ($(python3 --version)), skipping..."
    else
        log_info "Installing Python 3..."
        sudo apt-get update
        sudo apt-get install -y python3 python3-pip python3-venv
        log_success "Python 3 installed successfully"
    fi

    # Ensure pip is available
    if ! command_exists pip3; then
        log_info "Installing pip3..."
        sudo apt-get install -y python3-pip
    fi
}

#===============================================================================
# 6. RealVNC Connect Installation
#===============================================================================
install_realvnc() {
    log_step "6. Installing RealVNC Connect"

    if package_installed realvnc-vnc-server || command_exists vncserver-x11; then
        log_warning "RealVNC already installed, skipping..."
        return
    fi

    log_info "Downloading RealVNC Connect..."
    local temp_deb="/tmp/realvnc.deb"

    # RealVNC download URL
    if [ "$DEB_ARCH" == "amd64" ]; then
        download_file "https://downloads.realvnc.com/download/file/vnc.files/VNC-Server-7.12.1-Linux-x64.deb" "$temp_deb" || \
        download_file "https://www.realvnc.com/download/file/vnc.files/VNC-Server-7.12.1-Linux-x64.deb" "$temp_deb"
    else
        download_file "https://downloads.realvnc.com/download/file/vnc.files/VNC-Server-7.12.1-Linux-ARM64.deb" "$temp_deb" || \
        download_file "https://www.realvnc.com/download/file/vnc.files/VNC-Server-7.12.1-Linux-ARM64.deb" "$temp_deb"
    fi

    if [ -f "$temp_deb" ]; then
        log_info "Installing RealVNC Connect..."
        sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$temp_deb"
        rm -f "$temp_deb"
        log_success "RealVNC Connect installed successfully"
    else
        log_warning "Could not download RealVNC. Please install manually from https://www.realvnc.com/en/connect/download/vnc/"
    fi
}

#===============================================================================
# 7. CLI Login Commands
#===============================================================================
run_cli_logins() {
    log_step "7. CLI Login Commands"

    log_info "Running CLI login commands..."
    log_info "Each CLI will open a browser for authentication."

    echo ""
    read -p "Do you want to login to CLI tools now? (y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Reload NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

        # Claude CLI login
        if command_exists claude; then
            log_info "Starting Claude CLI login..."
            claude auth login || log_warning "Claude login skipped or failed"
        fi

        # Gemini CLI login
        if command_exists gemini; then
            log_info "Starting Gemini CLI login..."
            gemini auth login || log_warning "Gemini login skipped or failed"
        fi

        # Codex CLI login
        if command_exists codex; then
            log_info "Starting Codex CLI login..."
            codex auth login || log_warning "Codex login skipped or failed"
        fi

        log_success "CLI logins completed"
    else
        log_info "Skipping CLI logins. You can run them later manually:"
        echo "  - claude auth login"
        echo "  - gemini auth login"
        echo "  - codex auth login"
    fi
}

#===============================================================================
# 8. Firefox Removal
#===============================================================================
remove_firefox() {
    log_step "8. Removing Firefox"

    if ! command_exists firefox && ! snap list firefox &>/dev/null 2>&1; then
        log_warning "Firefox not found, skipping removal..."
        return
    fi

    read -p "Do you want to remove Firefox? (y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing Firefox..."

        # Remove snap version
        if snap list firefox &>/dev/null 2>&1; then
            sudo snap remove firefox
        fi

        # Remove apt version
        if dpkg -l firefox &>/dev/null 2>&1; then
            sudo apt-get remove -y firefox
            sudo apt-get autoremove -y
        fi

        # Remove flatpak version
        if flatpak list 2>/dev/null | grep -qi firefox; then
            flatpak uninstall -y org.mozilla.firefox
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
    sudo apt-get update

    log_info "Installing required packages..."
    sudo apt-get install -y \
        curl \
        wget \
        gnupg \
        ca-certificates \
        apt-transport-https \
        software-properties-common \
        build-essential \
        git

    log_success "Prerequisites installed"
}

#===============================================================================
# Summary
#===============================================================================
print_summary() {
    log_step "Installation Summary"

    echo -e "${GREEN}Installed Components:${NC}"
    echo ""

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
    command_exists gemini && echo -e "  ${GREEN}✓${NC} Gemini CLI"
    command_exists claude && echo -e "  ${GREEN}✓${NC} Claude CLI"
    (command_exists google-chrome || command_exists google-chrome-stable) && echo -e "  ${GREEN}✓${NC} Google Chrome"
    command_exists cursor && echo -e "  ${GREEN}✓${NC} Cursor IDE"
    command_exists code && echo -e "  ${GREEN}✓${NC} VS Code"
    command_exists python3 && echo -e "  ${GREEN}✓${NC} Python $(python3 --version 2>&1 | cut -d' ' -f2)"
    (package_installed realvnc-vnc-server || command_exists vncserver-x11) && echo -e "  ${GREEN}✓${NC} RealVNC Connect"

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
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║           Ubuntu Post-Installation Setup Script               ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        log_error "Please do not run this script as root. Run as normal user."
        exit 1
    fi

    # Detect system
    detect_system

    # Install prerequisites
    install_prerequisites

    # Run installations
    install_nvm_nodejs      # 1. NVM, Node.js, Yarn, CLI tools
    install_chrome          # 2. Google Chrome
    install_cursor          # 3. Cursor IDE
    install_vscode          # 4. VS Code + Extensions
    install_python          # 5. Python 3
    install_realvnc         # 6. RealVNC Connect
    run_cli_logins          # 7. CLI Logins
    remove_firefox          # 8. Firefox Removal

    # Print summary
    print_summary
}

# Run main function
main "$@"
