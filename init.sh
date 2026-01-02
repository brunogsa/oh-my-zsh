#!/bin/bash
set -e

# Source OS detection
source ~/oh-my-zsh/func-utilities/detect-os.sh

OS=$(detect_os)
echo "Detected OS: $OS"

# Update package manager
if [[ "$OS" == "macos" ]]; then
    brew update
fi

if [[ "$OS" == "linux" ]]; then
    sudo apt-get update && sudo apt-get upgrade
fi

# Install zsh
if [[ "$OS" == "macos" ]]; then
    brew install zsh
fi

if [[ "$OS" == "linux" ]]; then
    sudo apt install -y zsh
fi

# Install oh-my-zsh
if [[ "$OS" == "macos" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
fi

if [[ "$OS" == "linux" ]]; then
    wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
    sudo chmod +x install.sh
    ./install.sh
fi
