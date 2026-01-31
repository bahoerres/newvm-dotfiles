#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Directories
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.config-backup/$(date +%Y%m%d-%H%M%S)"

print_status() { echo -e "${GREEN}==>${NC} $1"; }
print_warning() { echo -e "${YELLOW}==>${NC} $1"; }
print_error() { echo -e "${RED}==>${NC} $1"; }

backup_if_exists() {
  local file=$1
  if [ -e "$file" ] && [ ! -L "$file" ]; then
    print_warning "Backing up existing $(basename "$file")"
    mkdir -p "$BACKUP_DIR"
    cp -r "$file" "$BACKUP_DIR/"
  fi
}

install_tools() {
  print_status "Updating system packages..."
  sudo apt update && sudo apt upgrade -y

  print_status "Installing essential tools..."
  sudo apt install -y curl git build-essential software-properties-common zsh

  # --- Neovim (extracted AppImage) ---
  print_status "Checking Neovim..."
  if ! command -v nvim &>/dev/null; then
    print_status "Installing Neovim..."
    curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage

    if [ ! -s nvim-linux-x86_64.appimage ] || ! file nvim-linux-x86_64.appimage | grep -q "executable"; then
      print_error "Failed to download Neovim AppImage"
      rm -f nvim-linux-x86_64.appimage
      exit 1
    fi

    chmod u+x nvim-linux-x86_64.appimage
    ./nvim-linux-x86_64.appimage --appimage-extract
    sudo mv squashfs-root /usr/local/nvim
    sudo ln -sf /usr/local/nvim/usr/bin/nvim /usr/local/bin/nvim
    rm nvim-linux-x86_64.appimage
  else
    print_warning "Neovim already installed, skipping..."
  fi

  # --- Eza (modern ls replacement) ---
  print_status "Checking eza..."
  if ! command -v eza &>/dev/null; then
    print_status "Installing eza..."
    sudo mkdir -p /etc/apt/keyrings
    wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
    echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" | sudo tee /etc/apt/sources.list.d/gierens.list
    sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
    sudo apt update
    sudo apt install -y eza
  else
    print_warning "Eza already installed, skipping..."
  fi

  # --- Zoxide (smarter cd) ---
  print_status "Checking zoxide..."
  if ! command -v zoxide &>/dev/null; then
    print_status "Installing zoxide..."
    curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  else
    print_warning "Zoxide already installed, skipping..."
  fi

  # --- Lazygit ---
  print_status "Checking lazygit..."
  if ! command -v lazygit &>/dev/null; then
    print_status "Installing lazygit..."
    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazygit.tar.gz lazygit
    sudo install lazygit /usr/local/bin
    rm lazygit lazygit.tar.gz
  else
    print_warning "Lazygit already installed, skipping..."
  fi

  # --- GitHub CLI ---
  print_status "Checking GitHub CLI..."
  if ! command -v gh &>/dev/null; then
    print_status "Installing GitHub CLI..."
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
    sudo apt update
    sudo apt install -y gh
  else
    print_warning "GitHub CLI already installed, skipping..."
  fi

  # --- Starship ---
  print_status "Checking starship..."
  if ! command -v starship &>/dev/null; then
    print_status "Installing starship..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
  else
    print_warning "Starship already installed, skipping..."
  fi

  # --- Atuin ---
  print_status "Checking atuin..."
  if ! command -v atuin &>/dev/null; then
    print_status "Installing atuin..."
    ATUIN_NO_INTERACTIVE=true bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh) || true
  else
    print_warning "Atuin already installed, skipping..."
  fi

  # --- Lazydocker ---
  print_status "Checking lazydocker..."
  if ! command -v lazydocker &>/dev/null; then
    print_status "Installing lazydocker..."
    LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
    tar xf lazydocker.tar.gz lazydocker
    sudo install lazydocker /usr/local/bin
    rm lazydocker lazydocker.tar.gz
  else
    print_warning "Lazydocker already installed, skipping..."
  fi

  # --- APT tools ---
  local apt_tools=("lnav" "ncdu" "bat" "grc" "httpie")
  for tool in "${apt_tools[@]}"; do
    print_status "Checking $tool..."
    # bat installs as batcat on Debian/Ubuntu
    local check_cmd="$tool"
    [[ "$tool" == "bat" ]] && check_cmd="batcat"

    if ! command -v "$tool" &>/dev/null && ! command -v "$check_cmd" &>/dev/null; then
      print_status "Installing $tool..."
      sudo apt install -y "$tool"
    else
      print_warning "$tool already installed, skipping..."
    fi
  done

  # Symlink batcat -> bat if needed
  if command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
    sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
  fi

  # --- Duf (modern df) ---
  print_status "Checking duf..."
  if ! command -v duf &>/dev/null; then
    print_status "Installing duf..."
    DUF_VERSION=$(curl -s "https://api.github.com/repos/muesli/duf/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    curl -Lo duf.deb "https://github.com/muesli/duf/releases/latest/download/duf_${DUF_VERSION}_linux_amd64.deb"
    sudo dpkg -i duf.deb
    rm duf.deb
  else
    print_warning "Duf already installed, skipping..."
  fi

  # --- LazyVim ---
  if [ ! -d "$HOME/.config/nvim" ]; then
    print_status "Installing LazyVim..."
    git clone https://github.com/LazyVim/starter ~/.config/nvim
    rm -rf ~/.config/nvim/.git
  else
    print_warning "Neovim config already exists, skipping LazyVim install..."
  fi

  # Link theme.lua if available
  if [ -f "$DOTFILES_DIR/config/theme.lua" ]; then
    mkdir -p ~/.config/nvim/lua/plugins
    ln -sf "$DOTFILES_DIR/config/theme.lua" ~/.config/nvim/lua/plugins/theme.lua
    print_status "Linked custom theme.lua"
  fi

  # --- Zsh plugins ---
  print_status "Installing zsh plugins..."
  mkdir -p ~/.zsh

  if [ ! -d ~/.zsh/zsh-syntax-highlighting ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
  fi

  if [ ! -d ~/.zsh/zsh-autosuggestions ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions.git ~/.zsh/zsh-autosuggestions
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
  mkdir -p "$HOME/.config"
  ln -sf "$DOTFILES_DIR/config/zshrc" "$HOME/.config/zshrc"
  print_status "Linked zsh modules directory"

  # SSH config
  if [ -f "$DOTFILES_DIR/config/ssh/config" ]; then
    backup_if_exists "$HOME/.ssh/config"
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    ln -sf "$DOTFILES_DIR/config/ssh/config" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    print_status "Linked SSH config"
  fi
}

link_scripts() {
  print_status "Linking scripts to ~/.local/bin..."
  mkdir -p "$HOME/.local/bin"

  for script in "$DOTFILES_DIR/scripts"/*.sh; do
    if [ -f "$script" ]; then
      script_name=$(basename "$script" .sh)
      ln -sf "$script" "$HOME/.local/bin/$script_name"
      print_status "Linked $script_name"
    fi
  done
}

change_shell() {
  if [ "$SHELL" != "$(which zsh)" ]; then
    print_status "Changing default shell to zsh..."
    if [ -t 0 ]; then
      chsh -s "$(which zsh)"
      print_warning "Shell changed. Log out and back in for it to take effect."
    else
      # Non-interactive (cron, Ansible, etc.) — use sudo to change shell
      sudo chsh -s "$(which zsh)" "$USER"
      print_status "Shell changed to zsh via sudo (non-interactive mode)"
    fi
  else
    print_status "Default shell is already zsh"
  fi
}

setup_auto_sync() {
  print_status "Setting up automated sync and updates..."

  if [ ! -d "$DOTFILES_DIR/.git" ]; then
    print_warning "Not a git repository, skipping auto-sync setup"
    return
  fi

  TEMP_CRON=$(mktemp)
  crontab -l 2>/dev/null >"$TEMP_CRON" || true

  # Auto-pull dotfiles every 6 hours
  SYNC_CMD="0 */6 * * * cd $DOTFILES_DIR && git pull --quiet >> $HOME/.dotfiles-sync.log 2>&1"
  if ! grep -qF "git pull" "$TEMP_CRON" 2>/dev/null; then
    echo "$SYNC_CMD" >>"$TEMP_CRON"
    print_status "Added auto-sync cron job (every 6 hours)"
  else
    print_warning "Auto-sync cron job already exists, skipping..."
  fi

  # Weekly update check (Sundays at 9am)
  UPDATE_CHECK_CMD="0 9 * * 0 $DOTFILES_DIR/scripts/update.sh --check >> $HOME/.dotfiles-update-check.log 2>&1"
  if ! grep -qF "update.sh --check" "$TEMP_CRON" 2>/dev/null; then
    echo "$UPDATE_CHECK_CMD" >>"$TEMP_CRON"
    print_status "Added weekly update check (Sundays at 9am)"
  else
    print_warning "Update check cron job already exists, skipping..."
  fi

  crontab "$TEMP_CRON"
  rm "$TEMP_CRON"
  print_status "Automation setup complete"
}

show_completion_message() {
  echo ""
  print_status "Installation complete!"
  echo ""
  echo "Next steps:"
  echo "  1. Log out and back in for shell change to take effect"
  echo "  2. Optional: Run './scripts/setup-docker.sh' to set up Docker"
  echo ""
  if [ -d "$BACKUP_DIR" ]; then
    echo "Old configs backed up to: $BACKUP_DIR"
  fi
}

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
TOOLS_ONLY=false
LINK_ONLY=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --tools-only)  TOOLS_ONLY=true; shift ;;
    --link-only)   LINK_ONLY=true; shift ;;
    --help|-h)
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
  link_scripts
  change_shell
  setup_auto_sync
fi

show_completion_message
