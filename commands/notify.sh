#!/bin/bash
# notify - Cross-platform desktop notification
#
# Usage:
#   notify <message> [title]
#
# Examples:
#   notify "Build complete"
#   notify "Tests failed" "CI"
#   long-command; notify "Finished!"
#   make build && notify "Build OK" || notify "Build failed"

# shellcheck source=../lib/detect-os.sh
source ~/oh-my-zsh/lib/detect-os.sh

function notify() {
  local message="$1"
  local title="${2:-Notification}"

  if [[ -z "$message" ]]; then
    echo "Usage: notify <message> [title]" >&2
    return 1
  fi

  local os
  os=$(detect_os)

  case "$os" in
    macos)
      osascript -e "display alert \"$title\" message \"$message\"" 2>/dev/null
      ;;
    linux)
      notify-send "$title" "$message" 2>/dev/null
      ;;
    *)
      echo "WARNING: Could not detect OS (got '$os'). Notification not sent: [$title] $message" >&2
      return 1
      ;;
  esac
}
