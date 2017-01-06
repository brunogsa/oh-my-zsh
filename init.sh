#!/bin/bash

# Dependencies
sudo apt-get update && sudo apt-get upgrade
sudo apt install -y zsh

# Install it
wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
sudo chmod +x install.sh
sudo ./install.sh
chsh -s $(which zsh)
