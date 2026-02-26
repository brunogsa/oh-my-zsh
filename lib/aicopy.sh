#!/bin/bash

function aicopy() {
  # Show help if no args and no stdin, or explicit help flag
  if [[ "$1" == "-h" || "$1" == "--help" || ( $# -eq 0 && -t 0 ) ]]; then
    echo "Usage:"
    echo "  aicopy <file1> [file2 ...]"
    echo "  ls -1 | aicopy"
    echo "  rg --files | aicopy"
    echo
    echo "Description:"
    echo "  Copies file names and contents to the clipboard."
    echo "  Accepts file paths via arguments and/or stdin (one path per line)."
    echo "  Only regular files are allowed — directories are skipped with a warning."
    echo "  For each file: prints the file name, a blank line, then its content."
    echo "  Files are separated by two blank lines."
    return 0
  fi

  # Collect inputs from stdin and args
  local inputs=()
  if [ ! -t 0 ]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && inputs+=("$line")
    done
  fi
  if (( $# > 0 )); then
    inputs+=("$@")
  fi
  if (( ${#inputs[@]} == 0 )); then
    echo "Error: No files provided (args or stdin)." >&2
    return 1
  fi

  # Portable mktemp (BSD/GNU)
  local tmpfile tmpdir="${TMPDIR:-/tmp}"
  tmpfile=$(mktemp "$tmpdir/aicopy.XXXXXX" 2>/dev/null) \
    || tmpfile=$(mktemp -t aicopy 2>/dev/null) \
    || { echo "Error: failed to create temp file." >&2; return 1; }
  trap 'rm -f "$tmpfile"' EXIT

  # Process each file
  local processed=0 first=true file
  for file in "${inputs[@]}"; do
    if [[ -d "$file" ]]; then
      echo "Warning: '$file' is a directory, skipping..." >&2
      continue
    elif [[ ! -f "$file" ]]; then
      echo "Warning: '$file' is not a regular file, skipping..." >&2
      continue
    fi

    # Two empty lines between files (none before the first)
    if [[ "$first" != true ]]; then
      printf '\n\n' >> "$tmpfile"
    else
      first=false
    fi

    # File name, one blank line, then content
    printf '%s\n\n' "$file" >> "$tmpfile"
    if ! cat -- "$file" >> "$tmpfile"; then
      echo "Error: failed to read '$file'." >&2
      continue
    fi

    ((processed++))
  done

  if (( processed == 0 )); then
    echo "Error: No valid files were processed" >&2
    return 1
  fi

  # Copy to clipboard using copyq
  local rc=0 copied_with="copyq"
  cat "$tmpfile" | copy; rc=$?
  if (( rc != 0 )); then
    echo "Error: clipboard command failed (exit $rc)." >&2
    return $rc
  fi

  # Always verify clipboard contents to detect truncation
  # Bytes of what we intended to copy:
  local expected_bytes
  expected_bytes=$(wc -c < "$tmpfile" | tr -d ' ')

  # Bytes actually in the clipboard
  local pasted_bytes=""
  pasted_bytes=$(copyq clipboard 2>/dev/null | wc -c | tr -d ' ')

  if [[ -n "$pasted_bytes" ]] && (( pasted_bytes < expected_bytes )); then
    echo "Error: clipboard appears truncated (${pasted_bytes} of ${expected_bytes} bytes)." >&2
    echo "Hint: you may have hit a clipboard size limit. Try fewer/smaller files or split the copy." >&2
    return 1
  fi

  echo "Copied ${processed} file(s) to clipboard."
  # tmpfile auto-removed by trap
}
