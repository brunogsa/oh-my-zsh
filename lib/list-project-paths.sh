#!/usr/bin/env bash
# list-project-paths - List files and directories relative to cwd
#
# Usage:
#   list-project-paths [directory]
#
# In a git repo: lists all tracked/untracked paths from the repo root.
# Outside a git repo: lists paths up to NON_GIT_MAX_DEPTH levels deep.
# Paths are always relative to the given directory (or cwd if omitted).
#
# Examples:
#   list-project-paths                  # from cwd
#   list-project-paths /some/folder     # from specific directory

NON_GIT_MAX_DEPTH=4
FD=(fd --hidden --follow --exclude .git --exclude node_modules --exclude vendor --exclude dist --exclude build --exclude .next --exclude out --exclude coverage --exclude .cache --exclude html)

list_project_paths() {
  local base_dir="${1:-$(pwd)}"

  to_relative_paths() {
    python3 -c "
import sys, os
base = sys.argv[1]
for line in sys.stdin:
    print(os.path.relpath(line.strip(), base))
" "$base_dir"
  }

  local search_root
  if search_root=$(git -C "$base_dir" rev-parse --show-toplevel 2>/dev/null); then
    "${FD[@]}" . "$search_root" 2>/dev/null | to_relative_paths
  else
    "${FD[@]}" --max-depth "$NON_GIT_MAX_DEPTH" . "$base_dir" 2>/dev/null | to_relative_paths
  fi
}
