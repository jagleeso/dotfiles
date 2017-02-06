#!/bin/bash
set -e
# set -x

NCPU=$(grep -c ^processor /proc/cpuinfo)

_install() {
    sudo apt install -y "$@"
}

setup_dotfiles() {
    local CLONE_DIR=$HOME/clone/dotfiles
    cd $HOME
    for f in $CLONE_DIR/.*; do
        if [ -f $f ]; then
            (
                ln -s -T $f $(basename $f) 2>&1 | grep -v 'File exists'
            ) || true
        fi
    done
}
setup_zsh() {
    if [ -d $HOME/.oh-my-zsh ]; then
        return
    fi
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    cp -r $HOME/clone/dotfiles/.oh-my-zsh/* $HOME/.oh-my-zsh
}
REINSTALLED_VIM=no
setup_vim() {
    if [ -f $HOME/local/bin/vim ]; then
        return
    fi
    REINSTALLED_VIM=yes
    mkdir -p $HOME/local
    if [ ! -d $HOME/clone/vim ]; then
        (
            mkdir -p $HOME/clone
            cd $HOME/clone
            git clone https://github.com/vim/vim.git
        )
    fi
    _install \
        libncurses5-dev libgnome2-dev libgnomeui-dev \
        libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
        libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
        python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git
    (
        cd $HOME/clone/vim
        ./configure --with-features=huge \
            --enable-multibyte \
            --enable-rubyinterp=yes \
            --enable-pythoninterp=yes \
            --with-python-config-dir=/usr/lib/python2.7/config \
            --enable-python3interp=yes \
            --with-python3-config-dir=/usr/lib/python3.5/config \
            --enable-perlinterp=yes \
            --enable-luainterp=yes \
            --enable-gui=gtk2 \
            --enable-cscope \
            --prefix=$HOME/local
        make -j$NCPU install
        vim -c PluginInstall -c quit -c quit
    )
}
setup_ycm_before() {
    sudo apt-get -y install build-essential cmake python-dev python3-dev
}
setup_ycm_after() {
    if [ "$REINSTALLED_VIM" == 'no' ]; then
        return
    fi
    ( 
        cd $HOME/.vim/bundle/YouCompleteMe
        ./install.py --clang-completer
    )
}
setup_packages() {
    _install htop zsh tree
}   
setup_fzf() {
    if [ -d $HOME/.fzf ]; then
        return
    fi
    _install libncurses5-dev
    sudo gem install curses
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
    mv $HOME/.fzf/install $HOME/.fzf/install.fzf
    mv $HOME/.fzf/uninstall $HOME/.fzf/uninstall.fzf
    $HOME/.fzf/install.fzf --no-key-bindings --no-completion --no-update-rc
    (
        cd $HOME/.fzf
        git apply $HOME/clone/dotfiles/patches/fzf.patch
    )
}
setup_all() {
    setup_packages
    setup_zsh
    setup_fzf
    setup_dotfiles
    setup_ycm_before
    setup_vim
    setup_ycm_after
}

(
    if [ $# -lt 1 ]; then
        setup_all
    else
        "$@"
    fi
)
