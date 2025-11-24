# Enable the line below for profilling
# zmodload zsh/zprof

# Paste the line below
# PS4='+[%D{%T.%.}] %N:%i> ' zsh -x

# Useful for profilling startup times
# zsh_profile_startup() {
#   shell=${1-$SHELL}
#   for i in $(seq 1 10); do /usr/bin/time $shell -i -c exit; done
# }

# git() {
#   local PS4='[%D{%T.%.}] %N:%i:'
#   print -u2 -f '-> %s (%s)\n' ${funcstack:^funcfiletrace}
#   set -o localoptions -o xtrace
#   command git "$@"
# }

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load. Optionally, if you set this to "random"
# it'll load a random theme each time that oh-my-zsh is loaded.
# See https://github.com/robbyrussell/oh-my-zsh/wiki/Themes
ZSH_THEME="punctual"
PUNCTUAL_TIMESTAMP_FORMAT="%a, %d %b %Y - %H:%M:%S";
PUNCTUAL_SHOW_HOSTNAME="false";
PUNCTUAL_TIMESTAMP_COLOUR="yellow";
PUNCTUAL_SHOW_GIT="true";

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion. Case
# sensitive completion must be off. _ and - will be interchangeable.
HYPHEN_INSENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(colored-man-pages npm yarn zsh-better-npm-completion fzf-zsh)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/rsa_id"

function compile-mermaid () {
  if [ -z "$1" ]; then
    echo "Usage: compile-mermaid <mermaid_file>"
    return 1
  fi

  mermaidFile="$1"
  fileName=$(echo "$mermaidFile" | cut -d '.' -f 1)

  mmdc -i "$mermaidFile" -o "${fileName}.png" --scale 4
  # convert -trim "$fileName.png" "$fileName.png"
}

function compile-gantt-mermaid () {
  if [ -z "$1" ]; then
    echo "Usage: compile-gantt-mermaid <mermaid_file> [width]"
    return 1
  fi

  mermaidFile="$1"
  width="${2:-2048}"

  fileName=$(echo "$mermaidFile" | cut -d '.' -f 1)

  mmdc -i "$mermaidFile" -o "${fileName}.svg" --scale 4 --width "$width"
}

function gen-schema-from-json () {
  if [[ -z $1 ]]; then
    echo "Usage: gen-schema-from-json <input_json_file>"
    return 1
  fi

  local inputJson=$1
  local fileName=${inputJson%.json}

  # 1. JSON  ➜  JSON-Schema
  npx quicktype \
    --src "$inputJson" \
    --src-lang json \
    --lang schema \
    --out "${fileName}.schema.json"
}

function diff-sorted-txt () {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: diff-sorted-txt <fileA> <fileB>"
    return 1
  fi

  local fileA="$1"
  local fileB="$2"

  local sortedFileA="/tmp/sorted-$(basename "$fileA")"
  local sortedFileB="/tmp/sorted-$(basename "$fileB")"

  sort "$fileA" > "$sortedFileA"
  sort "$fileB" > "$sortedFileB"

  meld "$sortedFileA" "$sortedFileB"
}

function diff-sorted-jsons () {
  if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: diff-sorted-json <fileA> <fileB> [field1,field2,...]"
    return 1
  fi

  local fileA="$1"
  local fileB="$2"
  local fields="$3"

  local sortedFileA="/tmp/sorted-$(basename "$fileA")"
  local sortedFileB="/tmp/sorted-$(basename "$fileB")"

  ~/oh-my-zsh/json-deep-sort.js "$fileA" "$fields" > "$sortedFileA"
  ~/oh-my-zsh/json-deep-sort.js "$fileB" "$fields" > "$sortedFileB"

  meld "$sortedFileA" "$sortedFileB"
}

