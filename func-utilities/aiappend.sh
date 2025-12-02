#!/bin/bash

function aiappend() {
  # Internal function to display help
  function _show_help() {
    echo "aiappend - Append useful context to the global Aider context file"
    echo
    echo "Usage:"
    echo "  aiappend [options]"
    echo
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -c, --clipboard  Append clipboard content to the global context file"
    echo "  -o, --output     Append the last command output, the command itself, and its exit code"
    echo
    echo "Examples:"
    echo "  aiappend --clipboard"
    echo "  aiappend --output"
  }

  # Internal function to get clipboard content
  function _get_clipboard() {
    if command -v pbpaste &> /dev/null; then
      # macOS
      pbpaste
    elif command -v wl-paste &> /dev/null; then
      # Wayland
      wl-paste
    elif command -v xclip &> /dev/null; then
      # X11
      xclip -selection clipboard -o
    else
      echo "Error: No clipboard command found (pbpaste, wl-paste, or xclip)" >&2
      return 1
    fi
  }

  # Internal function to handle clipboard content
  function _handle_clipboard() {
    local context_file="$1"
    local content
    content=$(_get_clipboard)

    if [[ -z "$content" ]]; then
      echo "Error: Clipboard is empty" >&2
      return 1
    fi

    # Append clipboard content directly without headers or code blocks
    echo -e "\n${content}" >> "$context_file"
    echo "Appended clipboard content to $context_file"
  }

  # Internal function to handle last command output
  function _handle_output() {
    local context_file="$1"
    # Get the last command from history
    local last_cmd
    last_cmd=$(fc -ln -1 | sed 's/^\s*//')

    # Skip if the last command was aiappend itself
    if [[ "$last_cmd" == "aiappend"* ]]; then
      last_cmd=$(fc -ln -2 | sed 's/^\s*//')
    fi

    # Execute the command again to capture output and exit code
    local output
    local exit_code

    output=$(eval "$last_cmd" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}

    # Append command and output in a more concise format
    echo -e "\n\$ ${last_cmd}\n\n${output}\n\nExit Code: ${exit_code}" >> "$context_file"

    echo "Appended command '$last_cmd' and its output to $context_file"
  }

  # Default location for the global Aider context file
  local CONTEXT_FILE="${HOME}/.claude/CLAUDE.md"

  # Create context file if it doesn't exist
  if [[ ! -f "$CONTEXT_FILE" ]]; then
    touch "$CONTEXT_FILE"
    echo "Created new context file at $CONTEXT_FILE"
  fi

  # Parse arguments
  if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    _show_help
    return 0
  fi

  case "$1" in
    -c|--clipboard)
      _handle_clipboard "$CONTEXT_FILE"
      ;;
    -o|--output)
      _handle_output "$CONTEXT_FILE"
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      _show_help
      return 1
      ;;
  esac
}
