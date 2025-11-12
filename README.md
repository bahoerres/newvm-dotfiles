# Dotfiles & System Setup

Personal dotfiles and automated setup scripts for new Ubuntu/Debian systems.

## Structure

```
dotfiles/
├── config/
│   ├── starship.toml       # Starship prompt config
│   ├── zshrc               # Main zsh configuration
│   └── zshrc/              # Modular zsh configs
│       ├── 00-init.zsh
│       ├── 10-autostart.zsh
│       ├── 20-customizations.zsh
│       └── 25-aliases.zsh
├── scripts/
│   ├── install.sh          # Main system setup script
│   └── setup-docker.sh     # Docker + Portainer setup (optional)
└── README.md

# After installation, your system will have:
~/
├── .zshrc                  # Symlinked to dotfiles/config/zshrc
├── .zsh/plugins/           # zsh-syntax-highlighting, zsh-autocomplete
├── .config/
│   ├── starship.toml       # Symlinked to dotfiles/config/starship.toml
│   └── zshrc/              # Symlinked to dotfiles/config/zshrc/
└── docker/                 # Docker compose stacks (if setup-docker.sh run)
    ├── portainer/          # or portainer-agent/
    └── watchtower/
```

## Quick Start

### New System Setup

```bash
# Clone the repo
git clone https://github.com/bahoerres/newvm-dotfiles.git ~/dotfiles
cd ~/dotfiles

# Run the installer
./scripts/install.sh
```

This will:
- Install essential tools (zsh, neovim, starship, atuin, fastfetch)
- Set up zsh plugins (syntax-highlighting, autocomplete)
- Symlink all config files
- Change your shell to zsh
- Backup any existing configs to `~/.config-backup/`

### Docker Node Setup (Optional)

```bash
# After main install, set up Docker + Portainer
./scripts/setup-docker.sh
```

Options:
- `./scripts/setup-docker.sh manager` - Deploy Portainer manager + Watchtower
- `./scripts/setup-docker.sh worker` - Deploy Portainer agent + Watchtower
- `./scripts/setup-docker.sh standalone` - Deploy Portainer agent + Watchtower (default)

All Docker compose stacks are organized in `~/docker/`:
- `~/docker/portainer/` or `~/docker/portainer-agent/`
- `~/docker/watchtower/`
- Add your own stacks here as needed

## Manual Installation

If you prefer to cherry-pick components:

```bash
# Install tools only
./scripts/install.sh --tools-only

# Link configs only (assumes tools already installed)
./scripts/install.sh --link-only
```

## Updating Configs

After making changes to your configs:

```bash
# Commit and push
git add -A
git commit -m "Update configs"
git push

# Pull on other systems
cd ~/dotfiles
git pull
```

Since configs are symlinked, changes are immediately reflected.

## Notes

- The installer is idempotent - safe to run multiple times
- Existing configs are backed up to `~/.config-backup/` with timestamps
- Requires Ubuntu/Debian-based system
- Some steps may require sudo privileges

## Customization

Edit configs in `~/dotfiles/config/` - changes take effect immediately due to symlinking.

Reload zsh config: `source ~/.zshrc`

## License

Personal use only.
