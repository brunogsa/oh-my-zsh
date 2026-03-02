# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a personal oh-my-zsh configuration repository containing shell customizations, utility functions, and development tools. The main configuration file is `.zshrc` which defines the shell environment, custom functions, and aliases.

## Key Files

- `.zshrc` - Main shell configuration file with custom functions and aliases
- `init.sh`, `init2.sh`, `init3.sh` - Installation scripts for setting up oh-my-zsh and dependencies
- `json-deep-sort.js` - Node.js utility for deep sorting JSON files by fields
- `.secrets.sh` - External file for secret environment variables (not tracked)
- `.temporary-global-envs.sh` - External file for temporary environment variables (not tracked)

## Architecture

### Custom Functions Organization

The `.zshrc` file contains numerous utility functions organized by purpose:

1. **Document Processing**: `compile-mermaid`, `compile-gantt-mermaid`, `gen-schema-from-json`
2. **File Comparison**: `diff-sorted-txt`, `diff-sorted-jsons`
3. **Code Utilities**: `search-replace-vim`, `node-debug-reminder`
4. **AI Integration**: `ai-request`, `ai-changelog`, `aigitcommit`, `aicmd`, `aiyank`, `aicopy`, `aiappend`
5. **Git/Review Tools**: `vimreview`
6. **AWS Integration**: `aws-get-cloudwatch-logs`

### AI Function Architecture

The AI functions follow a consistent pattern:
- Use Anthropic API (claude-haiku-4-5) as primary provider
- Fallback to OpenAI (o4-mini) when Anthropic quota is exceeded
- API keys stored in environment variables: `$ANTHROPIC_API_KEY`, `$OPENAI_API_KEY`

## Development Commands

### Profiling Startup Time

```bash
./profiler.sh              # per-file startup time breakdown
./profiler.sh --top 5      # just the 5 slowest
./profiler.sh --raw        # raw xtrace log for manual analysis
```

Runs a full login shell with xtrace timestamps (same as tmux new pane) and aggregates wall time per source file. Use this to identify startup bottlenecks -- results match `zsh-bench` `first_prompt_lag_ms` within ~10%.

### Performance Guard

After any change to `.zshrc`, plugins, `commands/`, or `lib/`, run the profiler to catch regressions:

```bash
./profiler.sh
```

Baseline first_prompt is ~200ms. If the total exceeds ~300ms, investigate before committing. Common traps: sourcing slow executables instead of defining functions, subprocess calls in top-level code (`$(command)`), and eager-loading version managers.

### Testing Shell Functions

Source the `.zshrc` to reload functions:
```bash
source ~/.zshrc
```

Test individual functions by calling them directly:
```bash
aicmd "find all JavaScript files"
```

### Installation

Run installation scripts in order:
```bash
./init.sh    # Install oh-my-zsh
./init2.sh   # Set zsh as default shell (requires reboot)
./init3.sh   # Install themes, plugins, and dependencies
```

### Dependencies

Required external tools:
- `brew` (macOS) or `apt-get` (Linux) - package managers
- `nvim` (Neovim - aliased as vim)
- `rg` (ripgrep - configured with custom exclusions)
- `fzf` (fuzzy finder)
- `jq` (JSON processor)
- `git` with SSH access configured
- `meld` (diff viewer)
- `mmdc` (Mermaid CLI)
- `aws` CLI (for CloudWatch functions)
- `copyq` (cross-platform clipboard manager)

## Platform Support

This configuration supports both macOS and Linux.

### OS Detection

The `detect-os.sh` utility automatically detects the operating system:
- `macos` - macOS systems
- `linux` - Linux systems

Usage:
```bash
source ~/oh-my-zsh/lib/detect-os.sh
OS_TYPE=$(detect_os)
```

### Platform-Specific Behavior

**Package Management:**
- macOS: Uses `brew`
- Linux: Uses `apt-get`

