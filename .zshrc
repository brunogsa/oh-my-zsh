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
  if [ -z "$1" ]; then
    echo "Usage: gen-schema-from-json <input_json_file>"
    return 1
  fi

  inputJson="$1"
  fileName=$(basename "$inputJson" .json)

  npx quicktype --src "$(pwd)/$inputJson" --src-lang json --out "$(pwd)/${fileName}.schema.json" --lang schema
  npx @openapi-contrib/json-schema-to-openapi-schema convert "$(pwd)/${fileName}.schema.json" | jq '.' > "$(pwd)/${fileName}.openapi.json"
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

function openai-request() {
  local prompt="$1"

  local json
  json=$(jq -n \
    --arg model "gpt-4o" \
    --arg temp "0.2" \
    --arg prompt "$prompt" \
      '{
        model: $model,
        temperature: ($temp | tonumber),
        messages: [
          { role: "system", content: $prompt }
        ]
      }'
  )

  local response
  response=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Authorization: Bearer $OPENAI_API_KEY" \
    -H "Content-Type: application/json" \
    -d "$json"
  )

  jq -r '.choices[0].message.content' <<< "$response"
}

function ai-changelog() {
  if [[ -t 0 ]] || [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  ai-changelog [-h | --help]"
    echo "  git diff HEAD~1 | ai-changelog"
    echo ""
    echo "Description:"
    echo "  Generates a changelog summary in bullet points from a git diff using GPT-4o"
    return
  fi

  local diff
  diff=$(cat)

  local prompt="Summarize the following git diff into concise bullet points:

  $diff"

  openai-request "$prompt"
}

function ai-git-commit() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  ai-git-commit [--no-verify]"
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
  message=$(openai-request "$prompt")

  # Write message to temp file
  local msgfile
  msgfile=$(mktemp)
  echo "$message" > "$msgfile"

  # Open editor with pre-filled message before committing
  git commit $no_verify --edit -F "$msgfile"

  # Clean up temp file
  rm -f "$msgfile"
}


# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
alias curl='curl --noproxy "*"'
alias sudo='sudo '
alias vim=nvim
alias aider='aider --no-verify-ssl --no-auto-commits --no-attribute-author --no-attribute-committer --no-attribute-commit-message-author --no-attribute-commit-message-committer --no-attribute-co-authored-by --stream --subtree-only --show-diffs --editor nvim --vim --pretty --code-theme monokai --architect --model o4-mini --editor-model 4o'
alias aider-continue='aider --restore-chat-history'
alias claude='claude --verbose'
alias cd-git-root='cd `git rev-parse --show-toplevel`'
alias rg="rg --hidden --follow -g '!html/*' -g '!.git/*' -g '!node_modules/*' -g '!vendor/*' -g '!dist/*' -g '!build/*' -g '!.next/*' -g '!out/*' -g '!coverage/*' -g '!.cache/*'"
alias tree="tree -C -I 'html' -I '.git' -I 'node_modules' -I 'vendor' -I 'dist' -I 'build' -I '.next' -I 'out' -I 'coverage' -I '.cache'"
alias cd-home="cd ~"
#
# Check if copyq exists in PATH
if ! which copyq &>/dev/null; then
  alias copyq="/Applications/CopyQ.app/Contents/MacOS/CopyQ"
fi

if git rev-parse --show-toplevel &>/dev/null; then
  export FZF_CTRL_T_COMMAND='rg --files `git rev-parse --show-toplevel | xargs realpath --relative-to="${PWD}"`'
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
