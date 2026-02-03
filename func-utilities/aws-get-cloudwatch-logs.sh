#!/bin/bash

function aws-get-cloudwatch-logs() {
  # Show help
  if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-v" || "$1" == "--version" ]]; then
    echo "aws-get-cloudwatch-logs - Fetch and paginate CloudWatch logs"
    echo
    echo "Usage:"
    echo "  AWS_PROFILE=<profile> aws-get-cloudwatch-logs --log-group <name> [--start-date <utc-iso8601>] [--end-date <utc-iso8601>] [--filter <pattern>]"
    echo "  aws-get-cloudwatch-logs -h | --help"
    echo
    echo "Parameters:"
    echo "  --log-group <name>        - CloudWatch log group name"
    echo "  --start-date <datetime>   - (Optional) Start time in UTC ISO8601 format (e.g., 2025-01-15T10:30:00Z)"
    echo "                              When omitted, uses progressive time windows (15m, 1h, 2h, ... 4w)"
    echo "                              anchored from --end-date (or now), stopping at first window with results."
    echo "  --end-date <datetime>     - (Optional) End time in UTC ISO8601 format (defaults to now)"
    echo "  --filter <pattern>        - (Optional) CloudWatch Logs filter pattern"
    echo "                              Example: \"{ \$.flow = 'nse-sales-agreements-cdc' && \$.level = 'error' }\""
    echo "  --output <file>           - (Optional) Output file path (appends results to this file)"
    echo "  --stdout                  - (Optional) Print results to stdout only (no file output, no debug info)"
    echo
    echo "Environment:"
    echo "  AWS_PROFILE              - AWS profile to use (required)"
    echo
    echo "Output:"
    echo "  All matching logs"
    echo
    echo "Examples:"
    echo "  # Explicit time range:"
    echo "  AWS_PROFILE=arco-prod aws-get-cloudwatch-logs --log-group '/aws/ecs/integrator-core-service/core' --start-date '2025-01-15T10:00:00Z' --end-date '2025-01-15T12:00:00Z' --filter '{ \$.level = \"error\" }' --stdout"
    echo
    echo "  # Progressive mode (auto-finds the right time window):"
    echo "  AWS_PROFILE=arco-prod aws-get-cloudwatch-logs --log-group '/aws/ecs/integrator-core-service/core' --filter '{ \$.level = \"error\" }' --stdout"
    echo
    echo "Note:"
    echo "  - Use single quotes for parameter values to avoid shell escaping issues"
    echo "  - macOS may show harmless CFPropertyList warnings during execution - you can ignored those"
    return 0
  fi

  # Check if AWS_PROFILE is set
  if [[ -z "$AWS_PROFILE" ]]; then
    echo "Error: AWS_PROFILE environment variable is not set" >&2
    echo "Usage: AWS_PROFILE=<profile> aws-get-cloudwatch-logs --log-group <name> [--start-date <utc-iso8601>] [--end-date <utc-iso8601>] [--filter <pattern>]" >&2
    return 1
  fi

  # Parse named arguments
  local log_group=""
  local start_date=""
  local end_date=""
  local filter_pattern=""
  local output_file=""
  local stdout_only=false

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
      --output)
        output_file="$2"
        shift 2
        ;;
      --stdout)
        stdout_only=true
        shift
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
    echo "Error: --log-group is required" >&2
    return 1
  fi

  # Helper: convert ISO8601 to Unix seconds
  _to_epoch_seconds() {
    local date_str="$1"
    if command -v gdate >/dev/null 2>&1; then
      gdate -d "$date_str" +%s 2>/dev/null
    else
      date -j -f "%Y-%m-%dT%H:%M:%SZ" "$date_str" +%s 2>/dev/null || date -d "$date_str" +%s 2>/dev/null
    fi
  }

  # Convert start_date if provided
  local start_time=""
  if [[ -n "$start_date" ]]; then
    start_time=$(_to_epoch_seconds "$start_date")
    if [[ -z "$start_time" ]]; then
      echo "Error: Invalid start-date format. Use UTC ISO8601 format (e.g., 2025-01-15T10:30:00Z)" >&2
      return 1
    fi
    start_time=$((start_time * 1000))
  fi

  # Convert end_date if provided, otherwise use current time
  local end_time
  if [[ -n "$end_date" ]]; then
    end_time=$(_to_epoch_seconds "$end_date")
    if [[ -z "$end_time" ]]; then
      echo "Error: Invalid end-date format. Use UTC ISO8601 format (e.g., 2025-01-15T10:30:00Z)" >&2
      return 1
    fi
    end_time=$((end_time * 1000))
  else
    end_time=$(($(date +%s) * 1000))
  fi

  # Determine output destination
  local logfile=""
  if [[ "$stdout_only" == true ]]; then
    logfile=""
  elif [[ -n "$output_file" ]]; then
    logfile="$output_file"
    touch "$logfile"
  else
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    logfile="/tmp/aws-cloudwatch-logs-${timestamp}.log"
    touch "$logfile"
  fi

  # --- Inner function: run paginated fetch for a given start_time/end_time ---
  # Sets outer variables: total_events (cumulative across pages)
  # Returns 0 on success, 1 on AWS error
  _run_paginated_fetch() {
    local fetch_start_time="$1"
    local fetch_end_time="$2"

    # NOTE: Variables used inside the loop must be declared here (not inside the loop)
    # to avoid zsh trace output issues when re-declaring local variables
    local next_token=""
    local page_count=0
    total_events=0
    local aws_cmd_args=()
    local response=""
    local aws_exit_code=0
    local event_count=0
    local parsed_output=""

    while true; do
      ((page_count++))
      if [[ "$stdout_only" != true ]]; then
        echo "Fetching page $page_count..."
      fi

      aws_cmd_args=(
        "logs" "filter-log-events"
        "--log-group-name" "$log_group"
        "--start-time" "$fetch_start_time"
        "--end-time" "$fetch_end_time"
        "--limit" 100
      )

      if [[ -n "$filter_pattern" ]]; then
        aws_cmd_args+=("--filter-pattern" "$filter_pattern")
      fi

      if [[ -n "$next_token" ]]; then
        aws_cmd_args+=("--next-token" "$next_token")
      fi

      response=$(AWS_PROFILE=${AWS_PROFILE} aws "${aws_cmd_args[@]}" 2> >(grep -v "CFPropertyList" >&2))
      aws_exit_code=$?

      if [[ $aws_exit_code -ne 0 ]]; then
        echo "Error: AWS CLI command failed with exit code $aws_exit_code: ${response}" >&2
        return 1
      fi

      event_count=$(echo "$response" | grep -c eventId) || true

      if [[ -z "$event_count" || "$event_count" == "null" ]]; then
        echo "Error: Invalid response from AWS CLI" >&2
        echo "Response received:" >&2
        echo "$response" >&2
        return 1
      fi

      ((total_events += event_count))
      if [[ "$stdout_only" != true ]]; then
        echo "  Found $event_count events in this page (total until now: $total_events)"
      fi

      if [[ "$event_count" -gt 0 ]]; then
        parsed_output=$(echo "$response" | grep -E '"message": "{' | grep -o '{.*' | sed 's/\\"/"/g' | sed 's/\\//g')
        if [[ "$stdout_only" == true ]]; then
          echo "$parsed_output"
        elif [[ -n "$logfile" ]]; then
          echo "$parsed_output" >> "$logfile"
        fi
      fi

      next_token=$(echo "$response" | grep nextToken | cut -d ':' -f 2 | tr -d '" \n')

      if [[ -z "$next_token" ]]; then
        if [[ "$stdout_only" != true ]]; then
          echo "No more pages. Pagination complete."
        fi
        break
      fi

      if [[ "$stdout_only" != true ]]; then
        echo "  Next token found (${next_token}), continuing..."
      fi
    done

    return 0
  }

  # --- Main execution ---
  local total_events=0

  if [[ -n "$start_time" ]]; then
    # Explicit start-date: single fetch (original behavior)
    if [[ "$stdout_only" != true ]]; then
      echo "Fetching logs from CloudWatch..."
      echo "Log Group: $log_group"
      echo "Start Date: $start_date"
      echo "End Date: ${end_date:-now}"
      echo "Filter: ${filter_pattern:-none}"
      echo "AWS Profile: $AWS_PROFILE"
      if [[ -n "$logfile" ]]; then
        echo "Output File: $logfile"
      fi
      echo
    fi

    _run_paginated_fetch "$start_time" "$end_time" || return 1
  else
    # Progressive mode: try increasingly wider windows
    local window_labels=("15m" "1h" "2h" "4h" "8h" "1d" "2d" "1w" "2w" "4w")
    local window_seconds=(900 3600 7200 14400 28800 86400 172800 604800 1209600 2419200)
    local anchor_epoch=$((end_time / 1000))

    if [[ "$stdout_only" != true ]]; then
      echo "Fetching logs from CloudWatch (progressive mode)..."
      echo "Log Group: $log_group"
      echo "Anchor: ${end_date:-now}"
      echo "Filter: ${filter_pattern:-none}"
      echo "AWS Profile: $AWS_PROFILE"
      if [[ -n "$logfile" ]]; then
        echo "Output File: $logfile"
      fi
      echo
    fi

    local found=false
    local i=0
    for i in "${!window_labels[@]}"; do
      local window_start=$(( (anchor_epoch - window_seconds[i]) * 1000 ))
      local label="${window_labels[$i]}"

      if [[ "$stdout_only" != true ]]; then
        echo "--- Trying window: last $label ---"
      else
        echo "--- Trying window: last $label ---" >&2
      fi

      _run_paginated_fetch "$window_start" "$end_time" || return 1

      if [[ "$total_events" -gt 0 ]]; then
        if [[ "$stdout_only" != true ]]; then
          echo
          echo "Found $total_events events in the last $label window."
        else
          echo "Found $total_events events in the last $label window." >&2
        fi
        found=true
        break
      fi

      if [[ "$stdout_only" != true ]]; then
        echo "  No results. Widening window..."
        echo
      fi
    done

    if [[ "$found" != true ]]; then
      if [[ "$stdout_only" != true ]]; then
        echo
        echo "No logs found in the last ~month for this filter."
      else
        echo "No logs found in the last ~month for this filter." >&2
      fi
    fi
  fi

  if [[ "$stdout_only" != true ]]; then
    echo
    echo "Complete!"
    echo "Total events fetched: $total_events"
    if [[ -n "$logfile" ]]; then
      echo "Output File: $logfile"
    fi
  fi
}
