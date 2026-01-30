#!/bin/bash

function compile-mermaid () {
  if [ -z "$1" ]; then
    echo "Usage: compile-mermaid <mermaid_file>"
    return 1
  fi

  mermaidFile="$1"
  fileName=$(echo "$mermaidFile" | cut -d '.' -f 1)

  # Generate SVG first to detect natural diagram dimensions
  mmdc -i "$mermaidFile" -o "${fileName}.svg"

  viewBox=$(grep -o 'viewBox="[^"]*"' "${fileName}.svg" | head -1)
  width=$(echo "$viewBox" | sed 's/.*viewBox="[^ ]* [^ ]* \([^ ]*\) .*/\1/' | awk '{printf "%d", $1 + 0.5}')
  height=$(echo "$viewBox" | sed 's/.*viewBox="[^ ]* [^ ]* [^ ]* \([^"]*\)".*/\1/' | awk '{printf "%d", $1 + 0.5}')

  if [ -z "$width" ] || [ "$width" -eq 0 ]; then
    width=800
    height=600
    echo "Could not parse viewBox, using default ${width}x${height}"
  else
    echo "Detected diagram dimensions: ${width}x${height}"
  fi

  mmdc -i "$mermaidFile" -o "${fileName}.png" --width "$width" --height "$height"
  rm -f "${fileName}.svg"
}
