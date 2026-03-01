#!/usr/bin/env bash
# tmux-pane-words-picker - Pick a word or filepath from visible tmux panes via fzf popup
#
# Two modes:
#   (no args)  - Pick mode: runs inside tmux popup, shows fzf, writes selection to temp file
#   --send     - Send mode: runs after popup closes, sends selection to the original pane
#
# Examples:
#   bind Tab run-shell "printf '%s %s %s' '#{cursor_x}' '#{cursor_y}' '#{pane_id}' > /tmp/tmux-picker-context && tmux capture-pane -p > /tmp/tmux-cursor-pane" \; \
#       display-popup -d '#{pane_current_path}' -E "~/oh-my-zsh/lib/tmux-pane-words-picker.sh" \; \
#       run-shell -b "~/oh-my-zsh/lib/tmux-pane-words-picker.sh --send"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# tmux's display-popup runs commands using the server's PATH, not an interactive
# shell's. The oh-my-zsh fzf plugin only adds its bin/ to PATH in .zshrc, so fzf
# is invisible to tmux-spawned processes.
export PATH="$HOME/.oh-my-zsh/custom/plugins/fzf/bin:$PATH"

RESULT_FILE="/tmp/tmux-pane-words-result"
CONTEXT_FILE="/tmp/tmux-picker-context"
PANE_FILE="/tmp/tmux-cursor-pane"

# --- Send mode: deliver result to original pane, then cleanup ---

send_mode() {
  if [[ ! -f "$RESULT_FILE" || ! -f "$CONTEXT_FILE" ]]; then
    return
  fi

  local cursor_x cursor_y pane_id
  read -r cursor_x cursor_y pane_id < "$CONTEXT_FILE"

  local selected prefix_len
  selected=$(cat "$RESULT_FILE")
  prefix_len=$(cat /tmp/tmux-prefix-len 2>/dev/null || echo 0)

  for ((i = 0; i < prefix_len; i++)); do
    tmux send-keys -t "$pane_id" BSpace
  done

  tmux send-keys -t "$pane_id" -l "$selected"
  rm -f "$RESULT_FILE" "$CONTEXT_FILE" "$PANE_FILE" /tmp/tmux-prefix-len
}

if [[ "$1" == "--send" ]]; then
  send_mode
  exit 0
fi

# --- Pick mode: runs inside tmux popup ---

source "$SCRIPT_DIR/list-project-paths.sh"

# display-popup -d sets our $PWD to the active pane's working directory
PANE_CWD=$(pwd)

extract_prefix() {
  if [[ ! -f "$CONTEXT_FILE" || ! -f "$PANE_FILE" ]]; then
    return
  fi

  local cursor_x cursor_y _pane_id line prefix_region
  read -r cursor_x cursor_y _pane_id < "$CONTEXT_FILE"
  line=$(sed -n "$((cursor_y + 1))p" "$PANE_FILE")
  prefix_region="${line:0:$cursor_x}"
  grep -oE '[a-zA-Z0-9_./-]+$' <<< "$prefix_region"
}

capture_pane_words() {
  local panes
  panes=$(tmux list-panes -F '#D')

  for pane in $panes; do
    tmux capture-pane -J -p -t "$pane"
  done |
    sed 's/[^a-zA-Z0-9_/-]/ /g' |
    tr -s '[:space:]' '\n'
}

rm -f "$RESULT_FILE" /tmp/tmux-prefix-len

prefix=$(extract_prefix)
selected=$({ capture_pane_words; list_project_paths "$PANE_CWD"; } | awk '!seen[$0]++' | fzf --no-info --layout=reverse --prompt="word> " --query="$prefix")

if [[ -n "$selected" ]]; then
  printf '%s' "$selected" > "$RESULT_FILE"
  printf '%s' "${#prefix}" > /tmp/tmux-prefix-len
fi
