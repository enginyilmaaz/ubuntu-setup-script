#!/bin/bash

#===============================================================================
# Ubuntu Post-Installation Setup Script
# Author: Auto-generated
# Description: Automates Ubuntu post-installation setup including:
#   - NVM, Node.js 22, Yarn
#   - CLI tools (Codex, Gemini CLI, Claude CLI)
#   - Chrome (apt), Cursor (AppImage), VSCode (apt) with extensions
#   - Python 3, RealVNC Connect (snap), DBeaver CE (snap)
#   - GNOME Shell Extensions + Dash to Dock configuration
#   - Firefox removal (snap/deb/flatpak detection)
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
# 2. Google Chrome Installation (via apt repository)
#===============================================================================
install_chrome() {
    log_step "2. Installing Google Chrome"

    if command_exists google-chrome || command_exists google-chrome-stable; then
        log_warning "Google Chrome already installed, skipping..."
        return
    fi

    log_info "Adding Google Chrome repository..."

    # Add Google's signing key
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg

    # Add repository
    echo "deb [arch=${DEB_ARCH} signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

    # Update and install
    sudo apt-get update
    sudo apt-get install -y google-chrome-stable

    log_success "Google Chrome installed successfully (via apt repository)"
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
# 4. Visual Studio Code Installation (via apt repository)
#===============================================================================
install_vscode() {
    log_step "4. Installing Visual Studio Code"

    if command_exists code; then
        log_warning "VS Code already installed, skipping installation..."
    else
        log_info "Adding Microsoft VS Code repository..."

        # Add Microsoft's signing key
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft.gpg

        # Add repository
        echo "deb [arch=${DEB_ARCH} signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

        # Update and install
        sudo apt-get update
        sudo apt-get install -y code

        log_success "VS Code installed successfully (via apt repository)"
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
# 6. GNOME Shell Extensions
#===============================================================================
install_gnome_extensions() {
    log_step "6. Installing GNOME Shell Extensions"

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

    log_success "GNOME Shell Extensions setup completed"
    log_info "You can manage extensions via:"
    echo "  - Extension Manager app"
    echo "  - https://extensions.gnome.org (with browser)"
    echo "  - gnome-tweaks"

    # Configure Dash to Dock settings
    configure_dash_to_dock
}

#===============================================================================
# 6.1 Dash to Dock Configuration
#===============================================================================
configure_dash_to_dock() {
    log_info "6.1 Configuring Dash to Dock settings..."

    # Check if gsettings is available
    if ! command_exists gsettings; then
        log_warning "gsettings not available, skipping Dash to Dock configuration..."
        return
    fi

    # Check if Dash to Dock schema exists
    if ! gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.dash-to-dock"; then
        log_warning "Dash to Dock extension not installed or schema not found, skipping configuration..."
        return
    fi

    local DOCK_SCHEMA="org.gnome.shell.extensions.dash-to-dock"

    log_info "Applying Dash to Dock settings..."

    # Animation and theme
    gsettings set $DOCK_SCHEMA animate-show-apps true
    gsettings set $DOCK_SCHEMA apply-custom-theme false
    gsettings set $DOCK_SCHEMA custom-theme-shrink true

    # Appearance
    gsettings set $DOCK_SCHEMA background-opacity 1.0
    gsettings set $DOCK_SCHEMA border-radius 0
    gsettings set $DOCK_SCHEMA max-alpha 0.80000000000000004
    gsettings set $DOCK_SCHEMA transparency-mode 'FIXED'

    # Position and size
    gsettings set $DOCK_SCHEMA dock-position 'BOTTOM'
    gsettings set $DOCK_SCHEMA dock-fixed true
    gsettings set $DOCK_SCHEMA extend-height true
    gsettings set $DOCK_SCHEMA height-fraction 0.90000000000000002
    gsettings set $DOCK_SCHEMA floating-margin 0
    gsettings set $DOCK_SCHEMA dash-max-icon-size 32
    gsettings set $DOCK_SCHEMA icon-size-fixed true

    # Behavior
    gsettings set $DOCK_SCHEMA click-action 'minimize-or-previews'
    gsettings set $DOCK_SCHEMA disable-overview-on-startup true
    gsettings set $DOCK_SCHEMA hot-keys false
    gsettings set $DOCK_SCHEMA intellihide-mode 'FOCUS_APPLICATION_WINDOWS'

    # Multi-monitor
    gsettings set $DOCK_SCHEMA multi-monitor true
    gsettings set $DOCK_SCHEMA preferred-monitor -2
    gsettings set $DOCK_SCHEMA preferred-monitor-by-connector 'Virtual1'
    gsettings set $DOCK_SCHEMA isolate-monitors false
    gsettings set $DOCK_SCHEMA isolate-workspaces false

    # Icons and indicators
    gsettings set $DOCK_SCHEMA running-indicator-style 'DASHES'
    gsettings set $DOCK_SCHEMA show-apps-always-in-the-edge false
    gsettings set $DOCK_SCHEMA show-apps-at-top true
    gsettings set $DOCK_SCHEMA show-favorites true
    gsettings set $DOCK_SCHEMA show-running true
    gsettings set $DOCK_SCHEMA show-windows-preview true

    # Mounts and trash
    gsettings set $DOCK_SCHEMA show-mounts true
    gsettings set $DOCK_SCHEMA show-mounts-only-mounted false
    gsettings set $DOCK_SCHEMA show-trash false

    log_success "Dash to Dock configured successfully"
}

#===============================================================================
# 7. RealVNC Connect Installation (via snap)
#===============================================================================
install_realvnc() {
    log_step "7. Installing RealVNC Connect"

    if snap list realvnc-vnc-server &>/dev/null 2>&1 || package_installed realvnc-vnc-server || command_exists vncserver-x11; then
        log_warning "RealVNC already installed, skipping..."
        return
    fi

    log_info "Installing RealVNC Connect via snap..."

    # Install via snap (preferred method)
    if command_exists snap; then
        sudo snap install realvnc-vnc-server --classic || {
            log_warning "Snap installation failed, trying alternative..."
            # Fallback: try apt if available
            sudo apt-get install -y realvnc-vnc-server 2>/dev/null || \
            log_warning "Could not install RealVNC. Please install manually from https://www.realvnc.com/en/connect/download/vnc/"
            return
        }
        log_success "RealVNC Connect installed successfully (via snap)"
    else
        log_warning "Snap not available. Please install RealVNC manually from https://www.realvnc.com/en/connect/download/vnc/"
    fi
}

#===============================================================================
# 8. DBeaver CE Installation (via snap)
#===============================================================================
install_dbeaver() {
    log_step "8. Installing DBeaver Community Edition"

    if snap list dbeaver-ce &>/dev/null 2>&1 || command_exists dbeaver; then
        log_warning "DBeaver CE already installed, skipping..."
        return
    fi

    log_info "Installing DBeaver CE via snap..."

    if command_exists snap; then
        sudo snap install dbeaver-ce
        log_success "DBeaver CE installed successfully (via snap)"
    else
        log_warning "Snap not available. Installing via apt repository..."

        # Add DBeaver repository
        curl -fsSL https://dbeaver.io/debs/dbeaver.gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/dbeaver.gpg
        echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list > /dev/null

        sudo apt-get update
        sudo apt-get install -y dbeaver-ce
        log_success "DBeaver CE installed successfully (via apt repository)"
    fi
}

#===============================================================================
# 9. CLI Login Commands
#===============================================================================
run_cli_logins() {
    log_step "9. CLI Login Commands"

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
# 10. Firefox Removal (detects snap, deb, flatpak)
#===============================================================================
remove_firefox() {
    log_step "10. Removing Firefox"

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

    read -p "Do you want to remove Firefox? (y/n): " -n 1 -r
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
            read -p "Do you want to remove Firefox user data too? (y/n): " -n 1 -r
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
    package_installed gnome-shell-extensions && echo -e "  ${GREEN}✓${NC} GNOME Shell Extensions"
    package_installed gnome-shell-extension-manager && echo -e "  ${GREEN}✓${NC} GNOME Extension Manager"
    package_installed gnome-tweaks && echo -e "  ${GREEN}✓${NC} GNOME Tweaks"
    gsettings list-schemas 2>/dev/null | grep -q "org.gnome.shell.extensions.dash-to-dock" && echo -e "  ${GREEN}✓${NC} Dash to Dock (configured)"
    (snap list realvnc-vnc-server &>/dev/null 2>&1 || package_installed realvnc-vnc-server || command_exists vncserver-x11) && echo -e "  ${GREEN}✓${NC} RealVNC Connect"
    (snap list dbeaver-ce &>/dev/null 2>&1 || command_exists dbeaver) && echo -e "  ${GREEN}✓${NC} DBeaver CE"

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
    install_chrome          # 2. Google Chrome (apt repo)
    install_cursor          # 3. Cursor IDE (AppImage)
    install_vscode          # 4. VS Code + Extensions (apt repo)
    install_python          # 5. Python 3
    install_gnome_extensions # 6. GNOME Shell Extensions + Dash to Dock
    install_realvnc         # 7. RealVNC Connect (snap)
    install_dbeaver         # 8. DBeaver CE (snap)
    run_cli_logins          # 9. CLI Logins
    remove_firefox          # 10. Firefox Removal

    # Print summary
    print_summary
}

# Run main function
main "$@"
