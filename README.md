# oh-my-zsh

Cross-platform zsh configuration, CLI scripts, and shared shell libraries. The foundation repo that other tooling repos depend on.

## Setup

```bash
./install.sh
```

Installs zsh + oh-my-zsh, sets zsh as the default shell, installs themes (punctual) and plugins (fzf, fzf-zsh, zsh-better-npm-completion), symlinks `.zshrc` to `~/.zshrc`, and ends with `exec zsh` to drop the terminal into the configured shell. Idempotent; safe to re-run.

## Profiling

```bash
./profiler.sh              # per-file startup time breakdown (top 25)
./profiler.sh --top 5      # just the 5 slowest files
./profiler.sh --raw        # raw xtrace log path for manual analysis
```

Uses xtrace timestamps on a full login shell (the same kind tmux spawns) to produce accurate wall-time-per-file numbers. Results match `zsh-bench` `first_prompt_lag_ms` within ~10%.

## What It Provides

- **Shell config** (`.zshrc`) -- aliases, environment variables, prompt theme, and more
- **CLI scripts** (`commands/`) -- AI tools, AWS utilities, diff/review helpers, clipboard, Jira, Mermaid
- **Shared libraries** (`lib/`) -- OS detection, clipboard integration, tmux helpers, used by other repos

## Platforms

- **macOS**: zsh and dependencies via Homebrew
- **Linux**: zsh and dependencies via apt

## Part of

Five-repo tooling stack: [unix-utils](https://github.com/brunogsa/unix-utils) | **oh-my-zsh** | [tmux](https://github.com/brunogsa/tmux) | [neovim](https://github.com/brunogsa/neovim) | [ghostty](https://github.com/brunogsa/ghostty)
