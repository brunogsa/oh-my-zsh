# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

Personal oh-my-zsh configuration: `.zshrc` + custom shell functions + installation scripts. Part of a five-repo tooling stack (`unix-utils`, `oh-my-zsh`, `tmux`, `neovim`, `ghostty`).

Untracked locals sourced by `.zshrc` if present:
- `.secrets.sh` -- API keys (`$ANTHROPIC_API_KEY`, `$OPENAI_API_KEY`, etc.)
- `.temporary-global-envs.sh` -- throwaway per-machine env vars

## Setup

```bash
./init.sh    # oh-my-zsh itself
./init2.sh   # set zsh as default shell
./init3.sh   # themes, plugins, dependencies
```

All auto-detect OS (macOS/Linux).

## Performance Guard

After any change to `.zshrc`, plugins, `commands/`, or `lib/`, run:

```bash
./profiler.sh              # per-file startup time breakdown
./profiler.sh --top 5      # just the 5 slowest
```

**Baseline first_prompt: ~200ms. If total exceeds ~300ms, investigate before committing.** Common traps: sourcing slow executables instead of defining functions, subprocess calls in top-level code (`$(command)`), eager-loading version managers. Results match `zsh-bench`'s `first_prompt_lag_ms` within ~10%.

## AI Function Architecture

The `ai-*` family (`ai-request`, `aigitcommit`, `aicmd`, `aiyank`, `aiappend`, etc.) shares a provider-fallback pattern:
1. Try Anthropic (Claude Haiku 4.5) first.
2. On quota error (HTTP 529), fall back to OpenAI (o4-mini).
3. Return specific error messages for other failures.

Key lookup via `$ANTHROPIC_API_KEY` / `$OPENAI_API_KEY` (set in `.secrets.sh`).

## Testing Shell Functions

```bash
source ~/.zshrc                            # reload after edits
aicmd "find all JavaScript files"          # exercise a function directly
```
