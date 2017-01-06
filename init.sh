#!/bin/bash

# Dependencies
sudo apt-get update && sudo apt-get upgrade
sudo apt install -y zsh

# Install it
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
chsh -s $(which zsh)
sudo su
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
chsh -s $(which zsh)
exit

# Use my configs
sudo rm -f ~/.zshrc
sudo ln -s ~/oh-my-zsh/.zshrc ~/.zshrc
sudo ln -s ~/.oh-my-zsh /root/.oh-my-zsh
sudo ln -s ~/oh-my-zsh/.zshrc /root/.zshrc

# Themes
cd ~/.oh-my-zsh/themes/
wget https://raw.githubusercontent.com/dannynimmo/punctual-zsh-theme/v0.1.0/punctual.zsh-theme
cd -

# Plugin
cd ~/.oh-my-zsh/custom/plugins
git clone https://github.com/psprint/history-search-multi-word
git clone https://github.com/akoenig/npm-run.plugin.zsh
git clone https://github.com/lukechilds/zsh-better-npm-completion
cd -

echo "Done!"