function search-replace-vim() {
  local pattern="$1"
  local replace="$2"

  if [ -z "$pattern" ] || [ -z "$replace" ]; then
    echo "Usage: search-replace-vim <search_pattern> <replace_pattern>"
    return 1
  fi

  # Use the 'rg' alias (assumes it already filters out large folders)
  local files
  files=$(rg --files-with-matches "$pattern" | sort -u)

  if [ -z "$files" ]; then
    echo "No matches found for '$pattern'"
    return 1
  fi

  echo "Found files:"
  echo "$files"
  echo

  # Use /dev/tty for prompts to avoid stdin conflicts
  while IFS= read -r file; do
    local bold_file="\033[1m$file\033[0m"
    echo -ne "Open $bold_file in Neovim for search & replace? (y/n/q): " > /dev/tty
    read -r choice < /dev/tty
    choice=${choice:-y}  # default to 'y'

    if [[ "$choice" == "q" ]]; then
      echo "Quit!"
      return 0
    elif [[ "$choice" == "n" ]]; then
      echo "Skipping $file."
    else
      nvim +"%s/$pattern/$replace/gc" -- "$file"
    fi
  done <<< "$files"
}

function node-debug-reminder() {
  echo "Node Debugger Quick Steps"
  echo
  echo "1) Add 'debugger;' statements in your test file"
  echo "2) In one terminal, run:"
  echo "node --inspect-brk ./node_modules/.bin/jest [tests/myFeature.test.js]"
  echo
  echo "3) In another terminal, attach the debugger with:"
  echo "node inspect localhost:9229"
  echo
  echo "4) Builtin Debugger Commands:"
  echo "c                – continue"
  echo "n                – step over"
  echo "s                – step into"
  echo "o                – step out"
  echo "repl             – enter full REPL mode (like a mini Node console)"
  echo "restart          – restart the debug session"
  echo "watch('someVar') – watch a variable"
  echo
  echo "Enjoy your debugging session!"
}

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

function ai-changelog() {
  if [[ -t 0 ]] || [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  ai-changelog [-h | --help]"
    echo "  git show HEAD~1 | ai-changelog"
    echo "  git diff HEAD~1 | ai-changelog"
    echo ""
    echo "Description:"
    echo "  Generates a changelog summary in bullet points from a git show/diff using AI"
    return
  fi

  local diff
  diff=$(cat)

  local prompt="Generate a changelog with the best practices, summarizing the following git show/info into concise bullet points:

  $diff"

  ai-request "$prompt" "gpt-4.1"
}

function aigitcommit() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  aigitcommit [--no-verify]"
    echo ""
    echo "Description:"
    echo "  Generates a commit message from staged changes,"
    echo "  then opens your editor with the message pre-filled before committing."
    return
  fi

  local no_verify=""
  if [[ "$1" == "--no-verify" ]]; then
    no_verify="--no-verify"
  fi

  local diff
  diff=$(git diff --cached)

  if [[ -z "$diff" ]]; then
    echo "No staged changes found. Use 'git add' first."
    return 1
  fi

  local prompt="Write a clear and concise Git commit message (max 72 characters in the subject line), based on the following staged diff. Use imperative tone, follow conventional commit style with scope, then below the subject line add a changelog in bullets.

  $diff"

  local message
  message=$(ai-request "$prompt")

  # Write message to temp file
  local msgfile
  msgfile=$(mktemp)
  echo "$message" > "$msgfile"

  # Open editor with pre-filled message before committing
  git commit $no_verify --edit -F "$msgfile"

  # Clean up temp file
  rm -f "$msgfile"
}

