#!/bin/bash
set -e
if [ "$DEBUG" = 'yes' ]; then
    set -x
fi

_yes_or_no() {
    if "$@" > /dev/null 2>&1; then
        echo yes
    else 
        echo no
    fi
}
_has_exec() {
    _yes_or_no which "$@"
}

# Hopefully the most stable one.
VIM_TAG="v8.0.0000"
VIM_PY2_CONFIG_DIR=/usr/lib/python2.7/config
VIM_PY3_CONFIG_DIR=/usr/lib/python3.5/config

# Force re-running setup
if [ "$FORCE" = "" ]; then
    FORCE=no
fi
# Skip installing packages if we're running without apt-get.
if [ "$SKIP_PACKAGES" = "" ]; then
    SKIP_PACKAGES=no
fi
HAS_APT_GET="$(_has_exec apt-get)"
HAS_YUM="$(_has_exec yum)"

NCPU=$(grep -c ^processor /proc/cpuinfo)

_install() {
    if [ "$HAS_APT_GET" = 'yes' ]; then
        sudo apt-get install -y "$@"
    elif [ "$HAS_YUM" = 'yes' ]; then
        sudo yum install -y "$@"
    elif [ "$SKIP_PACKAGES" = 'yes' ]; then
        true
    else
        echo "ERROR: Couldn't find apt-get when trying to install packages: $@"
        echo "  Consider installing packages manually, then try re-running with SKIP_PACKAGES=yes"
        exit 1
    fi
}

_install_yum_group() {
    if [ "$HAS_YUM" = 'no' ]; then
        return
    fi
    sudo yum group install -y "$@"
}
_install_yum() {
    if [ "$HAS_YUM" = 'no' ]; then
        return
    fi
    sudo yum install -y "$@"
}
_install_apt() {
    if [ "$HAS_APT_GET" = 'no' ]; then
        return
    fi
    sudo apt-get install -y "$@"
}

setup_tmux() {
    if [ "$FORCE" != 'yes' ] && [ -f $HOME/local/bin/tmux ]; then
        return
    fi
    mkdir -p $HOME/local
    mkdir -p $HOME/clone
    if [ ! -d $HOME/clone/tmux ]; then
        (
            cd $HOME/clone
            git clone https://github.com/tmux/tmux.git
            cd $HOME/clone/tmux
        )
    else
        (
            cd $HOME/clone/tmux
            # make clean
            git fetch
        )
    fi
    ( 
        cd $HOME/clone/tmux
        git checkout master
        ./autogen.sh
        ./configure --prefix=$HOME/local
        make -j$NCPU
        make install
    )
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
    # if [[ $SHELL =~ zsh ]]; then
    #    source $HOME/.zshrc
    # fi 
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
        https://www.github.com/zsh-users/zsh-syntax-highlighting.git \
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
            cd $HOME/clone/vim
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

    HAS_PYTHON3="$(_has_exec python3)"
    if [ $HAS_PYTHON3 = 'yes' ]; then
        PYTHON_OPTS="--enable-python3interp=yes"
    else
        PYTHON_OPTS="--enable-pythoninterp=yes"
    fi

    _install_yum_group "Development Tools"
    _install_yum ncurses-lib libgnome-devel ncurses-devel perl-devel python-devel ruby-devel rubygems perl-ExtUtils-Embed

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
            "$PYTHON_OPTS" \
            --with-python3-config-dir=$VIM_PY3_CONFIG_DIR \
            --enable-perlinterp=yes \
            --enable-luainterp=yes \
            --enable-gui=gtk2 \
            --enable-cscope \
            --prefix=$HOME/local
        make -j$NCPU install

        if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
            git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
        fi

        $HOME/local/bin/vim -c PluginInstall -c PluginUpdate -c quit -c quit

    )
}
setup_ycm_before() {
    _install build-essential cmake python-dev python3-dev
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
    mkdir -p $HOME/bin
    cd $HOME/bin
    ln -s $HOME/.vim/bundle/YCM-Generator/config_gen.py . || true
}
setup_packages() {
    _install htop zsh tree clang silversearcher-ag xclip
    _install_yum epel-release
    _install_yum the_silver_searcher
    _install_yum libevent-devel libevent
    _install_apt libevent libevent-dev
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
_wget() {
    local url="$1"
    local base="$(basename "$url")"
    if [ ! -e "$base" ]; then
        wget "$url"
    fi
}
setup_emacs() {
    if [ "$FORCE" != 'yes' ] && [ -e $HOME/local/bin/emacs ]; then
        return
    fi
    cd $HOME/clone
    if [ ! -f emacs-25.2.tar.xz ]; then
        _wget ftp://ftp.gnu.org/pub/gnu/emacs/emacs-25.2.tar.xz
        tar xf emacs-25.2.tar.xz
    fi
    cd emacs-25.2
    ./autogen.sh
    ./configure --prefix=$HOME/local  --with-xpm=no --with-jpeg=no --with-gif=no --with-tiff=no
    make -j$NCPU
    make install
}
setup_spacemacs() {
    if [ "$FORCE" != 'yes' ] && [ -e ~/.emacs.d ]; then
        return
    fi
    git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
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
    setup_tmux
    setup_emacs
    setup_spacemacs
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
