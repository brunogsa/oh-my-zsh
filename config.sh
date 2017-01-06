#!/bin/bash

# Use my configs
rm -f ~/.zshrc
sudo rm -f /root/.zshrc
sudo rm -fr /root/.oh-my-zsh

ln -s ~/oh-my-zsh/.zshrc ~/.zshrc
sudo ln -s ~/.oh-my-zsh /root/.oh-my-zsh
sudo ln -s ~/oh-my-zsh/.zshrc /root/.zshrc

# Themes
wget https://raw.githubusercontent.com/dannynimmo/punctual-zsh-theme/v0.1.0/punctual.zsh-theme
mv -f punctual.zsh-theme ~/.oh-my-zsh/themes/

# Plugin
git clone https://github.com/psprint/history-search-multi-word
mv -f history-search-multi-word ~/.oh-my-zsh/custom/plugins/

git clone https://github.com/akoenig/npm-run.plugin.zsh
mv -f npm-run.plugin.zsh ~/.oh-my-zsh/custom/plugins/

git clone https://github.com/lukechilds/zsh-better-npm-completion
mv -f zsh-better-npm-completion ~/.oh-my-zsh/custom/plugins/

echo "Done!"
