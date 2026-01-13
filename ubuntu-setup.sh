#!/bin/bash

#===============================================================================
# Ubuntu Post-Installation Setup Script
# Author: Auto-generated
# Description: Automates Ubuntu post-installation setup including:
#   - NVM, Node.js 22, Yarn
#   - CLI tools (Codex, Gemini CLI, Claude CLI)
#   - RealVNC Connect (deb) + Wayland Disable
#   - Chrome (apt), Cursor (deb), Antigravity (apt), VSCode (apt) with extensions
#   - Python 3, DBeaver CE (apt), VLC (apt), Docker (apt)
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

    # 2.4 Install Gemini CLI
    log_info "2.4 Installing Gemini CLI..."
    if command_exists gemini; then
        log_warning "Gemini CLI already installed, skipping..."
    else
        if retry_npm_install @google/gemini-cli; then
            log_success "Gemini CLI installed successfully"
        else
            log_warning "Gemini CLI installation skipped after 3 failed attempts"
        fi
    fi

    # 2.5 Install Claude CLI
    log_info "2.5 Installing Claude CLI..."
    if command_exists claude; then
        log_warning "Claude CLI already installed, skipping..."
    else
        if retry_npm_install @anthropic-ai/claude-code; then
            log_success "Claude CLI installed successfully"
        else
            log_warning "Claude CLI installation skipped after 3 failed attempts"
        fi
    fi
}

#===============================================================================
# 3. Google Chrome Installation (via apt repository)
#===============================================================================
install_chrome() {
    log_step "3. Installing Google Chrome"

    if command_exists google-chrome || command_exists google-chrome-stable; then
        log_warning "Google Chrome already installed, skipping..."
        return
    fi

    log_info "Adding Google Chrome repository..."

    # Add Google's signing key (with retry)
    if ! retry_command "Adding Chrome GPG key" bash -c 'curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg'; then
        log_warning "Chrome installation skipped - could not add GPG key"
        return
    fi

    # Add repository
    echo "deb [arch=${DEB_ARCH} signed-by=/usr/share/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

    # Update and install with retry
    sudo apt-get update
    if retry_apt_install google-chrome-stable; then
        log_success "Google Chrome installed successfully (via apt repository)"
    else
        log_warning "Chrome installation skipped after 3 failed attempts"
    fi
}

#===============================================================================
# 4. Cursor IDE Installation (via deb)
#===============================================================================
install_cursor() {
    log_step "4. Installing Cursor IDE"

    if command_exists cursor || dpkg -l cursor 2>/dev/null | grep -q "^ii"; then
        log_warning "Cursor already installed, skipping..."
        return
    fi

    local temp_file="/tmp/cursor.deb"
    local download_url

    # Cursor deb packages
    if [ "$DEB_ARCH" == "amd64" ]; then
        download_url="https://api2.cursor.sh/updates/download/golden/linux-x64-deb/cursor/latest"
    else
        download_url="https://api2.cursor.sh/updates/download/golden/linux-arm64-deb/cursor/latest"
    fi

    # Download with retry (3 attempts, 5s delay)
    if ! retry_curl_download "$download_url" "$temp_file" "Downloading Cursor deb"; then
        log_warning "Cursor installation skipped after 3 failed attempts. Install manually from https://cursor.sh"
        return
    fi

    log_info "Installing Cursor..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$temp_file"
    rm -f "$temp_file"

    log_success "Cursor installed successfully"
}

#===============================================================================
# 5. Antigravity Installation (via apt repository)
#===============================================================================
install_antigravity() {
    log_step "5. Installing Antigravity"

    if command_exists antigravity; then
        log_warning "Antigravity already installed, skipping..."
        return
    fi

    log_info "Installing Antigravity via apt repository..."

    # Create keyrings directory
    sudo mkdir -p /etc/apt/keyrings

    # Add Antigravity GPG key
    if ! retry_command "Adding Antigravity GPG key" bash -c 'curl -fsSL https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | sudo gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg'; then
        log_warning "Antigravity installation skipped - could not add GPG key"
        return
    fi

    # Add repository
    echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" | sudo tee /etc/apt/sources.list.d/antigravity.list > /dev/null

    # Update and install
    sudo apt-get update
    if retry_apt_install antigravity; then
        log_success "Antigravity installed successfully (via apt repository)"
    else
        log_warning "Antigravity installation skipped after 3 failed attempts"
    fi
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
            log_warning "VS Code installation skipped - could not add GPG key"
            return
        fi

        # Add repository
        echo "deb [arch=${DEB_ARCH} signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

        # Update and install with retry
        sudo apt-get update
        if retry_apt_install code; then
            log_success "VS Code installed successfully (via apt repository)"
        else
            log_warning "VS Code installation skipped after 3 failed attempts"
            return
        fi
    fi

    # Install extensions
    install_vscode_extensions
}

