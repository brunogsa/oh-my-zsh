#!/bin/bash

function aws-get-api-keys() {
  # Show help
  if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-v" || "$1" == "--version" ]]; then
    echo "aws-get-api-keys - List API Gateway API keys with their last 6 characters"
    echo
    echo "Usage:"
    echo "  AWS_PROFILE=<profile> aws-get-api-keys [--suffix <last-N-chars>]"
    echo "  aws-get-api-keys -h | --help"
    echo
    echo "Parameters:"
    echo "  --suffix <chars>  - (Optional) Filter keys by value suffix (e.g., last 6 chars from API GW logs)"
    echo "                      Without this flag, lists all API keys."
    echo
    echo "Environment:"
    echo "  AWS_PROFILE       - AWS profile to use (required)"
    echo
    echo "Output:"
    echo "  Table with columns: NAME | LAST_6_CHARS | DESCRIPTION"
    echo
    echo "Examples:"
    echo "  AWS_PROFILE=arco-prod aws-get-api-keys"
    echo "  AWS_PROFILE=arco-prod aws-get-api-keys --suffix 'xY3k9z'"
    echo
    echo "Note:"
    echo "  - Requires jq for JSON processing"
    return 0
  fi

  # Check if AWS_PROFILE is set
  if [[ -z "$AWS_PROFILE" ]]; then
    echo "Error: AWS_PROFILE environment variable is not set" >&2
    echo "Usage: AWS_PROFILE=<profile> aws-get-api-keys [--suffix <last-N-chars>]" >&2
    return 1
  fi

  # Check if jq is available
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed" >&2
    return 1
  fi

  # Parse named arguments
  local suffix=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --suffix)
        suffix="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown parameter '$1'" >&2
        echo "Run 'aws-get-api-keys --help' for usage" >&2
        return 1
        ;;
    esac
  done

  # Fetch all API keys with values
  local response
  response=$(AWS_PROFILE=${AWS_PROFILE} aws apigateway get-api-keys --include-values --output json 2> >(grep -v "CFPropertyList" >&2))
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "Error: AWS CLI command failed with exit code $exit_code" >&2
    return 1
  fi

  # Build jq filter
  local jq_filter
  if [[ -n "$suffix" ]]; then
    jq_filter=".items[] | select(.value | endswith(\"$suffix\")) | [.name, (.value | .[-6:]), (.description // \"-\")] | @tsv"
  else
    jq_filter='.items[] | [.name, (.value | .[-6:]), (.description // "-")] | @tsv'
  fi

  # Format as table
  local output
  output=$(echo "$response" | jq -r "$jq_filter")

  if [[ -z "$output" ]]; then
    if [[ -n "$suffix" ]]; then
      echo "No API keys found matching suffix '$suffix'" >&2
    else
      echo "No API keys found" >&2
    fi
    return 0
  fi

  (echo "NAME LAST_6_CHARS DESCRIPTION"; echo "$output" | tr '\t' ' ') | column -t
}
