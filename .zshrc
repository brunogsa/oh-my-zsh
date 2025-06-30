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

  # 1. Try OpenAI (gpt-4o)
  ##########################################################
  local openai_json
  openai_json=$(jq -n \
    --arg model "gpt-4o" \
    --arg temp "0.2" \
    --arg prompt "$prompt" \
    '{
      model: $model,
      temperature: ($temp | tonumber),
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
    echo "  ai-diff-changelog [-h | --help]"
    echo "  git diff HEAD~1 | ai-diff-changelog"
    echo ""
    echo "Description:"
    echo "  Generates a changelog summary in bullet points from a git diff using GPT-4o"
    return
  fi

  local diff
  diff=$(cat)

  local prompt="Summarize the following git diff into concise bullet points:

  $diff"

  ai-request "$prompt"
}

function aigitcommit() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  aigitcommit [--no-verify]"
    echo ""
    echo "Description:"
    echo "  Uses GPT-4o to generate a commit message from staged changes,"
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
  result=$(ai-request "$oa_prompt") || {
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

  local cmd="/add ${rel_paths[*]}"
  echo "$cmd"
  printf "%s" "$cmd" | pbcopy
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
# --weak-model MODEL
# claude-sonnet-4-20250514
# claude-3-7-sonnet-20250219
# gpt-4.1-2025-04-14
# gpt-4.1-mini-2025-04-14
# o3-2025-04-16
# o4-mini-2025-04-16
alias aider='aider --no-verify-ssl --add-gitignore-files --no-auto-commits --no-dirty-commits --no-attribute-author --no-attribute-committer --no-attribute-commit-message-author --no-attribute-commit-message-committer --no-attribute-co-authored-by --stream --subtree-only --map-tokens 8192 --map-multiplier-no-files 1 --map-refresh auto --editor nvim --pretty --code-theme monokai --architect --no-auto-accept-architect --model claude-3-7-sonnet-20250219 --editor-model gpt-4.1-2025-04-14 --weak-model gpt-4.1-mini-2025-04-14 --read ~/linux-utils/configs/ai-docs/CONVENTIONS.md --read ~/.ai-context --restore-chat-history --max-chat-history-tokens 16384 --skip-sanity-check-repo'

alias cd-git-root='cd `git rev-parse --show-toplevel`'
alias rg="rg --hidden --follow -g '!html/*' -g '!.git/*' -g '!node_modules/*' -g '!vendor/*' -g '!dist/*' -g '!build/*' -g '!.next/*' -g '!out/*' -g '!coverage/*' -g '!.cache/*'"
alias tree="tree -C -I 'html' -I '.git' -I 'node_modules' -I 'vendor' -I 'dist' -I 'build' -I '.next' -I 'out' -I 'coverage' -I '.cache'"
alias cd-home="cd ~"

# Check if copyq exists in PATH
if ! which copyq &>/dev/null; then
  alias copyq="/Applications/CopyQ.app/Contents/MacOS/CopyQ"
fi

if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then
  # Within a git repo, searches in the entire git repo, with relative paths
  export FZF_CTRL_T_COMMAND="rg --files '$git_root' | node -e 'const { relative, resolve } = require(\"path\"); const cwd = process.cwd(); require(\"readline\").createInterface({ input: process.stdin }).on(\"line\", l => console.log(relative(cwd, resolve(l))))'"
else
  # Without a git repo, searches in subtree folder
  export FZF_CTRL_T_COMMAND="rg --files | sed 's|^\./||'"
fi
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

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
