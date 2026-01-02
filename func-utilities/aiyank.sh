#!/bin/bash

function aiyank() {
  if [[ "$1" == "-h" || "$1" == "--help" || $# -eq 0 && -t 0 ]]; then
    echo "Usage: aiyank [fileA fileB ...] or via pipe"
    echo
    echo "Examples:"
    echo "  aiyank fileA.yaml fileB.json"
    echo "  ls | aiyank"
    return
  fi

  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$git_root" ]]; then
    echo "Error: not inside a git repository" >&2
    return 1
  fi

  local files=()

  if [[ $# -gt 0 ]]; then
    files=("$@")
  else
    # Read from pipe
    while IFS= read -r line; do
      [[ -n "$line" ]] && files+=("$line")
    done
  fi

  local rel_paths=()
  for f in "${files[@]}"; do
    if [[ -e "$f" ]]; then
      abs_path=$(realpath "$f")
      rel_path=$(python3 -c "import os; print(os.path.relpath('$abs_path', '$git_root'))")
      rel_paths+=("$rel_path")
    else
      echo "Warning: file '$f' does not exist" >&2
    fi
  done

  local result="${rel_paths[*]}"
  echo "$result"
  printf "%s" "$result" | copyq copy -
  echo "Copied to clipboard."
}