install_vscode_extensions() {
    log_info "6.1-6.4 Installing VS Code Extensions..."

    # 6.1 Gemini CLI VS Code Companion
    log_info "6.1 Installing Gemini CLI VS Code Companion extension..."
    if code --list-extensions 2>/dev/null | grep -qi "Google.gemini-cli-vscode-ide-companion"; then
        log_warning "Gemini CLI Companion already installed, skipping..."
    else
        code --install-extension Google.gemini-cli-vscode-ide-companion --force 2>/dev/null || \
        log_warning "Could not install Gemini CLI Companion extension"
    fi

    # 6.2 Claude Code (Claude Dev)
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
# 8. GNOME Shell Extensions
#===============================================================================
install_gnome_extensions() {
    log_step "8. Installing GNOME Shell Extensions"

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
# 8.1 Dash to Dock Configuration (using dconf)
#===============================================================================
configure_dash_to_dock() {
    log_info "8.1 Configuring Dash to Dock settings..."

    # Check if dconf is available
    if ! command_exists dconf; then
        log_warning "dconf not available, skipping Dash to Dock configuration..."
        return
    fi

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
show-mounts=true
show-mounts-only-mounted=false
show-running=true
show-trash=false
show-windows-preview=true
transparency-mode='FIXED'
DOCKCONF

    log_success "Dash to Dock configured successfully"
}

#===============================================================================
# 1. RealVNC Connect Installation (via deb) + Wayland Disable
#===============================================================================
install_realvnc() {
    log_step "1. Installing RealVNC Connect"

    if package_installed realvnc-connect || command_exists vncserver-x11; then
        log_warning "RealVNC already installed, skipping installation..."
    else
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

    # Check if Wayland is already disabled
    if grep -q "^WaylandEnable=false" "$gdm_config"; then
        log_warning "Wayland already disabled, skipping..."
        return
    fi

    # Backup original config
    sudo cp "$gdm_config" "$gdm_config.backup"

    # Enable the WaylandEnable=false line (uncomment if commented, or add if missing)
    if grep -q "^#WaylandEnable=false" "$gdm_config"; then
        sudo sed -i 's/^#WaylandEnable=false/WaylandEnable=false/' "$gdm_config"
    elif grep -q "^\[daemon\]" "$gdm_config"; then
        sudo sed -i '/^\[daemon\]/a WaylandEnable=false' "$gdm_config"
    else
        echo -e "[daemon]\nWaylandEnable=false" | sudo tee -a "$gdm_config" > /dev/null
    fi

    log_success "Wayland disabled successfully"
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

    log_info "Installing DBeaver CE via apt repository..."

    # Add DBeaver repository with retry
    if ! retry_command "Adding DBeaver GPG key" sudo wget -O /usr/share/keyrings/dbeaver.gpg.key https://dbeaver.io/debs/dbeaver.gpg.key; then
        log_warning "DBeaver installation skipped - could not add GPG key"
        return
    fi

    echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg.key] https://dbeaver.io/debs/dbeaver-ce /" | sudo tee /etc/apt/sources.list.d/dbeaver.list > /dev/null

    sudo apt-get update
    if retry_apt_install dbeaver-ce; then
        log_success "DBeaver CE installed successfully (via apt repository)"
    else
        log_warning "DBeaver CE installation skipped after 3 failed attempts"
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
# 11. Docker Installation (via apt repository)
#===============================================================================
install_docker() {
    log_step "11. Installing Docker"

    if command_exists docker; then
        log_warning "Docker already installed ($(docker --version)), skipping..."
        return
    fi

    log_info "Installing Docker via official apt repository..."

    # Add Docker's official GPG key
    if ! retry_command "Adding Docker GPG key" bash -c 'curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg'; then
        log_warning "Docker installation skipped - could not add GPG key"
        return
    fi

    # Add Docker repository
    echo "deb [arch=${DEB_ARCH} signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${OS_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # Update and install Docker
    sudo apt-get update
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
# 12. CLI Login Commands
#===============================================================================
run_cli_logins() {
    log_step "12. CLI Login Commands"

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

    # Check Gemini CLI auth status
    if command_exists gemini; then
        if gemini auth status &>/dev/null; then
            log_warning "Gemini CLI already authenticated, skipping..."
        else
            log_info "Gemini CLI needs authentication"
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
    read -p "Do you want to login to CLI tools now? (y/n): " -n 1 -r
    echo ""

    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Claude CLI login
        if command_exists claude && ! claude auth status &>/dev/null; then
            log_info "Starting Claude CLI login..."
            claude auth login || log_warning "Claude login skipped or failed"
        fi

        # Gemini CLI login
        if command_exists gemini && ! gemini auth status &>/dev/null; then
            log_info "Starting Gemini CLI login..."
            gemini auth login || log_warning "Gemini login skipped or failed"
        fi

        # Codex CLI login
        if command_exists codex && ! codex auth status &>/dev/null; then
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
# 13. Firefox Removal (detects snap, deb, flatpak)
#===============================================================================
remove_firefox() {
    log_step "13. Removing Firefox"

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
    command_exists gemini && echo -e "  ${GREEN}✓${NC} Gemini CLI"
    command_exists claude && echo -e "  ${GREEN}✓${NC} Claude CLI"
    (command_exists google-chrome || command_exists google-chrome-stable) && echo -e "  ${GREEN}✓${NC} Google Chrome"
    command_exists cursor && echo -e "  ${GREEN}✓${NC} Cursor IDE"
    command_exists antigravity && echo -e "  ${GREEN}✓${NC} Antigravity"
    command_exists code && echo -e "  ${GREEN}✓${NC} VS Code"
    command_exists python3 && echo -e "  ${GREEN}✓${NC} Python $(python3 --version 2>&1 | cut -d' ' -f2)"
    package_installed gnome-shell-extensions && echo -e "  ${GREEN}✓${NC} GNOME Shell Extensions"
    package_installed gnome-shell-extension-manager && echo -e "  ${GREEN}✓${NC} GNOME Extension Manager"
    package_installed gnome-tweaks && echo -e "  ${GREEN}✓${NC} GNOME Tweaks"
    dconf list /org/gnome/shell/extensions/dash-to-dock/ &>/dev/null && echo -e "  ${GREEN}✓${NC} Dash to Dock (configured)"
    (package_installed dbeaver-ce || command_exists dbeaver) && echo -e "  ${GREEN}✓${NC} DBeaver CE"
    command_exists vlc && echo -e "  ${GREEN}✓${NC} VLC Media Player"
    command_exists docker && echo -e "  ${GREEN}✓${NC} Docker $(docker --version 2>&1 | cut -d' ' -f3 | tr -d ',')"

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
    install_realvnc         # 1. RealVNC Connect (deb) + Wayland Disable
    install_nvm_nodejs      # 2. NVM, Node.js, Yarn, CLI tools
    install_chrome          # 3. Google Chrome (apt repo)
    install_cursor          # 4. Cursor IDE (deb)
    install_antigravity     # 5. Antigravity (apt)
    install_vscode          # 6. VS Code + Extensions (apt repo)
    install_python          # 7. Python 3
    install_gnome_extensions # 8. GNOME Shell Extensions + Dash to Dock
    install_dbeaver         # 9. DBeaver CE (apt)
    install_vlc             # 10. VLC Media Player (apt)
    install_docker          # 11. Docker (apt)
    run_cli_logins          # 12. CLI Logins
    remove_firefox          # 13. Firefox Removal

    # Print summary
    print_summary
}

# Run main function
main "$@"
