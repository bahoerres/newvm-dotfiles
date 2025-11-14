#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}==>${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}==>${NC} $1"
}

print_error() {
    echo -e "${RED}==>${NC} $1"
}

print_info() {
    echo -e "${BLUE}==>${NC} $1"
}

check_version() {
    local tool=$1
    local current=$2
    local latest=$3

    if [ "$current" = "$latest" ]; then
        print_info "$tool is up to date ($current)"
        return 1
    else
        print_warning "$tool can be updated: $current -> $latest"
        return 0
    fi
}

# Parse arguments
CHECK_ONLY=false
if [ "$1" = "--check" ]; then
    CHECK_ONLY=true
    print_status "Checking for updates..."
    echo ""
fi

UPDATES_AVAILABLE=false

# Update system packages first
if [ "$CHECK_ONLY" = false ]; then
    print_status "Updating system packages..."
    sudo apt update && sudo apt upgrade -y
    echo ""
fi

# Neovim
print_status "Checking Neovim..."
if command -v nvim &> /dev/null; then
    CURRENT_NVIM=$(nvim --version | head -n1 | awk '{print $2}')
    print_info "Current version: $CURRENT_NVIM"

    if [ "$CHECK_ONLY" = false ]; then
        read -p "Update Neovim to latest nightly? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Updating Neovim..."
            curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage
            chmod u+x nvim-linux-x86_64.appimage
            ./nvim-linux-x86_64.appimage --appimage-extract
            sudo rm -rf /usr/local/nvim
            sudo mv squashfs-root /usr/local/nvim
            rm nvim-linux-x86_64.appimage
            print_status "Neovim updated!"
        fi
    fi
else
    print_warning "Neovim not found"
fi
echo ""

# Lazygit
print_status "Checking lazygit..."
if command -v lazygit &> /dev/null; then
    CURRENT_LG=$(lazygit --version | head -n1 | awk -F'version=' '{print $2}' | awk '{print $1}' | tr -d ',')
    LATEST_LG=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

    if check_version "lazygit" "$CURRENT_LG" "$LATEST_LG"; then
        UPDATES_AVAILABLE=true
        if [ "$CHECK_ONLY" = false ]; then
            print_status "Updating lazygit..."
            curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LATEST_LG}_Linux_x86_64.tar.gz"
            tar xf lazygit.tar.gz lazygit
            sudo install lazygit /usr/local/bin
            rm lazygit lazygit.tar.gz
            print_status "Lazygit updated to $LATEST_LG!"
        fi
    fi
else
    print_warning "Lazygit not found"
fi
echo ""

# Lazydocker
print_status "Checking lazydocker..."
if command -v lazydocker &> /dev/null; then
    CURRENT_LD=$(lazydocker --version | head -n1 | awk -F'Version: ' '{print $2}' | awk '{print $1}')
    LATEST_LD=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

    if check_version "lazydocker" "$CURRENT_LD" "$LATEST_LD"; then
        UPDATES_AVAILABLE=true
        if [ "$CHECK_ONLY" = false ]; then
            print_status "Updating lazydocker..."
            curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LATEST_LD}_Linux_x86_64.tar.gz"
            tar xf lazydocker.tar.gz lazydocker
            sudo install lazydocker /usr/local/bin
            rm lazydocker lazydocker.tar.gz
            print_status "Lazydocker updated to $LATEST_LD!"
        fi
    fi
else
    print_warning "Lazydocker not found"
fi
echo ""

# Starship
print_status "Checking starship..."
if command -v starship &> /dev/null; then
    CURRENT_STARSHIP=$(starship --version | awk '{print $2}')
    print_info "Current version: $CURRENT_STARSHIP"

    if [ "$CHECK_ONLY" = false ]; then
        read -p "Update starship to latest? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Updating starship..."
            curl -sS https://starship.rs/install.sh | sh -s -- -y
            print_status "Starship updated!"
        fi
    fi
else
    print_warning "Starship not found"
fi
echo ""

# Zoxide
print_status "Checking zoxide..."
if command -v zoxide &> /dev/null; then
    CURRENT_ZOXIDE=$(zoxide --version | awk '{print $2}')
    print_info "Current version: $CURRENT_ZOXIDE"

    if [ "$CHECK_ONLY" = false ]; then
        read -p "Update zoxide to latest? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Updating zoxide..."
            curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
            print_status "Zoxide updated!"
        fi
    fi
else
    print_warning "Zoxide not found"
fi
echo ""

# Atuin
print_status "Checking atuin..."
if command -v atuin &> /dev/null; then
    CURRENT_ATUIN=$(atuin --version | awk '{print $2}')
    print_info "Current version: $CURRENT_ATUIN"

    if [ "$CHECK_ONLY" = false ]; then
        read -p "Update atuin to latest? (y/N): " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Updating atuin..."
            bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
            print_status "Atuin updated!"
        fi
    fi
else
    print_warning "Atuin not found"
fi
echo ""

# Duf
print_status "Checking duf..."
if command -v duf &> /dev/null; then
    CURRENT_DUF=$(duf --version 2>&1 | head -n1 | awk '{print $2}')
    LATEST_DUF=$(curl -s "https://api.github.com/repos/muesli/duf/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')

    if check_version "duf" "$CURRENT_DUF" "$LATEST_DUF"; then
        UPDATES_AVAILABLE=true
        if [ "$CHECK_ONLY" = false ]; then
            print_status "Updating duf..."
            curl -Lo duf.deb "https://github.com/muesli/duf/releases/latest/download/duf_${LATEST_DUF}_linux_amd64.deb"
            sudo dpkg -i duf.deb
            rm duf.deb
            print_status "Duf updated to $LATEST_DUF!"
        fi
    fi
else
    print_warning "Duf not found"
fi
echo ""

# Eza
print_status "Checking eza..."
if command -v eza &> /dev/null; then
    CURRENT_EZA=$(eza --version | head -n1 | awk '{print $2}')
    print_info "Current version: $CURRENT_EZA (managed via apt repository)"

    if [ "$CHECK_ONLY" = false ]; then
        print_info "Eza will be updated via apt upgrade"
    fi
else
    print_warning "Eza not found"
fi
echo ""

# APT-managed tools (lnav, ncdu, grc, httpie, bat)
print_status "APT-managed tools (lnav, ncdu, grc, httpie, bat):"
print_info "These tools are updated via 'apt upgrade' (already done)"
echo ""

# Summary
if [ "$CHECK_ONLY" = true ]; then
    if [ "$UPDATES_AVAILABLE" = true ]; then
        echo ""
        print_warning "Updates available! Run without --check to update."
    else
        echo ""
        print_status "All tools are up to date!"
    fi
else
    echo ""
    print_status "Update complete!"
fi
