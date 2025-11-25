#!/bin/bash

function estimate_tokens() {
  local file="$1"
  local char_count word_count
  char_count=$(wc -c < "$file" | tr -d ' ')
  word_count=$(wc -w < "$file" | tr -d ' ')

  # Two common estimation methods:
  # Method 1: ~4 characters per token (for code/technical content)
  # Method 2: ~0.75 words per token (for natural language)
  local tokens_by_chars=$((char_count / 4))
  local tokens_by_words=$((word_count * 3 / 4))

  # Use the higher estimate to be conservative
  local estimated_tokens=$((tokens_by_chars > tokens_by_words ? tokens_by_chars : tokens_by_words))

  echo "$estimated_tokens"
}
