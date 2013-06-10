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

# add user defined locations for completion scripts
fpath=($HOME/.zsh/completion $fpath)

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git svn zsh-syntax-highlighting)

source $ZSH/oh-my-zsh.sh
if [ -n "$TMUX" ]; then
    export TERM=screen-256color 
else
    export TERM=xterm-256color
fi

export EDITOR=vim
if [ -x "`which vimpager`" ]; then
    export PAGER="`which vimpager`"
    alias less=$PAGER 
    alias zless=$PAGER
fi

# Customize to your needs...
export PATH=/home/james/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:~/smlnj/bin

export PYTHONPATH=".:$HOME/python:$HOME/.vim/src/python"
# disable xoff ctrl-s shortcut that locks up vi
# stty -ixon
stty stop '' -ixoff

bindkey ^e backward-delete-word
bindkey ^f backward-word
bindkey ^k forward-word

# apt-get/apt-cache/apt-file aliases
alias ainstall="sudo apt-get install"
alias aremove="sudo apt-get remove"
alias asearch="apt-cache search"
alias ashow="apt-cache show"
if [ -x "`which ack-grep`" ]; then
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
compdef _git-diff gitdiff

# gitd i => diff between the the i+1-th and i-th commit on the current branch
# e.g. gitd 0 => show me the diff caused by the latest commit
gitd() {
    local i="$1"
    git d HEAD~$((i+1)) HEAD~$i 
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

# set tmux options requiring if-statement checks (tmux.conf doesn't support this)
if [ -n "$TMUX" ]; then

    # platform specific options
    
    ##CLIPBOARD selection integration
    ##Requires prefix key before the command key
    if uname | grep --quiet -i darwin; then
        tmux set-option -g default-command "reattach-to-user-namespace -l zsh" # or bash...
        tmux bind C-f run "tmux save-buffer - | reattach-to-user-namespace pbcopy"
        tmux bind C-v run "reattach-to-user-namespace pbpaste | tmux load-buffer - && tmux paste-buffer"
    else
        #Copy tmux paste buffer to CLIPBOARD
        tmux bind-key C-f run "tmux show-buffer | xclip -i -selection clipboard"
        #Copy CLIPBOARD to tmux paste buffer and paste tmux paste buffer
        tmux bind-key C-v run "tmux set-buffer \"$(xclip -o -selection clipboard)\"; tmux paste-buffer"
    fi

fi

function chpwd() {
    if [ -r $PWD/.zsh_config ]; then
        source $PWD/.zsh_config
    fi
}
