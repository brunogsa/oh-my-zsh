#!/bin/bash
set -e

# Public-repo clones below don't need auth, but on macOS the git-credential-osxkeychain
# helper configured in /opt/homebrew/etc/gitconfig pops up a login-keychain dialog
# whenever a github.com fetch fails (e.g. a deprecated tap returning 404). Skip the
# system-level gitconfig so no helper is ever invoked, and block interactive prompts.
export GIT_CONFIG_NOSYSTEM=1
export GIT_TERMINAL_PROMPT=0

# shellcheck source=/dev/null
source ~/oh-my-zsh/lib/detect-os.sh

OS=$(detect_os)
echo "Detected OS: $OS"

# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: zsh + oh-my-zsh
# ─────────────────────────────────────────────────────────────────────────────

# Update package manager
if [[ "$OS" == "macos" ]]; then
    # homebrew/cask-fonts was deprecated in May 2024 and merged into homebrew/cask.
    # A stale tap makes `brew update` fail and triggers a keychain credential prompt.
    brew untap homebrew/cask-fonts 2>/dev/null || true
    brew update
fi

if [[ "$OS" == "linux" ]]; then
    sudo apt-get update && sudo apt-get upgrade -y
fi

# Install zsh
if [[ "$OS" == "macos" ]]; then
    brew install zsh
fi

if [[ "$OS" == "linux" ]]; then
    sudo apt install -y zsh
fi

# Install oh-my-zsh
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo "oh-my-zsh already installed, skipping"
elif [[ "$OS" == "macos" ]]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
elif [[ "$OS" == "linux" ]]; then
    wget -O /tmp/omz-install.sh https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh
    chmod +x /tmp/omz-install.sh
    /tmp/omz-install.sh
    rm /tmp/omz-install.sh
fi

# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: set zsh as default shell
# ─────────────────────────────────────────────────────────────────────────────

# chsh always prompts for a password even when the target shell equals the
# current one, so guard against unnecessary prompts on re-runs.
ZSH_PATH="$(which zsh)"
if [[ "$OS" == "macos" ]]; then
    CURRENT_SHELL="$(dscl . -read ~/ UserShell | awk '{print $2}')"
elif [[ "$OS" == "linux" ]]; then
    CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"
fi

if [ "$CURRENT_SHELL" != "$ZSH_PATH" ]; then
    chsh -s "$ZSH_PATH"
else
    echo "zsh is already the login shell, skipping chsh"
fi

# ─────────────────────────────────────────────────────────────────────────────
# Stage 3: themes, plugins, dependencies
# ─────────────────────────────────────────────────────────────────────────────

# OS-specific dependencies
if [[ "$OS" == "macos" ]]; then
    brew install coreutils fd
fi

if [[ "$OS" == "linux" ]]; then
    sudo apt-get install -y silversearcher-ag fd-find
    # fd-find installs the binary as `fdfind` on Debian/Ubuntu; expose it as `fd`.
    mkdir -p ~/.local/bin
    ln -sf "$(command -v fdfind)" ~/.local/bin/fd
fi

# Link user configs
ln -sf ~/oh-my-zsh/.zshrc ~/.zshrc

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

echo "install.sh finished successfully — launching fresh zsh session"
exec zsh
