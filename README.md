# oh-my-zsh

Cross-platform zsh configuration, CLI scripts, and shared shell libraries. The foundation repo that other tooling repos depend on.

## Setup

```bash
./init.sh    # Install zsh and oh-my-zsh
./init2.sh   # Set zsh as default shell (requires reboot)
./init3.sh   # Install themes, plugins, and dependencies
```

The scripts install zsh, oh-my-zsh, themes (powerlevel10k), plugins (zsh-autosuggestions, zsh-syntax-highlighting), and symlink `.zshrc` to `~/.zshrc`. All steps are idempotent.

## What It Provides

- **Shell config** (`.zshrc`) -- aliases, environment variables, prompt theme, and more
- **CLI scripts** (`commands/`) -- AI tools, AWS utilities, diff/review helpers, clipboard, Jira, Mermaid
- **Shared libraries** (`lib/`) -- OS detection, clipboard integration, tmux helpers, used by other repos

## Platforms

- **macOS**: zsh and dependencies via Homebrew
- **Linux**: zsh and dependencies via apt

## Part of

Five-repo tooling stack: [unix-utils](https://github.com/brunogsa/unix-utils) | **oh-my-zsh** | [tmux](https://github.com/brunogsa/tmux) | [neovim](https://github.com/brunogsa/neovim) | [ghostty](https://github.com/brunogsa/ghostty)
