#!/bin/bash
set -e

# Source OS detection
source ~/oh-my-zsh/lib/detect-os.sh
OS_TYPE=$(detect_os)

# OS-specific dependencies
if [[ "$OS_TYPE" == "macos" ]]; then
  brew install coreutils
fi

if [[ "$OS_TYPE" == "linux" ]]; then
  sudo apt-get install silversearcher-ag -y
fi

# Set admin user home based on OS
if [[ "$OS_TYPE" == "macos" ]]; then
  ADMIN_HOME="/Users/admin"
fi

if [[ "$OS_TYPE" == "linux" ]]; then
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
