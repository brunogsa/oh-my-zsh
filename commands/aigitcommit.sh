#!/bin/bash

function aigitcommit() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  aigitcommit [--no-verify] [context]"
    echo ""
    echo "Description:"
    echo "  Generates a commit message from staged changes,"
    echo "  then opens your editor with the message pre-filled before committing."
    echo ""
    echo "  context: optional string describing what the changes are about,"
    echo "           used to generate a better commit message."
    echo ""
    echo "Examples:"
    echo "  aigitcommit"
    echo "  aigitcommit 'added cross-platform notification hooks'"
    echo "  aigitcommit --no-verify 'fix clipboard in non-interactive shells'"
    return
  fi

  local no_verify=""
  local context=""
  for arg in "$@"; do
    if [[ "$arg" == "--no-verify" ]]; then
      no_verify="--no-verify"
    else
      context="$arg"
    fi
  done

  local diff
  diff=$(git diff --cached)

  if [[ -z "$diff" ]]; then
    echo "No staged changes found. Use 'git add' first."
    return 1
  fi

  local context_section=""
  if [[ -n "$context" ]]; then
    context_section="

Context about these changes: $context"
  fi

  local prompt="Write a clear and concise Git commit message (max 72 characters in the subject line), based on the following staged diff. Use imperative tone, follow conventional commit style with scope, then below the subject line add a changelog in bullets.${context_section}

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
