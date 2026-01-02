#!/bin/bash
set -e

# Dependencies
brew install zsh

# Install it
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
