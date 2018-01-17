#!/bin/bash
set -e

sudo rm -f install.sh
sudo chsh -s $(which zsh)
chsh -s $(which zsh)
sudo reboot
