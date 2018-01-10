#!/bin/bash
set -e

# Dependencies
sudo apt-get update && sudo apt-get upgrade
sudo apt install -y zsh

# Install it
wget -q0- https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh | bash
sudo chsh -s $(which zsh)
chsh -s $(which zsh)
sudo reboot
