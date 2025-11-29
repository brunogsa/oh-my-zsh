#!/bin/bash

function search-replace-vim() {
  local pattern="$1"
  local replace="$2"

  if [ -z "$pattern" ] || [ -z "$replace" ]; then
    echo "Usage: search-replace-vim <search_pattern> <replace_pattern>"
    return 1
  fi

  # Use the 'rg' alias (assumes it already filters out large folders)
  local files
  files=$(rg --files-with-matches "$pattern" | sort -u)

  if [ -z "$files" ]; then
    echo "No matches found for '$pattern'"
    return 1
  fi

  echo "Found files:"
  echo "$files"
  echo

  # Use /dev/tty for prompts to avoid stdin conflicts
  while IFS= read -r file; do
    local bold_file="\033[1m$file\033[0m"
    echo -ne "Open $bold_file in Neovim for search & replace? (y/n/q): " > /dev/tty
    read -r choice < /dev/tty
    choice=${choice:-y}  # default to 'y'

    if [[ "$choice" == "q" ]]; then
      echo "Quit!"
      return 0
    elif [[ "$choice" == "n" ]]; then
      echo "Skipping $file."
    else
      nvim +"%s/$pattern/$replace/gc" -- "$file"
    fi
  done <<< "$files"
}
