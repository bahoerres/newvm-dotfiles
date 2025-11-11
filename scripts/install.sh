#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Directories
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"

print_status() {
  echo -e "${GREEN}==>${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}==>${NC} $1"
}

print_error() {
  echo -e "${RED}==>${NC} $1"
}

backup_if_exists() {
  local file=$1
  if [ -e "$file" ] && [ ! -L "$file" ]; then
    print_warning "Backing up existing $(basename $file)"
    mkdir -p "$BACKUP_DIR"
    cp -r "$file" "$BACKUP_DIR/"
  fi
}

install_tools() {
  print_status "Updating system packages..."
  sudo apt update && sudo apt upgrade -y

  print_status "Installing essential tools..."
  sudo apt install -y curl git build-essential software-properties-common zsh nodejs npm

  # Neovim
  print_status "Installing Neovim (AppImage)..."
  if ! command -v nvim &>/dev/null; then
    curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim.appimage
    chmod u+x nvim.appimage
    sudo mv nvim.appimage /usr/local/bin/nvim
  else
    print_warning "Neovim already installed, skipping..."
  fi

  # Fastfetch
  print_status "Installing fastfetch..."
  if ! command -v fastfetch &>/dev/null; then
    # Get latest release URL
    FASTFETCH_URL=$(curl -s https://api.github.com/repos/fastfetch-cli/fastfetch/releases/latest | grep "browser_download_url.*linux-amd64.deb" | cut -d '"' -f 4)
    curl -sL "$FASTFETCH_URL" -o /tmp/fastfetch.deb
    sudo dpkg -i /tmp/fastfetch.deb
    rm /tmp/fastfetch.deb
  else
    print_warning "Fastfetch already installed, skipping..."
  fi

  # Eza (modern ls replacement)
  print_status "Installing eza..."
  if ! command -v eza &>/dev/null; then
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
  else
    print_warning "Eza already installed, skipping..."
  fi

  # Zoxide (smarter cd command)
  print_status "Installing zoxide..."
  if ! command -v zoxide &>/dev/null; then
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  else
    print_warning "Zoxide already installed, skipping..."
  fi

  # Starship
  print_status "Installing Starship..."
  if ! command -v starship &>/dev/null; then
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  else
    print_warning "Starship already installed, skipping..."
  fi

  # Atuin
  print_status "Installing Atuin..."
  if ! command -v atuin &>/dev/null; then
    bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
  else
    print_warning "Atuin already installed, skipping..."
  fi

  # LazyVim
  if [ ! -d "$HOME/.config/nvim" ]; then
    print_status "Installing LazyVim..."
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git
  else
    print_warning "Neovim config already exists, skipping LazyVim install..."
  fi

  # Zsh plugins
  print_status "Installing zsh plugins..."
  mkdir -p ~/.zsh/

  if [ ! -d ~/.zsh/zsh-syntax-highlighting ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
  fi

  if [ ! -d ~/.zsh/zsh-autocomplete ]; then
    git clone https://github.com/marlonrichert/zsh-autocomplete.git ~/.zsh/zsh-autocomplete
  fi
}

link_configs() {
  print_status "Linking configuration files..."

  # Starship config
  backup_if_exists "$HOME/.config/starship.toml"
  mkdir -p "$HOME/.config"
  ln -sf "$DOTFILES_DIR/config/starship.toml" "$HOME/.config/starship.toml"
  print_status "Linked starship.toml"

  # Main zshrc
  backup_if_exists "$HOME/.zshrc"
  ln -sf "$DOTFILES_DIR/config/.zshrc" "$HOME/.zshrc"
  print_status "Linked .zshrc"

  # Zsh modules directory
  backup_if_exists "$HOME/.config/zshrc"
  ln -sf "$DOTFILES_DIR/config/zshrc" "$HOME/.config/zshrc"
  print_status "Linked zsh modules directory"
}

change_shell() {
  if [ "$SHELL" != "$(which zsh)" ]; then
    print_status "Changing default shell to zsh..."
    chsh -s $(which zsh)
    print_warning "Shell changed to zsh. You'll need to log out and back in for this to take effect."
  else
    print_status "Default shell is already zsh"
  fi
}

show_completion_message() {
  echo ""
  print_status "Installation complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Log out and back in (or reboot) for shell change to take effect"
  echo "  2. Optional: Run './scripts/setup-docker.sh' to set up Docker"
  echo ""
  if [ -d "$BACKUP_DIR" ]; then
    echo "Your old configs have been backed up to: $BACKUP_DIR"
  fi
}

# Parse arguments
TOOLS_ONLY=false
LINK_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
  --tools-only)
    TOOLS_ONLY=true
    shift
    ;;
  --link-only)
    LINK_ONLY=true
    shift
    ;;
  --help)
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --tools-only    Install tools only (skip config linking)"
    echo "  --link-only     Link configs only (skip tool installation)"
    echo "  --help          Show this help message"
    exit 0
    ;;
  *)
    print_error "Unknown option: $1"
    echo "Use --help for usage information"
    exit 1
    ;;
  esac
done

# Main execution
print_status "Starting dotfiles installation..."
echo "Install location: $DOTFILES_DIR"
echo ""

if [ "$LINK_ONLY" = false ]; then
  install_tools
fi

if [ "$TOOLS_ONLY" = false ]; then
  link_configs
  change_shell
fi

show_completion_message
