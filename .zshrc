# Path to your oh-my-zsh configuration.
export ZSH_DISABLE_COMPFIX="true"

# UTF-8 locale needed to prevent remnant characters when pressing "TAB" for autocomplete.
#
# NOTE: this issue appeared after using "tmux -u" to make oh-my-zsh's unicode 
# term-prompt characters show up in tmux.
#
# https://stackoverflow.com/questions/19305291/remnant-characters-when-tab-completing-with-zsh
export LC_ALL="en_US.UTF-8"

# fix bug where updates don't work
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
# ZSH_THEME="robbyrussell"
# ZSH_THEME="af-magic"
ZSH_THEME="james"
# ZSH_THEME="james-remote"
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

# Suggested by _bazel autocmplete
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Example format: plugins=(rails git textmate ruby lighthouse)
# plugins=(zsh-syntax-highlighting)
plugins=(git svn zsh-syntax-highlighting ssh-agent)
if which fd >&/dev/null; then
    plugins+=(fd)
    # When running fzf, respect .gitignore (fd inherently respects .gitignore)
    # https://github.com/junegunn/fzf#respecting-gitignore
    # export FZF_DEFAULT_COMMAND='fd --type f'
    # Keep directories.
    export FZF_DEFAULT_COMMAND='fd'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# ssh-agent: Load these identity files
#
# NOTE: 
# - If you add new identities, you must kill existing ssh-agent and re-login.
#   Use this command to locate the running ssh-agent process.
#   $ ps aux | grep ssh-agent | grep $USER | grep -v grep
# - This line must come before sourcing oh-my-zsh.sh
#
# https://github.com/robbyrussell/oh-my-zsh/tree/master/plugins/ssh-agent
SSH_KEY_LIST=()
SSH_KEY_LIST+=()
_maybe_add_ssh_key() {
    local basename="$1"
    shift 1
    if [ -e "$HOME/.ssh/$basename" ]; then
        SSH_KEY_LIST+=("$basename")
    fi
}
_maybe_add_ssh_key id_rsa
_maybe_add_ssh_key id_rsa_git
_maybe_add_ssh_key google_compute_engine
_maybe_add_ssh_key id_rsa_vector
_maybe_add_ssh_key id_rsa_azure
# echo "SSH_KEY_LIST = ${SSH_KEY_LIST[@]}"
zstyle :omz:plugins:ssh-agent identities ${SSH_KEY_LIST[@]}
# zstyle :omz:plugins:ssh-agent identities id_rsa id_rsa_git google_compute_engine

if [ -e $ZSH/oh-my-zsh.sh ]; then
    source $ZSH/oh-my-zsh.sh
fi

export PYTHONPATH
# http://www.zsh.org/mla/users/2012/msg00785.html
# -T ties an environment variable to a zsh array
# -U makes the elements of an array unique (i.e. it's a set)
typeset -T PYTHONPATH pythonpath
typeset -U pythonpath
pythonpath=(. $HOME/python $HOME/clone/dotfiles/src/python $HOME/.vim/src/python $pythonpath)

if [ -n "$TMUX" ]; then
    export TERM=screen-256color 
else
    export TERM=xterm-256color
fi

export EDITOR=vim

# source ~/.zshrc_path

_maybe_set_cuda_home() {
    local cuda_home="$1"
    shift 1

    if [ "$CUDA_HOME" != "" ]; then
        # Already set.
        return 1
    fi

    if [ -d "$cuda_home/bin" ] && [ -d "$cuda_home/lib64" ]; then
        export CUDA_HOME="$cuda_home"
        export PATH=$PATH:$CUDA_HOME/bin
        export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_HOME/lib64
        if [ -d $CUDA_HOME/extras/CUPTI/lib64 ]; then
            export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_HOME/extras/CUPTI/lib64
        fi
        return 0
    fi

    return 1
}

_source_if() {
    if [ -f "$1" ]; then
        source "$1"
    fi
}



_maybe_set_cuda_home /usr/local/cuda
# _source_if ~/.zshrc.gpu
# _source_if ~/.zshrc.vnc
# _source_if ~/.zshrc.vmgl
# _source_if ~/.zshrc.mic
# _source_if ~/.zshrc.rocm
# _source_if ~/.zshrc.tensorflow
# _source_if ~/.zshrc.cuda
# _source_if ~/.zshrc.school
# _source_if ~/.zshrc.mpi
#_source_if ~/.zshrc.mxnet
_source_if ~/.zshrc.windows
_source_if ~/.zshrc.go
export DOT_HOME="$HOME/clone/dotfiles"
_source_if ~/.dot_exports.sh
if [ "$(hostname)" = "james-tesla" ]; then
    _source_if ~/.zshrc.azure_james_tesla
fi
_source_if ~/.zshrc.vector
_source_if ~/.zshrc.pyenv
# _source_if ~/.zshrc.db
unset _source_if



if [ -x "`which vimpager 2>/dev/null`" ]; then
    export PAGER="`which vimpager`"
    alias less=$PAGER 
    alias zless=$PAGER
fi

