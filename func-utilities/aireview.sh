#!/bin/bash

# TODO: Add Jira Description using apis
# TODO: Add PR Description using gh apis
# TODO: Apply prompt engineering practices to improve its quality
function aireview() {
  _aireview_help() {
    echo "aireview - Prepare code review context for AI analysis"
    echo
    echo "Usage:"
    echo "  aireview <from_ref_or_base_branch> <to_ref_or_feature_branch>"
    echo "  aireview -h | --help"
    echo
    echo "Examples:"
    echo "  aireview main feature/new-api"
    echo "  aireview develop bugfix/fix-npe"
    echo
    echo "Requirements:"
    echo "  - Run inside a git repository"
    echo "  - SSH access configured for the repo remote (extracted from .git/config)"
    echo "  - Aider optional (repo map); falls back gracefully"
  }

  _to_ssh() {
    local url="$1"
    case "$url" in
      git@*|ssh://*) echo "$url" ;;
      https://github.com/*)
        local path org repo
        path="${url#https://github.com/}"; path="${path%.git}"
        org="${path%%/*}"; repo="${path#*/}"
        echo "git@github.com:${org}/${repo}.git"
        ;;
      *) echo "$url" ;;  # leave as-is; we'll error later if not SSH
    esac
  }

  _repo_name_from_url() {
    # Extract repo name (final segment, sans .git) from ssh/scp/https/ssh:// URLs
    local s="$1"
    s="${s%.git}"
    if [[ "$s" == *:* && "$s" != http*://* && "$s" != ssh://* ]]; then
      # scp-like: git@host:org/repo
      s="${s#*:}"
    else
      # ssh:// or https:// -> drop scheme and host
      s="${s#*://}"       # drop scheme://
      s="${s#*/}"         # drop host part
    fi
    echo "${s##*/}"
  }

  # ----- robust ref resolver (local ref, origin/<ref>, tag) -----
  _list_available_refs() {
    local pattern="$1"
    echo "Available branches matching '$pattern':"
    git branch -r | grep -E "(origin/.*${pattern}|${pattern}.*)" | head -5 || true
    echo
    echo "Available tags matching '$pattern':"
    git tag | grep -E "${pattern}" | head -5 || true
    echo
  }

  _resolve_ref() {
    local ref="$1"

    # If already starts with origin/, use as-is
    if [[ "$ref" == origin/* ]]; then
      if git rev-parse --verify "${ref}^{commit}" >/dev/null 2>&1; then
        echo "$ref"; return 0
      fi
    else
      # Always try with origin/ prefix first
      if git rev-parse --verify "origin/${ref}^{commit}" >/dev/null 2>&1; then
        echo "origin/${ref}"; return 0
      fi
    fi

    # Try as a tag
    if git rev-parse --verify "refs/tags/${ref}^{commit}" >/dev/null 2>&1; then
      echo "refs/tags/${ref}"; return 0
    fi

    # Fetch and try again
    git fetch --all --tags --prune 2>/dev/null || true

    if [[ "$ref" == origin/* ]]; then
      if git rev-parse --verify "${ref}^{commit}" >/dev/null 2>&1; then
        echo "$ref"; return 0
      fi
    else
      if git rev-parse --verify "origin/${ref}^{commit}" >/dev/null 2>&1; then
        echo "origin/${ref}"; return 0
      fi
    fi

    if git rev-parse --verify "refs/tags/${ref}^{commit}" >/dev/null 2>&1; then
      echo "refs/tags/${ref}"; return 0
    fi

    return 1
  }

  _longest_common_dir() {
    awk -F/ '
    NR==1{ n=NF; for(i=1;i<=NF;i++) p[i]=$i; next }
    { for(i=1;i<=n;i++){ if($i!=p[i]){ n=i-1; break } } }
    END{
      if(n<=0) print ".";
    else { for(i=1;i<=n;i++){ printf "%s%s", p[i], (i<n?"/":"\n") } }
    }'
  }

  _try_aider_map() {
    if ! command -v aider >/dev/null 2>/dev/null; then
      echo "Error: aider command not found. Please install aider first." >&2
      return 1
    fi

    echo "Attempting to generate repo map with aider..."

    # Try aider with max-repo-map limit, display output to stdout, and capture to file
    # Flags for non-interactive mode:
    # --yes-always: auto-answer yes to all prompts (git init, aiderignore creation, etc.)
    # --no-auto-commits: don't auto-commit since we're just generating a map
    aider --subtree-only --map-token 8192 --show-repo-map --no-pretty --yes-always --no-auto-commits 2>&1 | tee "$REPO_MAP"

    # Check aider's exit status (first command in the pipe)
    if [[ ${PIPESTATUS[0]} -eq 0 ]]; then
      return 0
    else
      echo "Error: aider failed to generate repo map." >&2
      return 1
    fi
  }


  # ----- clipboard helpers (split copy & verify) -----
  local COPIED_WITH=""

  _copy_to_clipboard() {
    local file="$1"
    if command -v pbcopy >/dev/null 2>&1; then
      pbcopy < "$file" || return $?
      COPIED_WITH="pbcopy"; return 0
    elif command -v wl-copy >/dev/null 2>&1; then
      wl-copy < "$file" || return $?
      COPIED_WITH="wl-copy"; return 0
    elif command -v xclip >/dev/null 2>&1; then
      xclip -selection clipboard < "$file" || return $?
      COPIED_WITH="xclip"; return 0
    elif command -v copyq >/dev/null 2>&1; then
      copyq copy < "$file" || return $?
      COPIED_WITH="copyq"; return 0
    else
      echo "Error: No clipboard tool found (pbcopy, wl-copy, xclip, copyq)." >&2
      return 1
    fi
  }

  _verify_copy_truncation() {
    local file="$1" expected pasted=""
    expected="$(wc -c < "$file" | tr -d ' ')"
    if command -v pbpaste >/dev/null 2>&1; then
      pasted="$(pbpaste | wc -c | tr -d ' ')"
    elif command -v wl-paste >/dev/null 2>&1; then
      pasted="$(wl-paste | wc -c | tr -d ' ')"
    elif command -v xclip >/dev/null 2>&1; then
      pasted="$(xclip -selection clipboard -o 2>/dev/null | wc -c | tr -d ' ')"
    elif command -v copyq >/dev/null 2>&1; then
      pasted="$(copyq read 2>/dev/null | wc -c | tr -d ' ')"
    else
      echo "Warning: could not verify clipboard (no paste tool found)." >&2
      return 0
    fi
    if [[ -n "$pasted" ]] && (( pasted < expected )); then
      echo "Error: clipboard appears truncated (${pasted}/${expected} bytes)." >&2
      return 1
    fi
    return 0
  }

  # ----- section builders for review file -----
  _add_header() {
    echo "# Code Review Request" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
    echo "**Branch/Ref:** ${FROM_REF} → ${TO_REF}" >> "$REVIEW_FILE"
    echo "**Repository:** ${SSH_URL}" >> "$REVIEW_FILE"
    echo "**Review Context (working dir):** ${WORK_DIR}" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
    echo "---" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
  }

  _add_repo_structure() {
    echo "## Repository Structure (Subtree Map)" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
    echo "This is the structure of the repository subtree where changes were made." >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
    echo '```' >> "$REVIEW_FILE"
    cat "$REPO_MAP" >> "$REVIEW_FILE"
    echo '```' >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
    echo "---" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
  }

  _add_full_file_contents() {
    echo "## Full content of files that were modified, with their lines (at ${TO_REF})" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"

    while IFS= read -r file; do
      [[ -z "$file" ]] && continue
      echo "### \`$file\`" >> "$REVIEW_FILE"
      if [[ "$file" =~ $LOCKFILE_REGEX ]]; then
        # Do not dump entire lockfile contents (too large/noisy)
        echo "_[lockfile content omitted in this section; see truncated diff below]_" >> "$REVIEW_FILE"
        echo >> "$REVIEW_FILE"
        continue
      fi
      if git cat-file -e "${TO_REF}:${file}" 2>/dev/null; then
        echo '```' >> "$REVIEW_FILE"
        git show "${TO_REF}:${file}" 2>/dev/null | cat -n >> "$REVIEW_FILE" \
          || echo "[Unable to show file content]" >> "$REVIEW_FILE"
        echo '```' >> "$REVIEW_FILE"
      else
        echo "_[deleted or not present in ${TO_REF}]_" >> "$REVIEW_FILE"
      fi
      echo >> "$REVIEW_FILE"
    done <<< "$CHANGED_LIST"

    echo "---" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
  }

  _add_git_diff() {
    echo "## Git Diff Output (range: ${MERGE_BASE}..${TO_REF})" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
    echo '```diff' >> "$REVIEW_FILE"
    # Exclude all lock files from the diff using the central list
    local GIT_DIFF_EXCLUDES=()
    for f in "${LOCKFILES[@]}"; do
      GIT_DIFF_EXCLUDES+=(":(exclude)$f")
      GIT_DIFF_EXCLUDES+=(":(exclude)**/$f")
    done
    git diff "$MERGE_BASE" "$TO_REF" -- . "${GIT_DIFF_EXCLUDES[@]}" >> "$REVIEW_FILE" || true
    echo >> "$REVIEW_FILE"
    echo "---" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
  }

  _add_git_context() {
    echo "## Git Context" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
    cat "$GIT_CTX" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
    echo "---" >> "$REVIEW_FILE"
    echo >> "$REVIEW_FILE"
  }

  _add_review_guidelines() {
    # ----- extract review guidelines and code conventions from CLAUDE.md -----
    local CLAUDE_MD="$HOME/.claude/CLAUDE.md"
    if [[ ! -f "$CLAUDE_MD" ]]; then
      echo "Warning: $CLAUDE_MD not found, using fallback review instructions" >&2
      echo "## Code Review Instructions" >> "$REVIEW_FILE"
      echo >> "$REVIEW_FILE"
      echo "Please perform a comprehensive code review following best practices." >> "$REVIEW_FILE"
    else
      # Extract CODE section (up to but not including TESTS section)
      echo "## Code Conventions (Reference)" >> "$REVIEW_FILE"
      echo >> "$REVIEW_FILE"
      sed -n '/^## CODE$/,/^## TESTS$/p' "$CLAUDE_MD" | sed '$d' >> "$REVIEW_FILE"
      echo >> "$REVIEW_FILE"
      echo "---" >> "$REVIEW_FILE"
      echo >> "$REVIEW_FILE"

      # Extract REVIEW section (up to but not including RECAP or next ## section)
      echo "## Code Review Instructions" >> "$REVIEW_FILE"
      echo >> "$REVIEW_FILE"
      sed -n '/^## REVIEW$/,/^## RECAP$/p' "$CLAUDE_MD" | sed '$d' >> "$REVIEW_FILE"
    fi
  }

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    _aireview_help
    return 0
  fi
  if [[ $# -ne 2 ]]; then
    echo "Error: Incorrect number of arguments" >&2
    echo
    _aireview_help
    return 1
  fi

  local FROM_REF_IN="$1"   # matches `git diff` order: from/base
  local TO_REF_IN="$2"     # to/feature

  # Save original directory for cleanup
  local ORIGINAL_DIR="$(pwd)"

  # Ensure we always return to original directory on exit
  trap 'cd "$ORIGINAL_DIR" 2>/dev/null || true' EXIT INT TERM

  # ----- must be in a git repo -----
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not inside a git repository." >&2
    return 1
  fi

  # ----- extract remote from .git/config and normalize to SSH (GitHub https -> SSH) -----
  local ORIGIN_URL
  ORIGIN_URL="$(git config --get remote.origin.url)"
  if [[ -z "$ORIGIN_URL" ]]; then
    echo "Error: No remote.origin.url found in .git/config." >&2
    return 1
  fi

  echo "Extracted origin: $ORIGIN_URL"

  local SSH_URL="$(_to_ssh "$ORIGIN_URL")"
  if [[ "$SSH_URL" != git@* && "$SSH_URL" != ssh://* ]]; then
    echo "Error: Remote is not SSH (from .git/config): $ORIGIN_URL" >&2
    echo "Hint: set remote.origin.url to an SSH URL (e.g., git@github.com:org/repo.git)" >&2
    return 1
  fi

  echo "Origin in SSH format: $SSH_URL"

  local REPO_NAME="$(_repo_name_from_url "$SSH_URL")"
  [[ -z "$REPO_NAME" ]] && REPO_NAME="repo"

  echo "Repo Name: $REPO_NAME"

  # ----- temp clone of the same repo (via SSH) -----
  local TMPROOT
  TMPROOT="$(mktemp -d "/tmp/aireview.${REPO_NAME}.XXXXXX")" || { echo "mktemp failed"; return 1; }
  local CLONED="${TMPROOT}/${REPO_NAME}"

  if ! git clone --quiet "$SSH_URL" "$CLONED"; then
    echo "Error: git clone via SSH failed: $SSH_URL" >&2
    return 1
  fi
  cd "$CLONED" || { echo "Failed to cd to cloned repo"; cd "$ORIGINAL_DIR"; return 1; }

  echo "Cloned at: $CLONED"

  git fetch --all --tags --prune

  echo "Fetched all remote branches"

  # ----- resolve refs (supports local, origin/<ref>, tags) -----
  local FROM_REF TO_REF
  if ! FROM_REF="$(_resolve_ref "$FROM_REF_IN")"; then
    echo "Error: could not resolve FROM ref: '$FROM_REF_IN'" >&2
    echo >&2
    _list_available_refs "$FROM_REF_IN"
    cd "$ORIGINAL_DIR"; return 1
  fi
  if ! TO_REF="$(_resolve_ref "$TO_REF_IN")"; then
    echo "Error: could not resolve TO ref: '$TO_REF_IN'" >&2
    echo >&2
    _list_available_refs "$TO_REF_IN"
    cd "$ORIGINAL_DIR"; return 1
  fi

  # ----- merge-base and changed files for range MERGE_BASE..TO_REF -----
  local MERGE_BASE
  MERGE_BASE="$(git merge-base "$FROM_REF" "$TO_REF")"
  if [[ -z "$MERGE_BASE" ]]; then
    echo "Error: could not compute merge-base between $FROM_REF and $TO_REF" >&2
    cd "$ORIGINAL_DIR"; return 1
  fi

  echo "Got the merge base"

  # Central list of common dependency lockfiles
  local LOCKFILES=(
    "yarn.lock"
    "package-lock.json"
    "npm-shrinkwrap.json"
    "pnpm-lock.yaml"
    "bun.lockb"
    "Gemfile.lock"
    "Cargo.lock"
    "Pipfile.lock"
    "poetry.lock"
    "composer.lock"
    "Podfile.lock"
    "pubspec.lock"
    "gradle.lockfile"
    "gradle/dependency-locks/.*"
    "go.sum"
    "mix.lock"
    "packages.lock.json"
    "Paket.lock"
    "conda-lock.yml"
    "shrinkwrap.yaml"
  )

  # Regex to match lockfiles in paths
  local LOCKFILE_REGEX="(^|/)($(IFS='|'; echo "${LOCKFILES[*]}"))$"

  local CHANGED_LIST
  CHANGED_LIST="$(git diff --name-only "$MERGE_BASE" "$TO_REF" | grep -vE '^\s*$' || true)"
  if [[ -z "$CHANGED_LIST" ]]; then
    echo "No changes found between $FROM_REF and $TO_REF." >&2
    cd "$ORIGINAL_DIR"; return 1
  fi

  echo "Got the change list"

  # ----- choose working directory: LONGEST COMMON DIR ONLY (fallback to repo root) -----

  local WORK_DIR
  WORK_DIR="$(printf '%s\n' "$CHANGED_LIST" | _longest_common_dir)"

  # Checkout TO_REF to ensure the working directory exists
  git checkout "$TO_REF" >/dev/null 2>&1 || {
    echo "Failed to checkout $TO_REF" >&2
    cd "$ORIGINAL_DIR"
    return 1
  }

  cd "$WORK_DIR" || { echo "Failed to cd to $WORK_DIR"; cd "$ORIGINAL_DIR"; return 1; }

  echo "Longest common directory found: $WORK_DIR"

  # ----- git context (for TO head) -----
  local GIT_CTX="${TMPROOT}/git-context.txt"
  : > "$GIT_CTX"
  echo "### git log (range: $MERGE_BASE..$TO_REF)" >> "$GIT_CTX"
  (git log --no-color --oneline --decorate --graph "$MERGE_BASE..$TO_REF" || true) >> "$GIT_CTX"
  echo >> "$GIT_CTX"
  echo "### git diff --stat (range: $MERGE_BASE..$TO_REF)" >> "$GIT_CTX"
  (git diff --no-color --stat "$MERGE_BASE" "$TO_REF" || true) >> "$GIT_CTX"

  echo "Built all git context"

  # ----- repo map via Aider (mandatory) -----
  local REPO_MAP="${TMPROOT}/repo-map.txt"
  : > "$REPO_MAP"

  if ! _try_aider_map; then
    echo "Failed to generate repo map with aider. This is required for aireview." >&2
    cd "$ORIGINAL_DIR"
    return 1
  fi

  echo "Successfully generated repo map with aider"

  # ----- build review bundle with appending echoes -----
  local REVIEW_FILE="/tmp/aireview-output-$(date +%s).md"
  : > "$REVIEW_FILE"

  # Build review file in sections (order optimized for LLM prompt engineering)
  # 1. Header with metadata
  _add_header
  # 2. Review instructions first - primes the AI with evaluation criteria
  _add_review_guidelines
  # 3. Git context early - provides WHAT changed and WHY (commit messages, stats)
  _add_git_context
  # 4. Git diff - shows HOW things changed (focused, relevant changes)
  _add_git_diff
  # 5. Repository structure - WHERE changes fit in the codebase
  _add_repo_structure
  # 6. Full file contents last - deep context (most token-expensive, comes last)
  _add_full_file_contents

  # ----- estimate and log tokens -----
  local estimated_tokens
  estimated_tokens=$(estimate_tokens "$REVIEW_FILE")
  echo "Estimated tokens: ~${estimated_tokens} (${estimated_tokens}k tokens = $((estimated_tokens / 1000))k)"

  # ----- copy & verify -----
  if ! _copy_to_clipboard "$REVIEW_FILE"; then
    echo "Warning: Copy to clipboard failed."
    echo "Bundle file: $REVIEW_FILE"
    echo "Temp clone:  $CLONED"
    cd "$ORIGINAL_DIR"
    return 1
  fi

  if ! _verify_copy_truncation "$REVIEW_FILE"; then
    echo "Warning: Clipboard may be truncated."
    echo "Bundle file: $REVIEW_FILE"
    echo "Temp clone:  $CLONED"
    cd "$ORIGINAL_DIR"
    return 1
  fi

  echo "OK. Review bundle copied to clipboard (via ${COPIED_WITH})."
  echo "Bundle file: $REVIEW_FILE"
  echo "Temp clone:  $CLONED"
  cd "$ORIGINAL_DIR"
}
