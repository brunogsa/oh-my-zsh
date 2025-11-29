#!/bin/bash

function compile-mermaid () {
  if [ -z "$1" ]; then
    echo "Usage: compile-mermaid <mermaid_file>"
    return 1
  fi

  mermaidFile="$1"
  fileName=$(echo "$mermaidFile" | cut -d '.' -f 1)

  mmdc -i "$mermaidFile" -o "${fileName}.png" --scale 4
  # convert -trim "$fileName.png" "$fileName.png"
}