**Clipboard:**
- Both platforms use `copyq` for clipboard operations
- Commands: `copyq copy -` (write from stdin), `copyq clipboard` (read to stdout)
- Installed via ~/unix-utils/install.sh on both platforms

**File Opener:**
- macOS: `open` (built-in command)
- Linux: `xdg-open` (via alias)

**Admin User:**
- macOS: `/Users/admin`
- Linux: `/root`

**AsyncAPI Autocomplete:**
- macOS: `$HOME/Library/Caches/@asyncapi/cli/autocomplete/zsh_setup`
- Linux: `$HOME/.cache/@asyncapi/cli/autocomplete/zsh_setup`

### Installation

Installation scripts detect OS automatically:
```bash
./init.sh    # Installs oh-my-zsh (auto-detects OS)
./init2.sh   # Sets zsh as default shell
./init3.sh   # Installs themes, plugins (auto-detects OS)
```

## Code Conventions

### Shell Function Structure

Functions follow this pattern:
1. Help/usage section with `-h` or `--help` flag
2. Input validation
3. Core logic with error handling
4. Output/return with cleanup

### Internal Helper Functions

Use nested functions for internal helpers within main functions (e.g., `_show_help`, `_get_clipboard` in `aiappend`):
```bash
function main_function() {
  function _internal_helper() {
    # helper logic
  }

  # main logic
  _internal_helper
}
```

### Error Handling

- Use `set -e` in shell scripts to exit on error
- Return non-zero exit codes for failures
- Write errors to stderr with `>&2`
- Provide clear error messages with context

### Clipboard Operations

Always use platform-agnostic clipboard commands with fallbacks:
```bash
if command -v pbcopy >/dev/null 2>&1; then
  pbcopy < "$file"
elif command -v wl-copy >/dev/null 2>&1; then
  wl-copy < "$file"
elif command -v xclip >/dev/null 2>&1; then
  xclip -selection clipboard < "$file"
fi
```

## Important Patterns

### Git Operations

- Always verify inside a git repository: `git rev-parse --is-inside-work-tree`
- Use merge-base for comparing branches: `git merge-base "$FROM_REF" "$TO_REF"`
- Prefer SSH URLs for git operations
- Handle origin/ prefix in branch names

### AI API Calls

The `ai-request` function handles provider fallback:
1. Try Anthropic (Haiku 4.5) first
2. On quota error (529), fallback to OpenAI (o4-mini)
3. Return specific error messages for other failures

### Temporary Files

Use `mktemp` for temporary files with cleanup:
```bash
local tmpfile=$(mktemp)
trap 'rm -f "$tmpfile"' EXIT
```

### File Processing

- Use `git show` with line numbers: `git show "${REF}:${file}" | cat -n`
- Exclude lockfiles from diffs using central LOCKFILES array
- Verify file existence before processing: `[[ -f "$file" ]]`

## Aliases

Key aliases to be aware of:
- `vim` → `nvim`
- `rg` → includes common exclusions (node_modules, .git, dist, build, etc.)
- `tree` → excludes same directories as rg
## Environment Variables

Required for AI functions:
- `OPENAI_API_KEY` - OpenAI API authentication
- `ANTHROPIC_API_KEY` - Anthropic Claude API authentication
- `AWS_PROFILE` - AWS profile for CloudWatch functions
- `EDITOR`, `VISUAL` - set to `nvim`

## Testing Utilities

### Node.js Debugging

Use `node-debug-reminder` to get debugger command reference for Jest tests.

### JSON Operations

Use `json-deep-sort.js` for sorting JSON:
```bash
~/oh-my-zsh/json-deep-sort.js file.json "field1,field2"
```

## Code Review Process

When making changes to shell functions:
1. Test the function in isolation
2. Verify error handling with invalid inputs
3. Check help text is comprehensive
4. Ensure clipboard operations work cross-platform
5. Test with and without required dependencies
6. Verify temporary file cleanup (no leaks)
