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

# Auto-source all utility functions from func-utilities directory
if [ -d "$HOME/oh-my-zsh/func-utilities" ]; then
  for utility_file in "$HOME/oh-my-zsh/func-utilities"/*.sh; do
    [ -f "$utility_file" ] && source "$utility_file"
  done
  unset utility_file
fi

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

alias cdgitroot='cd `git rev-parse --show-toplevel`'
alias rg="rg --hidden --follow -g '!html/*' -g '!.git/*' -g '!node_modules/*' -g '!vendor/*' -g '!dist/*' -g '!build/*' -g '!.next/*' -g '!out/*' -g '!coverage/*' -g '!.cache/*'"
alias tree="tree -C -I 'html' -I '.git' -I 'node_modules' -I 'vendor' -I 'dist' -I 'build' -I '.next' -I 'out' -I 'coverage' -I '.cache'"
alias cdhome="cd ~"
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
