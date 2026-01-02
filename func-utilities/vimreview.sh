#!/bin/bash

vimreview() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  vimreview                  Open Neovim with Diffview showing staged changes"
    echo "  vimreview <REV>           Open Neovim with Diffview comparing against <REV>"
    echo "  git diff ... | vimreview  Open Neovim with diff of piped input (fallback viewer)"
    echo
    echo "Examples:"
    echo "  vimreview HEAD~3"
    echo "  git diff HEAD~3 | vimreview"
    return
  fi

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not inside a Git repository." >&2
    return 1
  fi

  if [ ! -t 0 ]; then
    local tmpfile="/tmp/vimreview-$(date +%s)-$$.diff"
    cat > "$tmpfile"
    nvim -c "tabnew $tmpfile" -c "set filetype=diff"
    return
  fi

  local dummy_file
  dummy_file=$(git ls-files | head -n 1)
  if [[ -z "$dummy_file" ]]; then
    echo "Error: No tracked files found." >&2
    return 1
  fi

  local cmd="DiffviewOpen"
  [[ $# -eq 0 ]] && cmd+=" $1"

  nvim "$dummy_file" -c "$cmd"
}