function aicmd() {
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$1" ]]; then
    echo "Usage: aicmd 'prompt'"
    echo "  - Generates a Linux command that fulfils <prompt>."
    echo "  - Prints the command followed by brief bullet explanations."
    echo "  - Copies only the command (first line) to your clipboard."
    echo
    echo "Example:"
    echo "  aicmd 'recursively find and delete all .DS_Store files'"
    return
  fi

  local user_prompt="$*"

  local oa_prompt="You are an expert Linux shell user. Respond **exactly** in this format:

  <command>

  - bullet 1
  - bullet 2
  - …

  Rules:
  * The **first line must contain only the command**. Do **not** wrap anything in backticks ( \` ), code fences ( \`\`\` ), or other Markdown formatting.
  * Do **not** prefix the command with “bash$ ” or similar.
  * Bullets must start with a single hyphen and a space, be concise, and avoid backticks.
  * Never include triple backticks anywhere in the reply.

  Task:

  $user_prompt"

  local result
  result=$(ai-request "$oa_prompt" "gpt-4.1") || {
    echo "ai-request failed." >&2
    return 1
  }

  local cmd info
  cmd=$(printf '%s\n' "$result" | head -n1)
  info=$(printf '%s\n' "$result" | tail -n +2)

  printf '%s\n%s\n' "$cmd" "$info"

  if command -v pbcopy >/dev/null 2>&1; then
    printf '%s' "$cmd" | pbcopy
  elif command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$cmd" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$cmd" | xclip -selection clipboard
  fi
}

function aiyank() {
  if [[ "$1" == "-h" || "$1" == "--help" || $# -eq 0 && -t 0 ]]; then
    echo "Usage: aiyank [fileA fileB ...] or via pipe"
    echo
    echo "Examples:"
    echo "  aiyank fileA.yaml fileB.json"
    echo "  ls | aiyank"
    return
  fi

  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$git_root" ]]; then
    echo "Error: not inside a git repository" >&2
    return 1
  fi

  local files=()

  if [[ $# -gt 0 ]]; then
    files=("$@")
  else
    # Read from pipe
    while IFS= read -r line; do
      [[ -n "$line" ]] && files+=("$line")
    done
  fi

  local rel_paths=()
  for f in "${files[@]}"; do
    if [[ -e "$f" ]]; then
      abs_path=$(realpath "$f")
      rel_path=$(python3 -c "import os; print(os.path.relpath('$abs_path', '$git_root'))")
      rel_paths+=("$rel_path")
    else
      echo "Warning: file '$f' does not exist" >&2
    fi
  done

  local result="${rel_paths[*]}"
  echo "$result"
  printf "%s" "$result" | pbcopy
  echo "Copied to clipboard."
}

vimreview() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  vimreview                  Open Neovim with Diffview showing staged changes"
    echo "  vimreview <REV>           Open Neovim with Diffview comparing against <REV>"
    echo "  git diff ... | vimreview  Open Neovim with diff of piped input (fallback viewer)"
    echo
    echo "Examples:"
    echo "  vimreview HEAD~3"
    echo "  git diff HEAD~3 | vimreview"
    return
  fi

  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    echo "Error: Not inside a Git repository." >&2
    return 1
  fi

  if [ ! -t 0 ]; then
    local tmpfile="/tmp/vimreview-$(date +%s)-$$.diff"
    cat > "$tmpfile"
    nvim -c "tabnew $tmpfile" -c "set filetype=diff"
    return
  fi

  local dummy_file
  dummy_file=$(git ls-files | head -n 1)
  if [[ -z "$dummy_file" ]]; then
    echo "Error: No tracked files found." >&2
    return 1
  fi

  local cmd="DiffviewOpen"
  [[ $# -eq 0 ]] && cmd+=" $1"

  nvim "$dummy_file" -c "$cmd"
}

function aiappend() {
  # Internal function to display help
  function _show_help() {
    echo "aiappend - Append useful context to the global Aider context file"
    echo
    echo "Usage:"
    echo "  aiappend [options]"
    echo
    echo "Options:"
    echo "  -h, --help       Show this help message"
    echo "  -c, --clipboard  Append clipboard content to the global context file"
    echo "  -o, --output     Append the last command output, the command itself, and its exit code"
    echo
    echo "Examples:"
    echo "  aiappend --clipboard"
    echo "  aiappend --output"
  }

  # Internal function to get clipboard content
  function _get_clipboard() {
    if command -v pbpaste &> /dev/null; then
      # macOS
      pbpaste
    elif command -v wl-paste &> /dev/null; then
      # Wayland
      wl-paste
    elif command -v xclip &> /dev/null; then
      # X11
      xclip -selection clipboard -o
    else
      echo "Error: No clipboard command found (pbpaste, wl-paste, or xclip)" >&2
      return 1
    fi
  }

  # Internal function to handle clipboard content
  function _handle_clipboard() {
    local context_file="$1"
    local content
    content=$(_get_clipboard)

    if [[ -z "$content" ]]; then
      echo "Error: Clipboard is empty" >&2
      return 1
    fi

    # Append clipboard content directly without headers or code blocks
    echo -e "\n${content}" >> "$context_file"
    echo "Appended clipboard content to $context_file"
  }

  # Internal function to handle last command output
  function _handle_output() {
    local context_file="$1"
    # Get the last command from history
    local last_cmd
    last_cmd=$(fc -ln -1 | sed 's/^\s*//')

    # Skip if the last command was aiappend itself
    if [[ "$last_cmd" == "aiappend"* ]]; then
      last_cmd=$(fc -ln -2 | sed 's/^\s*//')
    fi

    # Execute the command again to capture output and exit code
    local output
    local exit_code

    output=$(eval "$last_cmd" 2>&1) || exit_code=$?
    exit_code=${exit_code:-0}

    # Append command and output in a more concise format
    echo -e "\n\$ ${last_cmd}\n\n${output}\n\nExit Code: ${exit_code}" >> "$context_file"

    echo "Appended command '$last_cmd' and its output to $context_file"
  }

  # Default location for the global Aider context file
  local CONTEXT_FILE="${HOME}/.ai-context"

  # Create context file if it doesn't exist
  if [[ ! -f "$CONTEXT_FILE" ]]; then
    touch "$CONTEXT_FILE"
    echo "Created new context file at $CONTEXT_FILE"
  fi

  # Parse arguments
  if [[ $# -eq 0 || "$1" == "-h" || "$1" == "--help" ]]; then
    _show_help
    return 0
  fi

  case "$1" in
    -c|--clipboard)
      _handle_clipboard "$CONTEXT_FILE"
      ;;
    -o|--output)
      _handle_output "$CONTEXT_FILE"
      ;;
    *)
      echo "Error: Unknown option '$1'" >&2
      _show_help
      return 1
      ;;
  esac
}

function aicopy() {
  # Show help if no args and no stdin, or explicit help flag
  if [[ "$1" == "-h" || "$1" == "--help" || ( $# -eq 0 && -t 0 ) ]]; then
    echo "Usage:"
    echo "  aicopy <file1> [file2 ...]"
    echo "  ls -1 | aicopy"
    echo "  rg --files | aicopy"
    echo
    echo "Description:"
    echo "  Copies file names and contents to the clipboard."
    echo "  Accepts file paths via arguments and/or stdin (one path per line)."
    echo "  Only regular files are allowed — directories are skipped with a warning."
    echo "  For each file: prints the file name, a blank line, then its content."
    echo "  Files are separated by two blank lines."
    return 0
  fi

  # Collect inputs from stdin and args
  local inputs=()
  if [ ! -t 0 ]; then
    while IFS= read -r line; do
      [[ -n "$line" ]] && inputs+=("$line")
    done
  fi
  if (( $# > 0 )); then
    inputs+=("$@")
  fi
  if (( ${#inputs[@]} == 0 )); then
    echo "Error: No files provided (args or stdin)." >&2
    return 1
  fi

  # Portable mktemp (BSD/GNU)
  local tmpfile tmpdir="${TMPDIR:-/tmp}"
  tmpfile=$(mktemp "$tmpdir/aicopy.XXXXXX" 2>/dev/null) \
    || tmpfile=$(mktemp -t aicopy 2>/dev/null) \
    || { echo "Error: failed to create temp file." >&2; return 1; }
  trap 'rm -f "$tmpfile"' EXIT

  # Process each file
  local processed=0 first=true file
  for file in "${inputs[@]}"; do
    if [[ -d "$file" ]]; then
      echo "Warning: '$file' is a directory, skipping..." >&2
      continue
    elif [[ ! -f "$file" ]]; then
      echo "Warning: '$file' is not a regular file, skipping..." >&2
      continue
    fi

    # Two empty lines between files (none before the first)
    if [[ "$first" != true ]]; then
      printf '\n\n' >> "$tmpfile"
    else
      first=false
    fi

    # File name, one blank line, then content
    printf '%s\n\n' "$file" >> "$tmpfile"
    if ! cat -- "$file" >> "$tmpfile"; then
      echo "Error: failed to read '$file'." >&2
      continue
    fi

    ((processed++))
  done

  if (( processed == 0 )); then
    echo "Error: No valid files were processed" >&2
    return 1
  fi

  # Copy to clipboard (macOS, Wayland, X11, or copyq)
  local rc=0 copied_with=""
  if command -v pbcopy >/dev/null 2>&1; then
    pbcopy < "$tmpfile"; rc=$?; copied_with="pbcopy"
  elif command -v wl-copy >/dev/null 2>&1; then
    wl-copy < "$tmpfile"; rc=$?; copied_with="wl-copy"
  elif command -v xclip >/dev/null 2>&1; then
    xclip -selection clipboard < "$tmpfile"; rc=$?; copied_with="xclip"
  elif command -v copyq >/dev/null 2>&1; then
    copyq copy < "$tmpfile"; rc=$?; copied_with="copyq"
  else
    echo "Error: No clipboard command found (pbcopy, wl-copy, xclip, copyq)" >&2
    return 1
  fi
  if (( rc != 0 )); then
    echo "Error: clipboard command failed (exit $rc)." >&2
    return $rc
  fi

  # Always verify clipboard contents to detect truncation
  # Bytes of what we intended to copy:
  local expected_bytes
  expected_bytes=$(wc -c < "$tmpfile" | tr -d ' ')

  # Bytes actually in the clipboard (pick an available paste tool)
  local pasted_bytes=""
  if command -v pbpaste >/dev/null 2>&1; then
    pasted_bytes=$(pbpaste | wc -c | tr -d ' ')
  elif command -v wl-paste >/dev/null 2>&1; then
    pasted_bytes=$(wl-paste | wc -c | tr -d ' ')
  elif command -v xclip >/dev/null 2>&1; then
    pasted_bytes=$(xclip -selection clipboard -o 2>/dev/null | wc -c | tr -d ' ')
  elif command -v copyq >/dev/null 2>&1; then
    pasted_bytes=$(copyq read 2>/dev/null | wc -c | tr -d ' ')
  else
    echo "Warning: could not verify clipboard contents (no paste tool found)." >&2
    pasted_bytes=""
  fi

  if [[ -n "$pasted_bytes" ]] && (( pasted_bytes < expected_bytes )); then
    echo "Error: clipboard appears truncated (${pasted_bytes} of ${expected_bytes} bytes)." >&2
    echo "Hint: you may have hit a clipboard size limit. Try fewer/smaller files or split the copy." >&2
    return 1
  fi

  echo "Copied ${processed} file(s) to clipboard."
  # tmpfile auto-removed by trap
}

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
  echo >> "$GIT_CTX"
  echo "### git show (HEAD of TO: $TO_REF)" >> "$GIT_CTX"
  (git show --no-color "$TO_REF" || true) >> "$GIT_CTX"

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

  echo "# Code Review Request" >> "$REVIEW_FILE"
  echo >> "$REVIEW_FILE"
  echo "**Branch/Ref:** ${FROM_REF} → ${TO_REF}" >> "$REVIEW_FILE"
  echo "**Repository:** ${SSH_URL}" >> "$REVIEW_FILE"
  echo "**Review Context (working dir):** ${WORK_DIR}" >> "$REVIEW_FILE"
  echo >> "$REVIEW_FILE"
  echo "---" >> "$REVIEW_FILE"
  echo >> "$REVIEW_FILE"

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

  echo "## Git Context" >> "$REVIEW_FILE"
  echo >> "$REVIEW_FILE"
  cat "$GIT_CTX" >> "$REVIEW_FILE"
  echo >> "$REVIEW_FILE"
  echo "---" >> "$REVIEW_FILE"
  echo >> "$REVIEW_FILE"

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

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
alias curl='curl --noproxy "*"'
alias sudo='sudo '
alias vim=nvim

# Useful when using aider:
# brew upgrade aider
# --copy-paste: for working wih chatgpt web UI, when throttling begins
# claude-sonnet-4-20250514
# claude-3-7-sonnet-20250219
# gpt-4.1-2025-04-14
# gpt-4.1-mini-2025-04-14
# gpt-4.1-nano-2025-04-14
# o3-2025-04-16
# o4-mini-2025-04-16
alias aid='aider --add-gitignore-files --no-auto-commits --no-dirty-commits --no-attribute-author --no-attribute-committer --no-attribute-commit-message-author --no-attribute-commit-message-committer --no-attribute-co-authored-by --stream --subtree-only --map-tokens 4096 --map-multiplier-no-files 2 --map-refresh auto --editor nvim --pretty --code-theme monokai --edit-format diff --editor-edit-format diff --read ~/.claude/CLAUDE.md --max-chat-history-tokens 0 --skip-sanity-check-repo --watch-files --cache-prompts --cache-keepalive-pings 3 --no-auto-accept-architect --alias 41:gpt-4.1 --alias 41m:gpt-4.1-mini --alias 41n:gpt-4.1-nano --alias o4m:o4-mini-2025-04-16 --model 41m --editor-model 41m --weak-model 41n --no-verify-ssl'
alias aidc='aid --restore-chat-history'

alias cd-git-root='cd `git rev-parse --show-toplevel`'
alias rg="rg --hidden --follow -g '!html/*' -g '!.git/*' -g '!node_modules/*' -g '!vendor/*' -g '!dist/*' -g '!build/*' -g '!.next/*' -g '!out/*' -g '!coverage/*' -g '!.cache/*'"
alias tree="tree -C -I 'html' -I '.git' -I 'node_modules' -I 'vendor' -I 'dist' -I 'build' -I '.next' -I 'out' -I 'coverage' -I '.cache'"
alias cd-home="cd ~"
alias claude="unset ANTHROPIC_API_KEY && ANTHROPIC_API_KEY="" claude"

# Check if copyq exists in PATH
if ! which copyq &>/dev/null; then
  alias copyq="/Applications/CopyQ.app/Contents/MacOS/CopyQ"
fi

export FZF_CTRL_T_COMMAND="if git_root=\$(git rev-parse --show-toplevel 2>/dev/null); then rg --files \"\$git_root\" | node -e 'const { relative, resolve } = require(\"path\"); const cwd = process.cwd(); require(\"readline\").createInterface({ input: process.stdin }).on(\"line\", l => console.log(relative(cwd, resolve(l))))'; else rg --files | sed 's|^\\./||'; fi"
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export AWS_CLI_FILE_ENCODING=UTF-8
export AWS_PAGER=""

# Add node global binaries to PATH
export PATH="$PATH:/usr/local/bin"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

# Created by `pipx` on 2024-09-18 21:03:30
export PATH="$PATH:/Users/brunoagostini/.local/bin"

export AIDER_EDITOR=nvim
export EDITOR=nvim
export VISUAL=nvim

source ~/.temporary-global-envs.sh
source ~/.secrets.sh

# AsyncAPI CLI Autocomplete

ASYNCAPI_AC_ZSH_SETUP_PATH=/Users/brunoagostini/Library/Caches/@asyncapi/cli/autocomplete/zsh_setup && test -f $ASYNCAPI_AC_ZSH_SETUP_PATH && source $ASYNCAPI_AC_ZSH_SETUP_PATH; # asyncapi autocomplete setup
