#!/bin/bash
set -e

# Dependency on mac
brew install coreutils

ln -sf ~/oh-my-zsh/.zshrc ~/.zshrc
sudo ln -sf ~/.oh-my-zsh /Users/admin/.oh-my-zsh
sudo ln -sf ~/oh-my-zsh/.zshrc /Users/admin/.zshrc

# Themes
wget https://raw.githubusercontent.com/dannynimmo/punctual-zsh-theme/v0.1.0/punctual.zsh-theme
mv -f punctual.zsh-theme ~/.oh-my-zsh/themes/

# Plugin
sudo rm -fr ~/.oh-my-zsh/custom/plugins/*

git clone https://github.com/lukechilds/zsh-better-npm-completion
mv -f zsh-better-npm-completion ~/.oh-my-zsh/custom/plugins/

git clone https://github.com/junegunn/fzf.git
mv -f fzf ~/.oh-my-zsh/custom/plugins/
~/.oh-my-zsh/custom/plugins/fzf/install --bin

git clone https://github.com/Treri/fzf-zsh.git
mv -f fzf-zsh ~/.oh-my-zsh/custom/plugins/

sudo reboot
