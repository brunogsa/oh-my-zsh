#!/bin/bash

function aws-get-integrator-logs() {
  # Show help
  if [[ "$1" == "-h" || "$1" == "--help" || "$1" == "-v" || "$1" == "--version" ]]; then
    echo "aws-get-integrator-logs - Fetch logs from all Integrator log groups in parallel and merge by timestamp"
    echo
    echo "Usage:"
    echo "  AWS_PROFILE=<profile> aws-get-integrator-logs [--start-date <utc-iso8601>] [--end-date <utc-iso8601>] [--filter <pattern>] [--output <file>] [--stdout] [--exclude <label>...]"
    echo "  aws-get-integrator-logs -h | --help"
    echo
    echo "Parameters:"
    echo "  --start-date <datetime>   - (Optional) Start time in UTC ISO8601 format (e.g., 2025-01-15T10:30:00Z)"
    echo "                              When omitted, uses progressive time windows (same as aws-get-cloudwatch-logs)"
    echo "  --end-date <datetime>     - (Optional) End time in UTC ISO8601 format (defaults to now)"
    echo "  --filter <pattern>        - (Optional) CloudWatch Logs filter pattern"
    echo "  --output <file>           - (Optional) Output file path"
    echo "  --stdout                  - (Optional) Print merged JSONL to stdout"
    echo "  --exclude <label>...      - (Optional) Skip specific log groups by label"
    echo
    echo "Log group labels:"
    echo "  apigw          - API-Gateway-Execution-Logs_1ciiwix04k/prod"
    echo "  middleware      - /aws/ecs/integrator-middleware-service/middleware"
    echo "  core            - /aws/ecs/integrator-core-service/core"
    echo "  http-caller     - /aws/lambda/integrator-http-caller-prod"
    echo "  sf-http-caller  - /aws/lambda/integrator-sf-http-caller-prod"
    echo "  sf-notifier     - /aws/lambda/integrator-sf-notifier-prod"
    echo
    echo "Environment:"
    echo "  AWS_PROFILE              - AWS profile to use (required)"
    echo
    echo "Output:"
    echo "  Merged JSONL from all log groups, sorted by timestamp ascending."
    echo "  Each line has an injected '__source' field with the log group label."
    echo
    echo "Examples:"
    echo "  # Trace a transactionId across all layers:"
    echo "  AWS_PROFILE=arco-prod aws-get-integrator-logs \\"
    echo "    --filter '{ \$.transactionId = \"abc-123\" || \$.requestId = \"abc-123\" }' \\"
    echo "    --stdout"
    echo
    echo "  # Skip API GW and sf-notifier:"
    echo "  AWS_PROFILE=arco-prod aws-get-integrator-logs \\"
    echo "    --filter '{ \$.transactionId = \"abc-123\" }' \\"
    echo "    --exclude apigw sf-notifier \\"
    echo "    --stdout"
    echo
    echo "Note:"
    echo "  - Requires node.js for merging"
    echo "  - macOS may show harmless CFPropertyList warnings during execution"
    return 0
  fi

  # Check if AWS_PROFILE is set
  if [[ -z "$AWS_PROFILE" ]]; then
    echo "Error: AWS_PROFILE environment variable is not set" >&2
    echo "Usage: AWS_PROFILE=<profile> aws-get-integrator-logs [options]" >&2
    return 1
  fi

  # Log group registry: label -> log group name
  local -A log_groups
  log_groups[apigw]="API-Gateway-Execution-Logs_1ciiwix04k/prod"
  log_groups[middleware]="/aws/ecs/integrator-middleware-service/middleware"
  log_groups[core]="/aws/ecs/integrator-core-service/core"
  log_groups[http-caller]="/aws/lambda/integrator-http-caller-prod"
  log_groups[sf-http-caller]="/aws/lambda/integrator-sf-http-caller-prod"
  log_groups[sf-notifier]="/aws/lambda/integrator-sf-notifier-prod"

  # Parse arguments
  local start_date=""
  local end_date=""
  local filter_pattern=""
  local output_file=""
  local stdout_only=false
  local -a exclude_labels=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
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
      --exclude)
        shift
        while [[ $# -gt 0 && ! "$1" == --* ]]; do
          exclude_labels+=("$1")
          shift
        done
        ;;
      *)
        echo "Error: Unknown parameter '$1'" >&2
        echo "Run 'aws-get-integrator-logs --help' for usage" >&2
        return 1
        ;;
    esac
  done

  # Validate exclude labels
  for label in "${exclude_labels[@]}"; do
    if [[ -z "${log_groups[$label]+_}" ]]; then
      echo "Error: Unknown log group label '$label'" >&2
      echo "Valid labels: ${!log_groups[*]}" >&2
      return 1
    fi
  done

  # Build the list of active log groups
  local -a active_labels=()
  for label in "${!log_groups[@]}"; do
    local excluded=false
    for ex in "${exclude_labels[@]}"; do
      if [[ "$label" == "$ex" ]]; then
        excluded=true
        break
      fi
    done
    if [[ "$excluded" == false ]]; then
      active_labels+=("$label")
    fi
  done

  if [[ ${#active_labels[@]} -eq 0 ]]; then
    echo "Error: All log groups excluded, nothing to fetch" >&2
    return 1
  fi

  # Build common args for aws-get-cloudwatch-logs
  local -a common_args=("--stdout")
  if [[ -n "$start_date" ]]; then
    common_args+=("--start-date" "$start_date")
  fi
  if [[ -n "$end_date" ]]; then
    common_args+=("--end-date" "$end_date")
  fi
  if [[ -n "$filter_pattern" ]]; then
    common_args+=("--filter" "$filter_pattern")
  fi

  echo "Fetching logs from ${#active_labels[@]} log groups in parallel..." >&2
  echo "Active: ${active_labels[*]}" >&2
  if [[ ${#exclude_labels[@]} -gt 0 ]]; then
    echo "Excluded: ${exclude_labels[*]}" >&2
  fi
  echo >&2

  local -a tmp_files=()
  local -a pids=()
  trap 'rm -f "${tmp_files[@]}"' EXIT

  for label in "${active_labels[@]}"; do
    local tmp_file
    tmp_file=$(mktemp "/tmp/integrator-logs-${label}-XXXXXX.jsonl")
    tmp_files+=("$tmp_file")

    echo "  Starting fetch: $label -> $tmp_file" >&2

    (
      aws-get-cloudwatch-logs \
        --log-group "${log_groups[$label]}" \
        "${common_args[@]}" 2>/dev/null \
      | jq -c --arg src "$label" '. + {__source: $src}' \
        > "$tmp_file"
    ) &
    pids+=($!)
  done

  # Wait for all background jobs
  echo >&2
  echo "Waiting for all fetches to complete..." >&2
  for i in "${!pids[@]}"; do
    wait "${pids[$i]}"
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
      echo "  Warning: fetch for '${active_labels[$((i+1))]}' exited with code $exit_code" >&2
    fi
  done

  # Check if any temp file has content
  local has_results=false
  for f in "${tmp_files[@]}"; do
    if [[ -s "$f" ]]; then
      has_results=true
      break
    fi
  done

  if [[ "$has_results" == false ]]; then
    echo "No logs found across any log group." >&2
    return 0
  fi

  echo >&2
  echo "Merging results..." >&2

  local script_dir
  script_dir="$(cd "$(dirname "$0")" 2>/dev/null && pwd)"
  # Fallback: $0 may not resolve correctly when sourced
  if [[ ! -f "$script_dir/jsonl-merge-and-sort-by-field.js" ]]; then
    script_dir="$HOME/oh-my-zsh/func-utilities"
  fi

  local merged_output
  merged_output=$(node "$script_dir/jsonl-merge-and-sort-by-field.js" --sort-field timestamp "${tmp_files[@]}")

  # Output
  if [[ "$stdout_only" == true ]]; then
    echo "$merged_output"
  elif [[ -n "$output_file" ]]; then
    echo "$merged_output" > "$output_file"
    echo "Output written to: $output_file" >&2
  else
    local timestamp
    timestamp=$(date +%Y%m%d_%H%M%S)
    local default_file="/tmp/integrator-logs-merged-${timestamp}.jsonl"
    echo "$merged_output" > "$default_file"
    echo "Output written to: $default_file" >&2
  fi

  # Summary
  local line_count
  line_count=$(echo "$merged_output" | wc -l | tr -d ' ')
  echo "Total merged entries: $line_count" >&2
}