bindkey ^u undo
bindkey ^e kill-word
bindkey ^f forward-word
bindkey ^s backward-word
bindkey ^g beginning-of-line
bindkey ^v end-of-line
bindkey ^x^e edit-command-line

# apt-get/apt-cache/apt-file aliases
alias ainstall="sudo apt-get install --assume-yes"
alias aremove="sudo apt-get remove"
alias asearch="apt-cache search"
alias alist="apt-file list"
alias ashow="apt-cache show"
alias ainfo="ashow"
alias afile="apt-file search"
alias aprovides="apt-file search"
if [ -x "`which ag`" ]; then
    alias ack="ag"
fi
afiles() {
    # $1 == exact package name
    apt-file list --regexp  "^$1\$" | sed "s/^$1:\s*//"
}
alias gopen="gnome-open"

# Takes forever to start over X11 otherwise...
alias xterm='xterm +u8'

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
if [ "$WINDOWS_SCRIPT" != 'yes' ]; then
    stty stop '' -ixoff
    stty -ixon
fi

alias sml="socat READLINE EXEC:sml"

alias vim="nocorrect vim"
alias rsync="rsync -avz"

# rsync with .gitignore files ignored
# http://stackoverflow.com/questions/13713101/rsync-exclude-according-to-gitignore-hgignore-svnignore-like-filter-c
rsyncg() {
    rsync --filter=":- $HOME/.gitignore" --filter=':- .gitignore' "$@"
}

# jsctags
export NODE_PATH=~/.jsctags/lib/jsctags/:$NODE_PATH

# alias cboard="xsel -i --clipboard"

PATH=$HOME/bin:$HOME/local/bin:~/.fzf:$PATH:$HOME/.rvm/bin

# set tmux options requiring if-statement checks (tmux.conf doesn't support this)
# Tell tmux we support utf-8 so fancy characters in oh-my-zsh prompt show up.
alias tmux='tmux -u'
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
        # For some reason, xclip is hanging in ubuntu with tmux1.8, until I open vim and yank 
        # a line, which causes all tmux events to suddenly stream in...just use xsel instead.
        # tmux bind-key C-f run "tmux show-buffer | xclip -i -selection clipboard"
        #
        # For some reason, xsel WORKS, but xclip causes 
        # tmux Ctrl-a <anything> to not work.
        #
        tmux bind-key C-f run "tmux show-buffer | xsel -i --clipboard" 
        # tmux bind-key C-f run "tmux show-buffer | xclip -i -selection clipboard" 
        #Copy CLIPBOARD to tmux paste buffer and paste tmux paste buffer
        tmux bind-key C-v run "tmux set-buffer \"$(xclip -o -selection clipboard)\"; tmux paste-buffer"
    fi

fi

function chpwd() {
    # Each time we cd into a directory, if there's a .zsh_config file, source it.
    if [ -r $PWD/.zsh_config ]; then
        source $PWD/.zsh_config
    fi
}

# if [ -x "`which lein`" ]; then
#     alias iclojure="lein trampoline irepl"
# fi

# source any computer specific zsh stuff:
export ZSH_BIN="$HOME/bin/zsh"

# My home desktop
# source ~/.zshrc_mypc

# My uoft desktop
__NO_ANDROID_PATH="$PATH"
# source ~/.zshrc_uoftpc
function android_bash() {
    PATH="$__NO_ANDROID_PATH" bash "$@"
}

# source ~/.bashrc_uoftpc

# source ~/.zshrc_samsung

unset ZSH_BIN

setopt HIST_IGNORE_SPACE
setopt interactivecomments

# ohmyzsh broke stuff
# setopt sharehistory
# setopt histappend 
# export HISTSIZE=100000 
# export HISTFILESIZE=1000000

TIMEFMT=$'\nreal\t%E\nuser\t%U\nsys\t%S'

# All hail the glory of the color gods.
# http://ciembor.github.io/4bit/#
# gconftool-2 --set /apps/gnome-terminal/profiles/Default/use_theme_background --type bool false 
# gconftool-2 --set /apps/gnome-terminal/profiles/Default/use_theme_colors --type bool false 
# gconftool-2 -s -t string /apps/gnome-terminal/profiles/Default/background_color '#0d0d19192626'
# gconftool-2 -s -t string /apps/gnome-terminal/profiles/Default/foreground_color '#d9d9e6e6f2f2'
# gconftool-2 -s -t string /apps/gnome-terminal/profiles/Default/palette '#0d0d19192626:#dede80805454:#5454dede8080:#b2b2dede5454:#80805454dede:#dede5454b2b2:#5454b2b2dede:#d9d9e5e5f2f2:#737380808d8d:#eeeebfbfaaaa:#aaaaeeeebfbf:#d9d9eeeeaaaa:#bfbfaaaaeeee:#eeeeaaaad9d9:#aaaad9d9eeee:#d9d9e5e5f2f2'

# Use ## as the trigger sequence instead of the default **
export FZF_COMPLETION_TRIGGER='##'
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

if [ -e ~/anaconda3/bin/conda ]; then
    alias aconda=~/anaconda3/bin/conda
fi
