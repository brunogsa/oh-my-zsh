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

DISABLE_AUTO_TITLE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

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

function meldSorted () {
  fileA=$1
  fileB=$2

  sortedFileA=/tmp/sorted-$(basename $fileA)
  sortedFileB=/tmp/sorted-$(basename $fileB)

  sort $fileA > $sortedFileA
  sort $fileB > $sortedFileB

  meld $sortedFileA $sortedFileB
}

function compileMermaid () {
  mermaidFile=$1
  fileName=$(echo "$mermaidFile" | cut -d '.' -f 1)

  mmdc -i $mermaidFile -o ${fileName}.png --scale 4
  convert -trim $fileName.png $fileName.png
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

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
alias curl='curl --noproxy "*"'
alias sudo='sudo '
alias vim=nvim
alias cd-gitroot='cd `git rev-parse --show-toplevel`'
alias rg="rg --hidden --follow -g '!*.git*'"
alias tree="tree -C -I '.git' -I 'node_modules'"
alias cdh="cd ~"

export FZF_CTRL_T_COMMAND='rg --files `git rev-parse --show-toplevel | xargs realpath --relative-to="${PWD}"`'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Add node global binaries to PATH
export PATH="$PATH:/usr/local/bin"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
