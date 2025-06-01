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

function compileMermaid () {
  mermaidFile=$1
  fileName=$(echo "$mermaidFile" | cut -d '.' -f 1)

  mmdc -i $mermaidFile -o ${fileName}.png --scale 4
  # convert -trim $fileName.png $fileName.png
}

function compileGanttMermaid () {
  mermaidFile=$1

  width=$2
  if [ -z "$width" ]; then
    width=2048
  fi

  fileName=$(echo "$mermaidFile" | cut -d '.' -f 1)

  mmdc -i $mermaidFile -o ${fileName}.svg --scale 4 --width $width
}

function generateSchemaFromJson () {
  inputJson=$1
  fileName=$(basename "$inputJson" .json)

  npx quicktype --src "$(pwd)/$1" --src-lang json --out "$(pwd)/${fileName}.schema.json" --lang schema
  npx @openapi-contrib/json-schema-to-openapi-schema convert "$(pwd)/${fileName}.schema.json" | jq '.' > "$(pwd)/${fileName}.openapi.json"
}

function sortFieldNamesInJson () {
  jq 'map(to_entries | sort_by(.key) | from_entries)'
}

function sortArrayElementsInJsonByField () {
  fieldName=$1

  jq --arg field "$fieldName" '
    (map(select(has($field))) | sort_by(.[$field])) + 
    (map(select(has($field) | not)))
  '
}

function meldSorted () {
  fileA=$1
  fileB=$2

  sortedFileA=/tmp/sorted-$(basename $fileA)
  sortedFileB=/tmp/sorted-$(basename $fileB)

  sort $fileA > $sortedFileA
  sort $fileB > $sortedFileB

  meld $sortedFileA $sortedFileB
}

function searchAndReplaceViaNvim() {
  local pattern="$1"
  local replace="$2"

  if [ -z "$pattern" ] || [ -z "$replace" ]; then
    echo "Usage: vimSearchAndReplace <search_pattern> <replace_pattern>"
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

function nodeDebugReminder() {
  echo "🔥 Node Debugger Quick Steps 🔥"
  echo
  echo "✅ 1) Add 'debugger;' statements in your test file"
  echo "✅ 2) In one terminal, run:"
  echo "   node --inspect-brk ./node_modules/.bin/jest [tests/myFeature.test.js]"
  echo
  echo "✅ 3) In another terminal, attach the debugger with:"
  echo "   node inspect localhost:9229"
  echo
  echo "✅ 4) Builtin Debugger Commands:"
  echo "   c      – continue"
  echo "   n      – step over"
  echo "   s      – step into"
  echo "   o      – step out"
  echo "   repl   – enter full REPL mode (like a mini Node console)"
  echo "   restart – restart the debug session"
  echo "   watch('someVar') – watch a variable"
  echo
  echo "🪄 Enjoy your debugging session! 🚀"
}

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
alias curl='curl --noproxy "*"'
alias sudo='sudo '
alias vim=nvim
alias aider='aider --no-verify-ssl --show-diffs --subtree-only --no-auto-commits --analytics --editor nvim --code-theme monokai --dark-mode --architect'
alias cd-gitroot='cd `git rev-parse --show-toplevel`'
alias rg="rg --hidden --follow -g '!.git/*' -g '!node_modules/*' -g '!vendor/*' -g '!dist/*' -g '!build/*' -g '!.next/*' -g '!out/*' -g '!coverage/*' -g '!.cache/*'"
alias tree="tree -C -I '.git' -I 'node_modules'"
alias cdh="cd ~"
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

# export NODE_TLS_REJECT_UNAUTHORIZED=0
export PYTHONHTTPSVERIFY=0

export AIDER_EDITOR=nvim
export EDITOR=nvim
export VISUAL=nvim

source ~/.temporary-global-envs.sh
source ~/.secrets.sh

