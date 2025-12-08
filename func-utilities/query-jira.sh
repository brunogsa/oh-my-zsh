#!/bin/bash

# Query Jira using JQL and return JSON results
# Usage: query-jira "JQL query" [maxResults]
# Example: query-jira "assignee = currentUser() AND status = Done" 50
#
# Requirements:
#   export JIRA_URL='https://yourcompany.atlassian.net'
#   export JIRA_EMAIL='your.email@company.com'
#   export JIRA_API_TOKEN='your-api-token'
#   Get API token at: https://id.atlassian.com/manage-profile/security/api-tokens

function query-jira() {
  local jql="$1"
  local max_results="${2:-100}"
  local fields="${3:-key,summary,issuetype,project,resolutiondate,parent,status}"

  if [[ -z "$jql" ]]; then
    echo "Usage: query-jira \"JQL query\" [maxResults] [fields]" >&2
    echo "Example: query-jira \"assignee = currentUser() AND status = Done\" 50" >&2
    return 1
  fi

  if [[ -z "$JIRA_URL" ]]; then
    echo "Error: JIRA_URL environment variable is not set." >&2
    echo "Set with: export JIRA_URL='https://yourcompany.atlassian.net'" >&2
    return 1
  fi

  if [[ -z "$JIRA_EMAIL" ]]; then
    echo "Error: JIRA_EMAIL environment variable is not set." >&2
    echo "Set with: export JIRA_EMAIL='your.email@company.com'" >&2
    return 1
  fi

  if [[ -z "$JIRA_API_TOKEN" ]]; then
    echo "Error: JIRA_API_TOKEN environment variable is not set." >&2
    echo "Set with: export JIRA_API_TOKEN='your-api-token'" >&2
    echo "Get token at: https://id.atlassian.com/manage-profile/security/api-tokens" >&2
    return 1
  fi

  local response
  response=$(curl -s -X POST -u "${JIRA_EMAIL}:${JIRA_API_TOKEN}" \
    -H "Accept: application/json" \
    -H "Content-Type: application/json" \
    -d "{\"jql\": \"${jql}\", \"maxResults\": ${max_results}, \"fields\": [$(echo "$fields" | sed 's/\([^,]*\)/"\1"/g')]}" \
    "${JIRA_URL}/rest/api/3/search/jql" 2>&1)

  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to query Jira: $response" >&2
    return 1
  fi

  if echo "$response" | grep -q '"errorMessages"'; then
    echo "Error: Jira API returned an error:" >&2
    echo "$response" | jq -r '.errorMessages[]' >&2
    return 1
  fi

  echo "$response"
}
