#!/bin/bash

function diff-sorted-jsons () {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: diff-sorted-json <fileA> <fileB> [field1,field2,...]"
    return 1
  fi

  local fileA="$1"
  local fileB="$2"
  local fields="$3"

  local sortedFileA="/tmp/sorted-$(basename "$fileA")"
  local sortedFileB="/tmp/sorted-$(basename "$fileB")"

  ~/oh-my-zsh/json-deep-sort.js "$fileA" "$fields" > "$sortedFileA"
  ~/oh-my-zsh/json-deep-sort.js "$fileB" "$fields" > "$sortedFileB"

  meld "$sortedFileA" "$sortedFileB"
}
