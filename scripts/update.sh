#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_status()  { echo -e "${GREEN}==>${NC} $1"; }
print_warning() { echo -e "${YELLOW}==>${NC} $1"; }
print_error()   { echo -e "${RED}==>${NC} $1"; }
print_info()    { echo -e "${BLUE}==>${NC} $1"; }

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Fetch latest GitHub release tag (strips leading 'v')
github_latest() {
  local repo="$1"
  curl -s "https://api.github.com/repos/${repo}/releases/latest" | grep -Po '"tag_name": "v?\K[^"]*'
}

# Compare two version strings. Returns 0 if update available, 1 if current.
version_check() {
  local tool="$1" current="$2" latest="$3"

  # Normalize: strip leading v if present
  current="${current#v}"
  latest="${latest#v}"

  if [ -z "$latest" ]; then
    print_warning "$tool: could not determine latest version"
    return 1
  fi

  if [ "$current" = "$latest" ]; then
    print_info "$tool is up to date ($current)"
    return 1
  else
    print_warning "$tool can be updated: $current → $latest"
    return 0
  fi
}

# Prompt or auto-accept based on --yes flag
confirm() {
  local prompt="$1"
  if [ "$AUTO_YES" = true ]; then
    return 0
  fi
  read -p "$prompt (y/N): " -n 1 -r
  echo ""
  [[ $REPLY =~ ^[Yy]$ ]]
}

# ---------------------------------------------------------------------------
# Tool updaters
# ---------------------------------------------------------------------------

update_neovim() {
  print_status "Checking Neovim..."
  if ! command -v nvim &>/dev/null; then
    print_warning "Neovim not found"
    return
  fi

  local current
  current=$(nvim --version | head -n1 | awk '{print $2}')
  print_info "Current version: $current (nightly)"

  # Nightly doesn't have a clean latest comparison, so prompt-based
  if [ "$CHECK_ONLY" = true ]; then
    print_info "Neovim uses nightly builds — run without --check to update"
    return
  fi

  if confirm "Update Neovim to latest nightly?"; then
    print_status "Updating Neovim..."
    curl -LO https://github.com/neovim/neovim/releases/download/nightly/nvim-linux-x86_64.appimage
    chmod u+x nvim-linux-x86_64.appimage
    ./nvim-linux-x86_64.appimage --appimage-extract
    sudo rm -rf /usr/local/nvim
    sudo mv squashfs-root /usr/local/nvim
    rm nvim-linux-x86_64.appimage
    print_status "Neovim updated!"
  fi
}

update_lazygit() {
  print_status "Checking lazygit..."
  if ! command -v lazygit &>/dev/null; then
    print_warning "Lazygit not found"
    return
  fi

  local current latest
  current=$(lazygit --version | head -n1 | awk -F'version=' '{print $2}' | awk '{print $1}' | tr -d ',')
  latest=$(github_latest "jesseduffield/lazygit")

  if version_check "lazygit" "$current" "$latest"; then
    UPDATES_AVAILABLE=true
    if [ "$CHECK_ONLY" = false ] && confirm "Update lazygit to $latest?"; then
      curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${latest}_Linux_x86_64.tar.gz"
      tar xf lazygit.tar.gz lazygit
      sudo install lazygit /usr/local/bin
      rm lazygit lazygit.tar.gz
      print_status "Lazygit updated to $latest!"
    fi
  fi
}

update_lazydocker() {
  print_status "Checking lazydocker..."
  if ! command -v lazydocker &>/dev/null; then
    print_warning "Lazydocker not found"
    return
  fi

  local current latest
  current=$(lazydocker --version | head -n1 | awk -F'Version: ' '{print $2}' | awk '{print $1}')
  latest=$(github_latest "jesseduffield/lazydocker")

  if version_check "lazydocker" "$current" "$latest"; then
    UPDATES_AVAILABLE=true
    if [ "$CHECK_ONLY" = false ] && confirm "Update lazydocker to $latest?"; then
      curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${latest}_Linux_x86_64.tar.gz"
      tar xf lazydocker.tar.gz lazydocker
      sudo install lazydocker /usr/local/bin
      rm lazydocker lazydocker.tar.gz
      print_status "Lazydocker updated to $latest!"
    fi
  fi
}

