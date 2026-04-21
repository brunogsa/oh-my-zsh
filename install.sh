#!/bin/bash
set -e

# shellcheck source=/dev/null
source ~/oh-my-zsh/lib/detect-os.sh

OS=$(detect_os)
echo "Detected OS: $OS"

# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: zsh + oh-my-zsh
# ─────────────────────────────────────────────────────────────────────────────

# Update package manager
if [[ "$OS" == "macos" ]]; then
    brew update
fi

if [[ "$OS" == "linux" ]]; then
    sudo apt-get update && sudo apt-get upgrade -y
fi

# Install zsh
if [[ "$OS" == "macos" ]]; then
    brew install zsh
fi

if [[ "$OS" == "linux" ]]; then
    sudo apt install -y zsh
fi

# Install oh-my-zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh already installed, skipping"
elif [[ "$OS" == "macos" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
elif [[ "$OS" == "linux" ]]; then
    wget -O /tmp/omz-install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
    chmod +x /tmp/omz-install.sh
    /tmp/omz-install.sh
    rm /tmp/omz-install.sh
fi

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: set zsh as default shell
# ─────────────────────────────────────────────────────────────────────────────

sudo chsh -s "$(which zsh)"
chsh -s "$(which zsh)"

# ─────────────────────────────────────────────────────────────────────────────
# Stage 3: themes, plugins, dependencies
# ─────────────────────────────────────────────────────────────────────────────

# OS-specific dependencies
if [[ "$OS" == "macos" ]]; then
    brew install coreutils fd
fi

if [[ "$OS" == "linux" ]]; then
    sudo apt-get install -y silversearcher-ag fd-find
    # fd-find installs the binary as `fdfind` on Debian/Ubuntu; expose it as `fd`.
    mkdir -p ~/.local/bin
    ln -sf "$(command -v fdfind)" ~/.local/bin/fd
fi

# Set admin user home based on OS
if [[ "$OS" == "macos" ]]; then
    ADMIN_HOME="/Users/admin"
fi

if [[ "$OS" == "linux" ]]; then
    ADMIN_HOME="/root"
fi

# Link user configs
ln -sf ~/oh-my-zsh/.zshrc ~/.zshrc

# Create and link admin/root configs
sudo mkdir -p ~/.oh-my-zsh "$ADMIN_HOME"
sudo ln -sf ~/.oh-my-zsh "$ADMIN_HOME/.oh-my-zsh"
sudo ln -sf ~/oh-my-zsh/.zshrc "$ADMIN_HOME/.zshrc"

touch ~/.secrets.sh
touch ~/.temporary-global-envs.sh

# Themes
if [ ! -f ~/.oh-my-zsh/themes/punctual.zsh-theme ]; then
    wget -O ~/.oh-my-zsh/themes/punctual.zsh-theme https://raw.githubusercontent.com/dannynimmo/punctual-zsh-theme/v0.1.0/punctual.zsh-theme
fi

# Plugins
if [ ! -d ~/.oh-my-zsh/custom/plugins/zsh-better-npm-completion ]; then
    git clone https://github.com/lukechilds/zsh-better-npm-completion ~/.oh-my-zsh/custom/plugins/zsh-better-npm-completion
fi

if [ ! -d ~/.oh-my-zsh/custom/plugins/fzf ]; then
    git clone https://github.com/junegunn/fzf.git ~/.oh-my-zsh/custom/plugins/fzf
    ~/.oh-my-zsh/custom/plugins/fzf/install --bin
fi

if [ ! -d ~/.oh-my-zsh/custom/plugins/fzf-zsh ]; then
    git clone https://github.com/Treri/fzf-zsh.git ~/.oh-my-zsh/custom/plugins/fzf-zsh
fi

exec zsh
