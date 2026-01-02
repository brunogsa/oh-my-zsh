#!/bin/bash

function aicmd() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    echo "Usage: aicmd 'prompt'"
    echo "  - Generates a Linux command that fulfils <prompt>."
    echo "  - Prints the command followed by brief bullet explanations."
    echo "  - Copies only the command (first line) to your clipboard."
    echo
    echo "Example:"
    echo "  aicmd 'recursively find and delete all .DS_Store files'"
    return
  fi

  local user_prompt="$*"

  local oa_prompt="You are an expert Linux shell user. Respond **exactly** in this format:

  <command>

  - bullet 1
  - bullet 2
  - …

  Rules:
  * The **first line must contain only the command**. Do **not** wrap anything in backticks ( \` ), code fences ( \`\`\` ), or other Markdown formatting.
  * Do **not** prefix the command with \"bash$ \" or similar.
  * Bullets must start with a single hyphen and a space, be concise, and avoid backticks.
  * Never include triple backticks anywhere in the reply.

  Task:

  $user_prompt"

  local result
  result=$(ai-request "$oa_prompt" "gpt-4.1") || {
    echo "ai-request failed." >&2
    return 1
  }

  local cmd info
  cmd=$(printf '%s\n' "$result" | head -n1)
  info=$(printf '%s\n' "$result" | tail -n +2)

  printf '%s\n%s\n' "$cmd" "$info"

  printf '%s' "$cmd" | copyq copy -
}
