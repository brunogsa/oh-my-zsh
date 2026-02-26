#!/usr/bin/env bash
# Extracts the last Claude Code edit target and builds an nvim command
# Usage: Press tmux prefix + g (copy) or G (open in new window)

source ~/oh-my-zsh/func-utilities/copy.sh

tmux-extract-claude-change-place() {
  local with_line=false
  [[ "$1" == "--with-line" ]] && with_line=true

  local pane_content
  pane_content=$(tmux capture-pane -p -S -100)

  # Find the last Update(...) or Edit(...) pattern
  local last_edit_line_num
  last_edit_line_num=$(echo "$pane_content" | grep -nE '^⏺ (Update|Edit)\(' | tail -1 | cut -d: -f1)

  if [[ -z "$last_edit_line_num" ]]; then
    tmux display-message "No Claude edit found"
    return 1
  fi

  # Extract the file from that line
  local file
  file=$(echo "$pane_content" | sed -n "${last_edit_line_num}p" | grep -oE '(Update|Edit)\([^)]+\)' | sed 's/.*(\(.*\))/\1/')

  local result
  if $with_line; then
    # Extract first + line number from the diff block after the edit header
    local line
    line=$(echo "$pane_content" | tail -n +"$last_edit_line_num" | grep -oE '^\s+[0-9]+ \+' | head -1 | grep -oE '[0-9]+')
    line="${line:-1}"
    result="nvim +${line} ${file}"
  else
    result="$file"
  fi

  echo -n "$result" | copy
  tmux display-message "Copied: ${result}"
}
