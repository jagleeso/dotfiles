#!/bin/bash
set -e
if [ "$DEBUG" = 'yes' ]; then
    set -x
fi

# Hopefully the most stable one.
VIM_TAG="v8.0.0000"
VIM_PY2_CONFIG_DIR=/usr/lib/python2.7/config
VIM_PY3_CONFIG_DIR=/usr/lib/python2.7/config

# Force re-running setup
if [ "$FORCE" = "" ]; then
    FORCE=no
fi

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
    # reload dotfiles
    if [[ $SHELL =~ zsh ]]; then
        source $HOME/.zshrc
    fi 
}
setup_zsh() {
    if [ "$FORCE" != 'yes' ] && [ -d $HOME/.oh-my-zsh ]; then
        return
    fi
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    cp -r $HOME/clone/dotfiles/.oh-my-zsh/* $HOME/.oh-my-zsh
    if [ -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
        return
    fi
    git clone \
        https://github.com/zsh-users/zsh-syntax-highlighting.git \
        $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
}
REINSTALLED_VIM=no
setup_vim() {
    if [ "$FORCE" != 'yes' ] && [ -f $HOME/local/bin/vim ]; then
        return
    fi

    REINSTALLED_VIM=yes
    mkdir -p $HOME/local
    mkdir -p $HOME/clone
    if [ ! -d $HOME/clone/vim ]; then
        (
            cd $HOME/clone
            git clone https://github.com/vim/vim.git
            git checkout $VIM_TAG
        )
    else
        (
            cd $HOME/clone/vim
            # make clean
            git fetch
            git checkout $VIM_TAG
        )
    fi

    _install \
        libncurses5-dev libgnome2-dev libgnomeui-dev \
        libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
        libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
        python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git

    (
        cd $HOME/clone/vim
        # --enable-pythoninterp=yes
        # http://stackoverflow.com/questions/23023783/vim-compiled-with-python-support-but-cant-see-sys-version
        #
        # TLDR: 
        # Linux vim cannot load both python2 and python3, causing them to both be loaded 
        # dynamically, which makes YCM angry.
        #
        # Solution: 
        # use only one, disable the other.
        ./configure --with-features=huge \
            --enable-multibyte \
            --enable-rubyinterp=yes \
            --with-python-config-dir=$VIM_PY2_CONFIG_DIR \
            --enable-python3interp=yes \
            --with-python3-config-dir=$VIM_PY3_CONFIG_DIR \
            --enable-perlinterp=yes \
            --enable-luainterp=yes \
            --enable-gui=gtk2 \
            --enable-cscope \
            --prefix=$HOME/local
        make -j$NCPU install
        vim -c PluginInstall -c PluginUpdate -c quit -c quit
    )
}
setup_ycm_before() {
    sudo apt-get -y install build-essential cmake python-dev python3-dev
}
setup_ycm_after() {
    if [ "$FORCE" != 'yes' ] && [ "$REINSTALLED_VIM" == 'no' ]; then
        return
    fi
    ( 
        cd $HOME/.vim/bundle/YouCompleteMe
        ./install.py --clang-completer
    )
}
setup_vim_after() {
    cd $HOME/bin
    ln -s $HOME/.vim/bundle/YCM-Generator/config_gen.py . || true
}
setup_packages() {
    _install htop zsh tree clang silversearcher-ag
}   
setup_fzf() {
    if [ "$FORCE" != 'yes' ] && [ -d $HOME/.fzf ]; then
        return
    fi
    _install libncurses5-dev ruby
    # curses is part of ruby for < 2.1.0?
    sudo gem install curses || true
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
    mv $HOME/.fzf/install $HOME/.fzf/install.fzf
    mv $HOME/.fzf/uninstall $HOME/.fzf/uninstall.fzf
    $HOME/.fzf/install.fzf --key-bindings --no-completion --update-rc
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
    setup_vim_after
}

_setup_vim_all() {
    setup_ycm_before
    setup_vim
    setup_ycm_after
    setup_vim_after
}

(
    if [ $# -lt 1 ]; then
        setup_all
    else
        "$@"
    fi
)
