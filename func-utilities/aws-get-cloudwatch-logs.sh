#!/bin/bash

# TODO: Add an optional --output-file <file> to it, so it append there instead of doing so on a tmp file
function aws-get-cloudwatch-logs() {
  # Show help
  if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-v" || "$1" == "--version" ]]; then
    echo "aws-get-cloudwatch-logs - Fetch and paginate CloudWatch logs"
    echo
    echo "Usage:"
    echo "  AWS_PROFILE=<profile> aws-get-cloudwatch-logs --log-group <name> --start-date <utc-iso8601> [--end-date <utc-iso8601>] [--filter <pattern>]"
    echo "  aws-get-cloudwatch-logs -h | --help"
    echo
    echo "Parameters:"
    echo "  --log-group <name>        - CloudWatch log group name"
    echo "  --start-date <datetime>   - Start time in UTC ISO8601 format (e.g., 2025-01-15T10:30:00Z)"
    echo "  --end-date <datetime>     - (Optional) End time in UTC ISO8601 format (defaults to now)"
    echo "  --filter <pattern>        - (Optional) CloudWatch Logs filter pattern"
    echo "                              Example: \"{ \$.flow = 'nse-sales-agreements-cdc' && \$.level = 'error' }\""
    echo
    echo "Environment:"
    echo "  AWS_PROFILE              - AWS profile to use (required)"
    echo
    echo "Output:"
    echo "  All matching logs"
    echo
    echo "Examples:"
    echo "  AWS_PROFILE=arco-stage aws-get-cloudwatch-logs --log-group '/aws/ecs/integrator-core-service/core' --start-date '2025-01-15T10:00:00Z' | tee /tmp/cloudwatch-logs.log"
    echo "  AWS_PROFILE=arco-stage aws-get-cloudwatch-logs --log-group '/aws/ecs/integrator-core-service/core' --start-date '2025-01-15T10:00:00Z' --end-date '2025-01-15T12:00:00Z' --filter '{ \$.flow = \"nse-sales-agreements-cdc\" && \$.level = \"error\" }' | tee /tmp/cloudwatch-logs.log"
    echo
    echo "Note:"
    echo "  - Use single quotes for parameter values to avoid shell escaping issues"
    echo "  - macOS may show harmless CFPropertyList warnings during execution - you can ignored those"
    return 0
  fi

  # Check if AWS_PROFILE is set
  if [[ -z "$AWS_PROFILE" ]]; then
    echo "Error: AWS_PROFILE environment variable is not set"
    echo "Usage: AWS_PROFILE=<profile> aws-get-cloudwatch-logs --log-group <name> --start-date <utc-iso8601> [--end-date <utc-iso8601>] [--filter <pattern>]"
    return 1
  fi

  # Parse named arguments
  local log_group=""
  local start_date=""
  local end_date=""
  local filter_pattern=""

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
      --filter)
        filter_pattern="$2"
        shift 2
        ;;
      *)
        echo "Error: Unknown parameter '$1'" >&2
        echo "Run 'aws-get-cloudwatch-logs --help' for usage" >&2
        return 1
        ;;
    esac
  done

  # Validate required parameters
  if [[ -z "$log_group" ]]; then
    echo "Error: --log-group is required"
    return 1
  fi

  if [[ -z "$start_date" ]]; then
    echo "Error: --start-date is required"
    return 1
  fi

  # Convert ISO8601 to Unix timestamp in milliseconds
  local start_time
  if command -v gdate >/dev/null 2>&1; then
    # macOS with GNU date installed via homebrew
    start_time=$(gdate -d "$start_date" +%s 2>/dev/null)
  else
    # Linux or macOS built-in date
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

  # Generate output filename with timestamp
  local timestamp=$(date +%Y%m%d_%H%M%S)
  local logfile="/tmp/aws-cloudwatch-logs-${timestamp}.log"
  touch $logfile

  echo "Fetching logs from CloudWatch..."
  echo "Log Group: $log_group"
  echo "Start Date: $start_date"
  echo "End Date: ${end_date:-now}"
  echo "Filter: ${filter_pattern:-none}"
  echo "AWS Profile: $AWS_PROFILE"
  echo "Output File: $logfile"
  echo

  # Initialize variables for pagination
  local next_token=""
  local prev_token=""
  local page_count=0
  local total_events=0

  # Pagination loop
  while true; do
    ((page_count++))
    echo "Fetching page $page_count..."

    # Build AWS CLI command
    local aws_cmd_args=(
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
    local response
    response=$(AWS_PROFILE=${AWS_PROFILE} aws "${aws_cmd_args[@]}" 2> >(grep -v "CFPropertyList" >&2))
    local aws_exit_code=$?

    if [[ $aws_exit_code -ne 0 ]]; then
      echo "Error: AWS CLI command failed with exit code $aws_exit_code: ${response}"
      return 1
    fi

    # Extract event count
    local event_count=$(echo "$response" | grep eventId | wc -l)

    if [[ -z "$event_count" || "$event_count" == "null" ]]; then
      echo "Error: Invalid response from AWS CLI"
      echo "Response received:"
      echo "$response"
      return 1
    fi

    ((total_events += event_count))
    echo "  Found $event_count events in this page (total until now: $total_events)"

    # Output parsed message content (one JSON per line)
    if [[ "$event_count" -gt 0 ]]; then
      echo "$response" | egrep '"message": "{' | grep -o '{.*' | sed 's/\\"/"/g' | sed 's/\\//g' >> $logfile
    fi

    # Extract the new next token
    next_token=$(echo "$response" | grep nextToken | cut -d ':' -f 2 | tr -d '" \n')

    # Check if no more tokens or token unchanged
    if [[ -z "$next_token" ]]; then
      echo "No more pages. Pagination complete."
      break
    fi

    echo "  Next token found (${next_token}), continuing..."
  done

  echo
  echo "Complete!"
  echo "Total events fetched: $total_events"
  echo "Output File: $logfile"
}
