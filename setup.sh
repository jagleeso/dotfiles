#!/bin/bash
set -e

NCPU=$(grep -c ^processor /proc/cpuinfo)

setup_dotfiles() {
    local CLONE_DIR=$HOME/clone/dotfiles
    cd $HOME
    for f in $CLONE_DIR/.*; do
        if [ -f $f ]; then
            ln -s -T $f $(basename $f) || true
        fi
    done
}
setup_zsh() {
    if [ -d $HOME/.oh-my-zsh ]; then
        return
    fi
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
}
setup_vim() {
    if [ -f $HOME/local/bin/vim ]; then
        return
    fi
    mkdir -p $HOME/local
    if [ ! -d $HOME/clone/vim ]; then
        (
            mkdir -p $HOME/clone
            cd $HOME/clone
            git clone https://github.com/vim/vim.git
        )
    fi
    sudo apt install -y \
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
    )
}
setup_packages() {
    sudo apt install -y htop zsh 
}
setup_all() {
    setup_packages
    setup_zsh
    setup_dotfiles
    setup_vim
}

(
    if [ $# -lt 1 ]; then
        setup_all
    else
        "$@"
    fi
)
