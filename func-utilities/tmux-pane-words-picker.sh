#!/usr/bin/env bash
# tmux-pane-words-picker - Pick a word from visible tmux panes via fzf popup
#
# Usage:
#   Bound to a tmux key. Opens fzf popup with all words from visible panes.
#   Selected word is sent to the active pane via send-keys.
#
# Examples:
#   bind Tab run-shell "~/oh-my-zsh/func-utilities/tmux-pane-words-picker.sh"

# Capture visible content from all panes in current window
capture_words() {
  local panes
  panes=$(tmux list-panes -F '#D')

  for pane in $panes; do
    tmux capture-pane -J -p -t "$pane"
  done
}

# Extract and deduplicate words
extract_words() {
  sed 's/[^a-zA-Z0-9_/-]/ /g' |
    tr -s '[:space:]' '\n' |
    sort -u
}

RESULT_FILE="/tmp/tmux-pane-words-result"
rm -f "$RESULT_FILE"

selected=$(capture_words | extract_words | fzf --no-sort --no-info --layout=reverse --prompt="word> ")

if [[ -n "$selected" ]]; then
  printf '%s' "$selected" > "$RESULT_FILE"
fi
