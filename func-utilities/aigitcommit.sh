#!/bin/bash

function aigitcommit() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  aigitcommit [--no-verify]"
    echo ""
    echo "Description:"
    echo "  Generates a commit message from staged changes,"
    echo "  then opens your editor with the message pre-filled before committing."
    return
  fi

  local no_verify=""
  if [[ "$1" == "--no-verify" ]]; then
    no_verify="--no-verify"
  fi

  local diff
  diff=$(git diff --cached)

  if [[ -z "$diff" ]]; then
    echo "No staged changes found. Use 'git add' first."
    return 1
  fi

  local prompt="Write a clear and concise Git commit message (max 72 characters in the subject line), based on the following staged diff. Use imperative tone, follow conventional commit style with scope, then below the subject line add a changelog in bullets.

  $diff"

  local message
  message=$(ai-request "$prompt")

  # Write message to temp file
  local msgfile
  msgfile=$(mktemp)
  echo "$message" > "$msgfile"

  # Open editor with pre-filled message before committing
  git commit $no_verify --edit -F "$msgfile"

  # Clean up temp file
  rm -f "$msgfile"
}
