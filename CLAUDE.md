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
4. **AI Integration**: `ai-request`, `ai-changelog`, `aigitcommit`, `aicmd`, `aiyank`, `aicopy`, `aiappend`, `aireview`
5. **Git/Review Tools**: `vimreview`, `aireview`
6. **AWS Integration**: `aws-get-cloudwatch-logs`

### AI Function Architecture

The AI functions follow a consistent pattern:
- Use OpenAI API (gpt-4o, o4-mini) as primary provider
- Fallback to Anthropic Claude (claude-3-7-sonnet-latest) when OpenAI quota is exceeded
- API keys stored in environment variables: `$OPENAI_API_KEY`, `$ANTHROPIC_API_KEY`

### Code Review Workflow (`aireview`)

The `aireview` function is complex and performs:
1. Creates a temporary clone of the repo via SSH
2. Resolves git refs (supports branches, tags, origin/ prefixes)
3. Generates repo map using Aider (mandatory)
4. Collects changed files between merge-base and target ref
5. Excludes lockfiles from full content dumps
6. Extracts CODE and REVIEW sections from `~/.claude/CLAUDE.md` for review guidelines
7. Produces a comprehensive markdown bundle with:
   - Repository structure (via Aider's repo map)
   - Full content of modified files with line numbers
   - Git diff (excluding lockfiles)
   - Git context (log, diff --stat, show)
   - Code conventions and review instructions from CLAUDE.md
8. Copies bundle to clipboard with truncation verification
9. Estimates token count for LLM context

## Development Commands

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
- `aider` (AI code assistant - required for `aireview`)
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
source ~/oh-my-zsh/func-utilities/detect-os.sh
OS_TYPE=$(detect_os)
```

### Platform-Specific Behavior

**Package Management:**
- macOS: Uses `brew`
- Linux: Uses `apt-get`

**Clipboard:**
- Both platforms use `copyq` for clipboard operations
- Commands: `copyq copy -` (write from stdin), `copyq clipboard` (read to stdout)
- Installed via ~/linux-utils/install.sh on both platforms

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

### Aider Configuration

The `aid` alias configures Aider with specific settings:
- Uses gpt-4.1 models (41, 41m, 41n aliases)
- Reads from `~/.claude/CLAUDE.md` for conventions
- Subtree-only mode with 4096 token map
- Diff-based editing format
- No auto-commits, no attribution
- Editor: nvim with monokai theme
- Cache prompts with keepalive pings
- Skip SSL verification

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

The `ai-request` function handles retries:
1. Try OpenAI first
2. On quota error, fallback to Anthropic
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
- `aid` → full aider configuration with gpt-4.1 models
- `aidc` → aider with chat history restoration

## Environment Variables

Required for AI functions:
- `OPENAI_API_KEY` - OpenAI API authentication
- `ANTHROPIC_API_KEY` - Anthropic Claude API authentication
- `AWS_PROFILE` - AWS profile for CloudWatch functions
- `EDITOR`, `VISUAL`, `AIDER_EDITOR` - all set to `nvim`

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
