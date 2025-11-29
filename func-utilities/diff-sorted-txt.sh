#!/bin/bash

function diff-sorted-txt () {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: diff-sorted-txt <fileA> <fileB>"
    return 1
  fi

  local fileA="$1"
  local fileB="$2"

  local sortedFileA="/tmp/sorted-$(basename "$fileA")"
  local sortedFileB="/tmp/sorted-$(basename "$fileB")"

  sort "$fileA" > "$sortedFileA"
  sort "$fileB" > "$sortedFileB"

  meld "$sortedFileA" "$sortedFileB"
}
