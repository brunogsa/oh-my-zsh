#!/bin/bash

function compile-gantt-mermaid () {
  if [ -z "$1" ]; then
    echo "Usage: compile-gantt-mermaid <mermaid_file> [width]"
    return 1
  fi

  mermaidFile="$1"
  width="${2:-2048}"

  fileName=$(echo "$mermaidFile" | cut -d '.' -f 1)

  mmdc -i "$mermaidFile" -o "${fileName}.svg" --scale 4 --width "$width"
}
