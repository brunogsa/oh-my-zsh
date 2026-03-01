#!/bin/bash
# render-ascii-mermaid - Render Mermaid diagrams as Unicode box-drawing art
#
# Usage:
#   render-ascii-mermaid <file>
#   echo 'graph LR; A-->B-->C' | render-ascii-mermaid
#
# Examples:
#   render-ascii-mermaid diagram.mmd                           # from file
#   echo 'flowchart LR; A-->B-->C' | render-ascii-mermaid     # from stdin
#   echo 'sequenceDiagram; Alice->>Bob: Hello!' | render-ascii-mermaid

_RENDER_ASCII_MERMAID_SRC="${BASH_SOURCE[0]:-$0}"

function render-ascii-mermaid () {
  if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    sed -n '2,11p' "$_RENDER_ASCII_MERMAID_SRC" | sed 's/^# \?//'
    return 0
  fi

  local input
  if [ -n "$1" ]; then
    if [ ! -f "$1" ]; then
      echo "Error: file not found: $1" >&2
      return 1
    fi
    input=$(cat "$1")
  elif [ ! -t 0 ]; then
    input=$(cat)
  else
    echo "Error: provide a file argument or pipe mermaid text via stdin" >&2
    return 1
  fi

  local module_path
  module_path="$(npm root -g)/beautiful-mermaid/dist/index.js"

  node --input-type=module -e "
    import { renderMermaidAscii } from '${module_path}';
    process.stdout.write(renderMermaidAscii(process.argv[1]) + '\n');
  " "$input"
}
