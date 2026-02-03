#!/bin/bash

function aws-get-dlq-summary() {
  # Show help
  if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-v" || "$1" == "--version" ]]; then
    echo "aws-get-dlq-summary - Get DLQ queue attributes and peek at messages"
    echo
    echo "Usage:"
    echo "  AWS_PROFILE=<profile> aws-get-dlq-summary --queue-url <url> [--peek <N>]"
    echo "  AWS_PROFILE=<profile> aws-get-dlq-summary --queue-name <name> [--peek <N>]"
    echo "  aws-get-dlq-summary -h | --help"
    echo
    echo "Parameters:"
    echo "  --queue-url <url>     - Full SQS queue URL (mutually exclusive with --queue-name)"
    echo "  --queue-name <name>   - SQS queue name, resolved to URL via aws sqs get-queue-url"
    echo "  --peek <N>            - (Optional) Number of messages to peek at (default: 1, max: 10)"
    echo "                          Uses visibility-timeout 0 so messages are NOT consumed."
    echo "                          FIFO queues are limited to 1 message per peek (enforced automatically)."
    echo
    echo "Environment:"
    echo "  AWS_PROFILE           - AWS profile to use (required)"
    echo
    echo "Output:"
    echo "  Structured text with:"
    echo "  1. Queue attributes: message count, in-flight, oldest message age (human-readable)"
    echo "  2. Per peeked message: full raw JSON payload + extracted identifiers"
    echo
    echo "Examples:"
    echo "  AWS_PROFILE=arco-prod aws-get-dlq-summary --queue-name 'my-service-dlq'"
    echo "  AWS_PROFILE=arco-prod aws-get-dlq-summary --queue-url 'https://sqs.us-east-1.amazonaws.com/123456789/my-dlq' --peek 5"
    echo
    echo "Note:"
    echo "  - Requires jq for JSON processing"
    echo "  - SNS-wrapped messages (Type: Notification) are automatically unwrapped"
    return 0
  fi

  # Check if AWS_PROFILE is set
  if [[ -z "$AWS_PROFILE" ]]; then
    echo "Error: AWS_PROFILE environment variable is not set" >&2
    echo "Usage: AWS_PROFILE=<profile> aws-get-dlq-summary --queue-url <url> | --queue-name <name> [--peek <N>]" >&2
    return 1
  fi

  # Check if jq is available
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed" >&2
    return 1
  fi

  # Parse named arguments
  local queue_url=""
  local queue_name=""
  local peek_count=1

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --queue-url)
        queue_url="$2"
        shift 2
        ;;
      --queue-name)
        queue_name="$2"
        shift 2
        ;;
      --peek)
        peek_count="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown parameter '$1'" >&2
        echo "Run 'aws-get-dlq-summary --help' for usage" >&2
        return 1
        ;;
    esac
  done

  # Validate: one of queue-url or queue-name required
  if [[ -z "$queue_url" && -z "$queue_name" ]]; then
    echo "Error: --queue-url or --queue-name is required" >&2
    return 1
  fi

  if [[ -n "$queue_url" && -n "$queue_name" ]]; then
    echo "Error: --queue-url and --queue-name are mutually exclusive" >&2
    return 1
  fi

  # Validate peek count
  if [[ "$peek_count" -lt 1 || "$peek_count" -gt 10 ]]; then
    echo "Error: --peek must be between 1 and 10" >&2
    return 1
  fi

  # Resolve queue name to URL if needed
  if [[ -n "$queue_name" ]]; then
    if ! queue_url=$(AWS_PROFILE=${AWS_PROFILE} aws sqs get-queue-url --queue-name "$queue_name" --output text --query QueueUrl 2> >(grep -v "CFPropertyList" >&2)) || [[ -z "$queue_url" ]]; then
      echo "Error: Could not resolve queue name '$queue_name' to URL" >&2
      return 1
    fi
  fi

  # Detect FIFO queue
  local is_fifo=false
  if [[ "$queue_url" == *.fifo ]]; then
    is_fifo=true
    if [[ "$peek_count" -gt 1 ]]; then
      echo "Note: FIFO queue detected -- limiting peek to 1 message (FIFO returns messages in order, one group at a time)." >&2
      peek_count=1
    fi
  fi

  # Helper: convert seconds to human-readable duration
  _format_duration() {
    local total_seconds="$1"
    local days=$((total_seconds / 86400))
    local hours=$(( (total_seconds % 86400) / 3600 ))
    local minutes=$(( (total_seconds % 3600) / 60 ))
    local result=""
    if [[ $days -gt 0 ]]; then result="${days}d "; fi
    if [[ $hours -gt 0 ]]; then result="${result}${hours}h "; fi
    if [[ $minutes -gt 0 || -z "$result" ]]; then result="${result}${minutes}m"; fi
    echo "${result% }"
  }

  echo "=== Queue Attributes ==="
  echo "Queue URL: $queue_url"
  if [[ "$is_fifo" == true ]]; then
    echo "Type:      FIFO"
  else
    echo "Type:      Standard"
  fi
  echo

  # Get queue attributes
  local attrs_response
  if ! attrs_response=$(AWS_PROFILE=${AWS_PROFILE} aws sqs get-queue-attributes \
    --queue-url "$queue_url" \
    --attribute-names ApproximateNumberOfMessages ApproximateNumberOfMessagesNotVisible ApproximateAgeOfOldestMessage \
    --output json 2> >(grep -v "CFPropertyList" >&2)); then
    echo "Error: Failed to get queue attributes" >&2
    return 1
  fi

  local msg_count
  msg_count=$(echo "$attrs_response" | jq -r '.Attributes.ApproximateNumberOfMessages // "0"')
  local in_flight
  in_flight=$(echo "$attrs_response" | jq -r '.Attributes.ApproximateNumberOfMessagesNotVisible // "0"')
  local oldest_age_seconds
  oldest_age_seconds=$(echo "$attrs_response" | jq -r '.Attributes.ApproximateAgeOfOldestMessage // "0"')
  local oldest_age_human
  oldest_age_human=$(_format_duration "$oldest_age_seconds")

  echo "Messages:   $msg_count"
  echo "In-flight:  $in_flight"
  echo "Oldest age: $oldest_age_human ($oldest_age_seconds seconds)"
  echo

  # Peek at messages
  if [[ "$msg_count" == "0" ]]; then
    echo "=== Messages ==="
    echo "Queue is empty, nothing to peek."
    return 0
  fi

  echo "=== Messages (peeking $peek_count) ==="
  echo

  local messages_response
  if ! messages_response=$(AWS_PROFILE=${AWS_PROFILE} aws sqs receive-message \
    --queue-url "$queue_url" \
    --max-number-of-messages "$peek_count" \
    --visibility-timeout 0 \
    --output json 2> >(grep -v "CFPropertyList" >&2)); then
    echo "Error: Failed to receive messages" >&2
    return 1
  fi

  local message_count
  message_count=$(echo "$messages_response" | jq '.Messages | length // 0')

  if [[ "$message_count" == "0" || "$message_count" == "null" ]]; then
    echo "No messages returned (they may be in-flight from another consumer)."
    return 0
  fi

  local i
  for ((i = 0; i < message_count; i++)); do
    echo "--- Message $((i + 1)) of $message_count ---"

    local raw_body
    raw_body=$(echo "$messages_response" | jq -r ".Messages[$i].Body")

    # Detect SNS-wrapped messages and unwrap
    local body
    local is_sns
    is_sns=$(echo "$raw_body" | jq -r 'if .Type == "Notification" then "yes" else "no" end' 2>/dev/null)

    if [[ "$is_sns" == "yes" ]]; then
      echo "[SNS-wrapped message, showing inner payload]"
      body=$(echo "$raw_body" | jq -r '.Message' 2>/dev/null)
      # Try to parse inner message as JSON for pretty output
      local parsed_body
      parsed_body=$(echo "$body" | jq '.' 2>/dev/null)
      if [[ $? -eq 0 && -n "$parsed_body" ]]; then
        body="$parsed_body"
      fi
    else
      # Try to pretty-print raw body as JSON
      local parsed_body
      parsed_body=$(echo "$raw_body" | jq '.' 2>/dev/null)
      if [[ $? -eq 0 && -n "$parsed_body" ]]; then
        body="$parsed_body"
      else
        body="$raw_body"
      fi
    fi

    echo
    echo "Payload:"
    echo "$body"
    echo

    # Extract known identifiers from the body
    echo "Extracted identifiers:"
    local id_value
    for field in transactionId externalId externalOrderId docNumber flow; do
      id_value=$(echo "$body" | jq -r ".. | .${field}? // empty" 2>/dev/null | head -1)
      if [[ -n "$id_value" ]]; then
        echo "  $field: $id_value"
      fi
    done
    echo
  done
}
