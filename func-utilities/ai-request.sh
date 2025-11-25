#!/bin/bash

function ai-request() {
  local prompt="$1"
  local model="${2:-o4-mini}"

  # 1. Try OpenAI (gpt-4o)
  ##########################################################
  # gpt-4o
  # o4-mini

  local openai_json
  openai_json=$(jq -n \
    --arg model "$model" \
    --arg prompt "$prompt" \
    '{
      model: $model,
      messages: [
        { role: "system", content: $prompt }
      ]
    }')

  local openai_response
  openai_response=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$openai_json")

  local openai_error_code
  openai_error_code=$(jq -r '.error.code // empty' <<< "$openai_response")

  if [[ -z "$openai_error_code" ]]; then
    jq -r '.choices[0].message.content' <<< "$openai_response"
    return 0
  fi

  if [[ "$openai_error_code" == "insufficient_quota" ]]; then
    echo "OpenAI quota exceeded – falling back to Claude Sonnet..."
  else
    echo "OpenAI error ($openai_error_code): $(jq -r '.error.message' <<< "$openai_response")"
    return 1
  fi

  # 2. Fallback to Anthropic Claude (Sonnet)
  ##########################################################
  local anthropic_json
  anthropic_json=$(jq -n \
    --arg prompt "$prompt" \
    '{
      model: "claude-3-7-sonnet-latest",
      max_tokens: 8192,
      temperature: 0.2,
      messages: [
      { role: "user", content: $prompt }
      ]
    }')

  local anthropic_response
  anthropic_response=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $ANTHROPIC_API_KEY" \
    -H "anthropic-version: 2023-06-01" \
    -H "Content-Type: application/json" \
    -d "$anthropic_json")

  local anthropic_error
  anthropic_error=$(jq -r '.error.type // empty' <<< "$anthropic_response")

  if [[ -z "$anthropic_error" ]]; then
    jq -r '.content[0].text' <<< "$anthropic_response"
    return 0
  fi

  if [[ "$anthropic_error" == "over_rate_limit_error" || "$anthropic_error" == "insufficient_quota" ]]; then
    echo "Claude Sonnet also ran out of quota. Aborting."
  else
    echo "Anthropic error ($anthropic_error): $(jq -r '.error.message // .error' <<< "$anthropic_response")"
  fi

  return 1
}
