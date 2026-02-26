#!/bin/bash

function ai-changelog() {
  if [[ -t 0 ]] || [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  ai-changelog [-h | --help]"
    echo "  git show HEAD~1 | ai-changelog"
    echo "  git diff HEAD~1 | ai-changelog"
    echo ""
    echo "Description:"
    echo "  Generates a changelog summary in bullet points from a git show/diff using AI"
    return
  fi

  local diff
  diff=$(cat)

  local prompt="Generate a changelog with the best practices, summarizing the following git show/info into concise bullet points:

  $diff"

  ai-request "$prompt" "gpt-4.1"
}