update_starship() {
  print_status "Checking starship..."
  if ! command -v starship &>/dev/null; then
    print_warning "Starship not found"
    return
  fi

  local current latest
  current=$(starship --version | head -n1 | awk '{print $2}')
  latest=$(github_latest "starship/starship")

  if version_check "starship" "$current" "$latest"; then
    UPDATES_AVAILABLE=true
    if [ "$CHECK_ONLY" = false ] && confirm "Update starship to $latest?"; then
      curl -sS https://starship.rs/install.sh | sh -s -- -y
      print_status "Starship updated to $latest!"
    fi
  fi
}

update_zoxide() {
  print_status "Checking zoxide..."
  if ! command -v zoxide &>/dev/null; then
    print_warning "Zoxide not found"
    return
  fi

  local current latest
  current=$(zoxide --version | awk '{print $2}')
  latest=$(github_latest "ajeetdsouza/zoxide")

  if version_check "zoxide" "$current" "$latest"; then
    UPDATES_AVAILABLE=true
    if [ "$CHECK_ONLY" = false ] && confirm "Update zoxide to $latest?"; then
      curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
      print_status "Zoxide updated to $latest!"
    fi
  fi
}

update_atuin() {
  print_status "Checking atuin..."
  if ! command -v atuin &>/dev/null; then
    print_warning "Atuin not found"
    return
  fi

  local current latest
  current=$(atuin --version | awk '{print $2}')
  latest=$(github_latest "atuinsh/atuin")

  if version_check "atuin" "$current" "$latest"; then
    UPDATES_AVAILABLE=true
    if [ "$CHECK_ONLY" = false ] && confirm "Update atuin to $latest?"; then
      bash <(curl --proto '=https' --tlsv1.2 -sSf https://setup.atuin.sh)
      print_status "Atuin updated to $latest!"
    fi
  fi
}

update_duf() {
  print_status "Checking duf..."
  if ! command -v duf &>/dev/null; then
    print_warning "Duf not found"
    return
  fi

  local current latest
  current=$(duf --version 2>&1 | head -n1 | awk '{print $2}')
  latest=$(github_latest "muesli/duf")

  if version_check "duf" "$current" "$latest"; then
    UPDATES_AVAILABLE=true
    if [ "$CHECK_ONLY" = false ] && confirm "Update duf to $latest?"; then
      curl -Lo duf.deb "https://github.com/muesli/duf/releases/latest/download/duf_${latest}_linux_amd64.deb"
      sudo dpkg -i duf.deb
      rm duf.deb
      print_status "Duf updated to $latest!"
    fi
  fi
}

update_eza() {
  print_status "Checking eza..."
  if ! command -v eza &>/dev/null; then
    print_warning "Eza not found"
    return
  fi

  local current
  current=$(eza --version | head -n1 | awk '{print $2}')
  print_info "Eza $current (managed via apt — updated with system packages)"
}

# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------
CHECK_ONLY=false
AUTO_YES=false
UPDATES_AVAILABLE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --check)  CHECK_ONLY=true; shift ;;
    --yes|-y) AUTO_YES=true; shift ;;
    --help|-h)
      echo "Usage: $0 [OPTIONS]"
      echo ""
      echo "Options:"
      echo "  --check   Check for updates without installing"
      echo "  --yes     Skip confirmation prompts (auto-accept all updates)"
      echo "  --help    Show this help"
      echo ""
      echo "Examples:"
      echo "  $0              # Interactive update"
      echo "  $0 --check      # Just check what's available"
      echo "  $0 --yes        # Update everything non-interactively"
      exit 0
      ;;
    *)
      print_error "Unknown option: $1"
      exit 1
      ;;
  esac
done

if [ "$CHECK_ONLY" = true ]; then
  print_status "Checking for updates..."
else
  print_status "Updating system packages..."
  sudo apt update && sudo apt upgrade -y
fi
echo ""

# Run all checks/updates
update_neovim;    echo ""
update_lazygit;   echo ""
update_lazydocker; echo ""
update_starship;  echo ""
update_zoxide;    echo ""
update_atuin;     echo ""
update_duf;       echo ""
update_eza;       echo ""

# APT-managed tools note
print_status "APT-managed tools (lnav, ncdu, grc, httpie, bat):"
print_info "Updated via apt upgrade"
echo ""

# Summary
if [ "$CHECK_ONLY" = true ]; then
  if [ "$UPDATES_AVAILABLE" = true ]; then
    echo ""
    print_warning "Updates available! Run without --check to update."
    print_info "Use --yes to skip prompts: $0 --yes"
  else
    echo ""
    print_status "All tools are up to date!"
  fi
else
  echo ""
  print_status "Update complete!"
fi
