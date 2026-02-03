#!/bin/bash

function aws-get-status-distribution-api-gw() {
  # Show help
  if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-v" || "$1" == "--version" ]]; then
    echo "aws-get-status-distribution-api-gw - Fetch API Gateway logs and show status distribution by endpoint + caller"
    echo
    echo "Usage:"
    echo "  AWS_PROFILE=<profile> aws-get-status-distribution-api-gw --log-group <name> [--start-date <utc-iso8601>] [--end-date <utc-iso8601>] [--status <code>] [--path <resource-path>]"
    echo "  aws-get-status-distribution-api-gw -h | --help"
    echo
    echo "Parameters:"
    echo "  --log-group <name>        - API Gateway log group name (required)"
    echo "  --start-date <datetime>   - Start time in UTC ISO8601 format (defaults to start of today UTC)"
    echo "  --end-date <datetime>     - End time in UTC ISO8601 format (defaults to now)"
    echo "  --status <code>           - Filter by HTTP status code (e.g., 401)"
    echo "  --path <resource-path>    - Filter by resourcePath (exact match, e.g., /v1/facades/sae/protheus/kits)"
    echo
    echo "Environment:"
    echo "  AWS_PROFILE              - AWS profile to use (required)"
    echo
    echo "Output:"
    echo "  Distribution table of requests grouped by method, path, status, and API key (last 6 chars)"
    echo
    echo "Examples:"
    echo "  AWS_PROFILE=arco-prod aws-get-status-distribution-api-gw --log-group 'API-Gateway-Execution-Logs_1ciiwix04k/prod' --status 401"
    echo "  AWS_PROFILE=arco-prod aws-get-status-distribution-api-gw --log-group 'API-Gateway-Execution-Logs_1ciiwix04k/prod' --start-date '2025-01-15T00:00:00Z' --end-date '2025-01-15T12:00:00Z'"
    echo "  AWS_PROFILE=arco-prod aws-get-status-distribution-api-gw --log-group 'API-Gateway-Execution-Logs_1ciiwix04k/prod' --status 401 --path '/v1/facades/sae/protheus/kits'"
    echo
    echo "Note:"
    echo "  - Requires node.js for the distribution table"
    echo "  - macOS may show harmless CFPropertyList warnings during execution - you can ignore those"
    return 0
  fi

  # Check if AWS_PROFILE is set
  if [[ -z "$AWS_PROFILE" ]]; then
    echo "Error: AWS_PROFILE environment variable is not set" >&2
    echo "Usage: AWS_PROFILE=<profile> aws-get-status-distribution-api-gw --log-group <name> [options]" >&2
    return 1
  fi

  # Parse named arguments
  local log_group=""
  local start_date=""
  local end_date=""
  local status_filter=""
  local path_filter=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --log-group)
        log_group="$2"
        shift 2
        ;;
      --start-date)
        start_date="$2"
        shift 2
        ;;
      --end-date)
        end_date="$2"
        shift 2
        ;;
      --status)
        status_filter="$2"
        shift 2
        ;;
      --path)
        path_filter="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown parameter '$1'" >&2
        echo "Run 'aws-get-status-distribution-api-gw --help' for usage" >&2
        return 1
        ;;
    esac
  done

  # Validate required parameters
  if [[ -z "$log_group" ]]; then
    echo "Error: --log-group is required" >&2
    return 1
  fi

  # Default start_date to start of today (UTC)
  if [[ -z "$start_date" ]]; then
    if command -v gdate >/dev/null 2>&1; then
      start_date=$(gdate -u +%Y-%m-%dT00:00:00Z)
    else
      start_date=$(date -u +%Y-%m-%dT00:00:00Z)
    fi
  fi

  # Convert ISO8601 to Unix timestamp in milliseconds
  local start_time
  if command -v gdate >/dev/null 2>&1; then
    start_time=$(gdate -d "$start_date" +%s 2>/dev/null)
  else
    start_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$start_date" +%s 2>/dev/null || date -d "$start_date" +%s 2>/dev/null)
  fi

  if [[ -z "$start_time" ]]; then
    echo "Error: Invalid start-date format. Use UTC ISO8601 format (e.g., 2025-01-15T10:30:00Z)" >&2
    return 1
  fi
  start_time=$((start_time * 1000))

  # Convert end_date if provided, otherwise use current time
  local end_time
  if [[ -n "$end_date" ]]; then
    if command -v gdate >/dev/null 2>&1; then
      end_time=$(gdate -d "$end_date" +%s 2>/dev/null)
    else
      end_time=$(date -j -f "%Y-%m-%dT%H:%M:%SZ" "$end_date" +%s 2>/dev/null || date -d "$end_date" +%s 2>/dev/null)
    fi

    if [[ -z "$end_time" ]]; then
      echo "Error: Invalid end-date format. Use UTC ISO8601 format (e.g., 2025-01-15T10:30:00Z)" >&2
      return 1
    fi
    end_time=$((end_time * 1000))
  else
    end_time=$(($(date +%s) * 1000))
  fi

  # Build filter pattern from --status and --path
  local filter_pattern=""
  if [[ -n "$status_filter" && -n "$path_filter" ]]; then
    filter_pattern="{ \$.status = $status_filter && \$.resourcePath = \"$path_filter\" }"
  elif [[ -n "$status_filter" ]]; then
    filter_pattern="{ \$.status = $status_filter }"
  elif [[ -n "$path_filter" ]]; then
    filter_pattern="{ \$.resourcePath = \"$path_filter\" }"
  fi

  # Print debug info to stderr
  echo "Fetching API Gateway logs..." >&2
  echo "Log Group: $log_group" >&2
  echo "Start Date: $start_date" >&2
  echo "End Date: ${end_date:-now}" >&2
  echo "Status Filter: ${status_filter:-any}" >&2
  echo "Path Filter: ${path_filter:-any}" >&2
  echo "Filter Pattern: ${filter_pattern:-none}" >&2
  echo "AWS Profile: $AWS_PROFILE" >&2
  echo >&2

  # Temp file to collect all events
  local tmp_file
  tmp_file=$(mktemp /tmp/apigw-distribution-XXXXXX.jsonl)

  # Initialize variables for pagination
  local next_token=""
  local page_count=0
  local total_events=0
  local aws_cmd_args=()
  local response=""
  local aws_exit_code=0
  local event_count=0

  # Pagination loop
  while true; do
    ((page_count++))
    echo "Fetching page $page_count..." >&2

    # Build AWS CLI command
    aws_cmd_args=(
      "logs" "filter-log-events"
      "--log-group-name" "$log_group"
      "--start-time" "$start_time"
      "--end-time" "$end_time"
      "--limit" 100
    )

    # Add filter pattern if provided
    if [[ -n "$filter_pattern" ]]; then
      aws_cmd_args+=("--filter-pattern" "$filter_pattern")
    fi

    # Add next token if we have one
    if [[ -n "$next_token" ]]; then
      aws_cmd_args+=("--next-token" "$next_token")
    fi

    # Execute command and capture response (filter out CFPropertyList warnings)
    response=$(AWS_PROFILE=${AWS_PROFILE} aws "${aws_cmd_args[@]}" 2> >(grep -v "CFPropertyList" >&2))
    aws_exit_code=$?

    if [[ $aws_exit_code -ne 0 ]]; then
      echo "Error: AWS CLI command failed with exit code $aws_exit_code: ${response}" >&2
      rm -f "$tmp_file"
      return 1
    fi

    # Extract event count
    event_count=$(echo "$response" | grep -c eventId) || true

    if [[ -z "$event_count" || "$event_count" == "null" ]]; then
      echo "Error: Invalid response from AWS CLI" >&2
      rm -f "$tmp_file"
      return 1
    fi

    ((total_events += event_count))
    echo "  Found $event_count events in this page (total: $total_events)" >&2

    # Append raw message content to temp file (one JSON per line)
    if [[ "$event_count" -gt 0 ]]; then
      echo "$response" | jq -r '.events[].message' >> "$tmp_file"
    fi

    # Extract the new next token
    next_token=$(echo "$response" | grep nextToken | cut -d ':' -f 2 | tr -d '" \n')

    # Check if no more tokens
    if [[ -z "$next_token" ]]; then
      echo "No more pages. Pagination complete." >&2
      break
    fi

    echo "  Next token found, continuing..." >&2
  done

  echo >&2
  echo "Total events fetched: $total_events" >&2

  if [[ "$total_events" -eq 0 ]]; then
    echo "No events found matching the criteria." >&2
    rm -f "$tmp_file"
    return 0
  fi

  echo "Generating distribution table..." >&2
  echo >&2

  # Resolve the path to the Node.js helper (same directory as this script)
  local script_dir="${0:a:h}"
  # Fallback: if sourced, $0 may not resolve correctly
  if [[ ! -f "$script_dir/apigw-distribution-table.js" ]]; then
    script_dir="$HOME/oh-my-zsh/func-utilities"
  fi

  node "$script_dir/apigw-distribution-table.js" "$tmp_file"

  rm -f "$tmp_file"
}
