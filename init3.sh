#!/bin/bash
set -e

# Use my configs
rm -f ~/.zshrc
sudo rm -f /root/.zshrc
sudo rm -fr /root/.oh-my-zsh

ln -s ~/oh-my-zsh/.zshrc ~/.zshrc
sudo ln -s ~/.oh-my-zsh /root/.oh-my-zsh
sudo ln -s ~/oh-my-zsh/.zshrc /root/.zshrc

# Themes
wget https://raw.githubusercontent.com/dannynimmo/punctual-zsh-theme/v0.1.0/punctual.zsh-theme
rm -f ~/.oh-my-zsh/themes/*
mv -f punctual.zsh-theme ~/.oh-my-zsh/themes/

# Plugin
sudo rm -fr ~/.oh-my-zsh/custom/plugins/*

git clone https://github.com/lukechilds/zsh-better-npm-completion
mv -f zsh-better-npm-completion ~/.oh-my-zsh/custom/plugins/

sudo apt-get install silversearcher-ag -y

git clone https://github.com/junegunn/fzf.git
mv -f fzf ~/.oh-my-zsh/custom/plugins/
~/.oh-my-zsh/custom/plugins/fzf/install --bin

git clone https://github.com/Treri/fzf-zsh.git
mv -f fzf-zsh ~/.oh-my-zsh/custom/plugins/

sudo reboot
