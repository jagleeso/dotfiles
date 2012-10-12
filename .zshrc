# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# fix bug where updates don't work
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
#ZSH_THEME="robbyrussell"
ZSH_THEME="james"
#ZSH_THEME="blinks"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git svn zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
if [ -n "$TMUX" ]; then
    export TERM=screen-256color 
else
    export TERM=xterm-256color
fi

# Customize to your needs...
export PATH=/home/james/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:~/smlnj/bin

export PYTHONPATH=".:~/python"
# disable xoff ctrl-s shortcut that locks up vi
# stty -ixon
stty stop '' -ixoff

bindkey ^e backward-delete-word
bindkey ^f backward-word
bindkey ^k forward-word

# apt-get/apt-cache/apt-file aliases
alias ainstall="sudo apt-get install"
alias asearch="apt-cache search"
alias ashow="apt-cache show"
if [ -x `which ack-grep` ]; then
    alias ack="ack-grep"
fi
afiles() {
    # $1 == exact package name
    apt-file list --regexp  "^$1\$" | sed "s/^$1:\s*//"
}
alias gopen="gnome-open"

gitdiff() {
    git diff --quiet "$@" ||
        git diff "$@" | vim -
}

svndiff() {
    svn diff "$@" | vim -
}

# source ~/.school

# disable ctrl-s scroll locking
stty -ixon

alias sml="socat READLINE EXEC:sml"

alias vim="nocorrect vim"

# jsctags
export NODE_PATH=~/.jsctags/lib/jsctags/:$NODE_PATH
