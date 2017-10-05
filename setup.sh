#!/bin/bash
#
# [MODE=full|minimal|minimal-no-vim|update]
# [DEBUG=yes] 
# [SKIP_FAILURES=yes] 
# setup.sh
#

set -e
if [ "$DEBUG" = 'yes' ]; then
    set -x
fi

if [ "$MODE" = "" ]; then
    MODE='full'
fi
if [ "$SKIP_FAILURES" = "" ]; then
    # If setup_* fails, continue on.
    SKIP_FAILURES='no'
fi

HAS_SUDO=""

# vim setup.
SETUP_VIM='yes'
# Anything that needs sudo, like installing packages.
SETUP_SUDO='yes'
# Anything that needs ./configure
SETUP_NEEDS_BUILDING='yes'

#
# Determine what to do based on "$MODE"
#

if [ "$MODE" = 'minimal-no-vim' ] || [ "$MODE" = 'update' ]; then
    SETUP_VIM='no'
fi
if [ "$MODE" = 'minimal-no-vim' ] || [ "$MODE" = 'update' ]; then
    SETUP_SUDO='no'
    HAS_SUDO='no'
fi
if [ "$MODE" != 'minimal' ] || [ "$MODE" = 'minimal-no-vim' ] || [ "$MODE" = 'update' ]; then
    SETUP_NEEDS_BUILDING='no'
fi

echo
echo "> MODE = $MODE"
echo "> SETUP_VIM = $SETUP_VIM"
echo "> SETUP_SUDO = $SETUP_SUDO"
echo "> SETUP_NEEDS_BUILDING = $SETUP_NEEDS_BUILDING"
echo

_yes_or_no() {
    if "$@" > /dev/null 2>&1; then
        echo yes
    else
        echo no
    fi
}
_has_sudo() {
    if [ "$HAS_SUDO" = '' ]; then
        HAS_SUDO="$(_yes_or_no /usr/bin/sudo -v)"
    fi
    echo $HAS_SUDO
}
_has_exec() {
    _yes_or_no which "$@"
}

INSTALL_DIR=$HOME/local
DOT_HOME=$HOME/clone/dotfiles

# Hopefully the most stable one.
VIM_TAG="v8.0.0000"
# VIM_TAG="master"
VIM_PY2_CONFIG_DIR=/usr/lib64/python2.7/config
VIM_PY3_CONFIG_DIR=/usr/lib64/python3.5/config

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

_sudo() {
    if [ "$(_has_sudo)" = 'no' ]; then
        return
    fi
    sudo "$@"
}
_install() {
    if [ "$(_has_sudo)" = 'no' ]; then
        return
    fi
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
    if [ "$(_has_sudo)" = 'no' ]; then
        return
    fi
    if [ "$HAS_YUM" = 'no' ]; then
        return
    fi
    sudo yum group install -y "$@"
}
_install_yum() {
    if [ "$(_has_sudo)" = 'no' ]; then
        return
    fi
    if [ "$HAS_YUM" = 'no' ]; then
        return
    fi
    sudo yum install -y "$@"
}
_install_apt() {
    if [ "$(_has_sudo)" = 'no' ]; then
        return
    fi
    if [ "$HAS_APT_GET" = 'no' ]; then
        return
    fi
    sudo apt-get install -y "$@"
}
_install_pip() {
    if [ "$(_has_sudo)" = 'no' ]; then
        pip install "$@"
    else
        sudo pip install "$@"
    fi
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
bkup() {
	local file="$1"
	shift 1
	if [ -e "$file" ]; then
		local new_f="$file.bkup"
		mv -n $file $new_f
	fi
}
setup_dotfiles() {
    (
    cd $HOME
    for f in $DOT_HOME/.*; do
        if [ -f $f ]; then
	    local new_f="$(basename $f)"
	    if [ -e "$new_f" ]; then
                bkup $new_f || true
	    fi
            (
                ln -s -T $f $new_f 2>&1 | grep -v 'File exists'
            ) || true
        fi
    done
    )
    # reload dotfiles
    # if [[ $SHELL =~ zsh ]]; then
    #    source $HOME/.zshrc
    # fi 
}
setup_oh_my_zsh() {
    if [ "$FORCE" != 'yes' ] && [ -d $HOME/.oh-my-zsh ]; then
        return
    fi
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
    cp -r $DOT_HOME/.oh-my-zsh/* $HOME/.oh-my-zsh
    if [ -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
        return
    fi
    git clone \
        https://www.github.com/zsh-users/zsh-syntax-highlighting.git \
        $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
}
setup_zsh() {
    setup_oh_my_zsh

    _link_files $HOME/.zsh/completion $DOT_HOME/.zsh/completion
    _link_files $HOME/.oh-my-zsh/themes $DOT_HOME/.oh-my-zsh/themes
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

    _install_yum ncurses-devel || true
    _install libncurses5-dev || true
    _install \
        libgnome2-dev libgnomeui-dev \
        libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
        libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
        python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git || true

    HAS_PYTHON3="$(_has_exec python3)"
    if [ $HAS_PYTHON3 = 'yes' ]; then
        PYTHON_OPTS="--enable-python3interp=yes"
    else
        PYTHON_OPTS="--enable-pythoninterp=yes"
    fi

    _install_yum_group "Development Tools"
    _install_yum ncurses-lib ncurses-devel || true
    _install_yum libgnome-devel perl-devel python-devel ruby-devel rubygems perl-ExtUtils-Embed

    EXTRA_OPS=()
    if [ "$HAS_YUM" != 'yes' ]; then
        EXTRA_OPS=( \
            --enable-gui=gtk2 \
            --enable-perlinterp=yes \
            --enable-luainterp=yes \
            --enable-rubyinterp=yes \
            "${EXTRA_OPS[@]}")
    fi

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
        # CFLAGS="-fPIC -O -D_FORTIFY_SOURCE=0" 
        # --prefix=$HOME/local
        # --with-tlib=ncurses
        ./configure --with-features=huge \
	    --prefix=$HOME/local \
            --enable-multibyte \
            --with-python-config-dir=$VIM_PY2_CONFIG_DIR \
            "$PYTHON_OPTS" \
            --with-python3-config-dir=$VIM_PY3_CONFIG_DIR \
            --enable-cscope \
            "${EXTRA_OPS[@]}"
        make -j$NCPU install

    )
}
setup_ycm_before() {
    _install build-essential || true
    _install python-dev python3-dev || true
    _install cmake
    _install_yum python-devel || true
    _install_yum python3-devel || true
    _install_yum_group "Development Tools" "Development Libraries"
}
setup_ycm_after() {
    if [ "$FORCE" != 'yes' ] && [ "$REINSTALLED_VIM" == 'no' ]; then
        return
    fi
    ( 
        cd $HOME/.vim/bundle/YouCompleteMe
        ./install.py --clang-completer
    )
    ln -s $HOME/.vim/bundle/YCM-Generator/config_gen.py . || true
}
setup_vim_after() {
    mkdir -p $HOME/bin
    cd $HOME/bin

    if [ ! -d "$HOME/.vim/bundle/Vundle.vim" ]; then
        git clone https://github.com/VundleVim/Vundle.vim.git $HOME/.vim/bundle/Vundle.vim
    fi

    $HOME/local/bin/vim -c PluginInstall -c PluginUpdate -c quit -c quit
}
setup_packages() {
    _install xauth xterm || true
    _install silversearcher-ag || true
    _install htop zsh tree clang xclip ctags cscope
    _install_yum epel-release || true
    _install_yum the_silver_searcher
    _install_yum util-linux-user || true
    _install_yum libevent-devel libevent
    _install_apt libevent-dev
    _install_apt libevent || true
    _install_apt build-essential autotools-dev autoconf
    _install autossh || true
    _install_pip colorama watchdog
    _install entr || true
}   
_clone() {
    local path="$1"
    local repo="$2"
    local commit="$3"
    if [ ! -e "$path" ]; then
        (
        git clone --recursive $repo $path
        )
    fi
    (
    cd $path
    git checkout $commit
    git submodule update --init
    )
}
setup_ag() {
    if [ "$FORCE" != 'yes' ] && [ -e /usr/bin/ag ]; then
        return
    fi
    local commit="master"
    _clone $HOME/clone/the_silver_searcher \
        https://github.com/ggreer/the_silver_searcher.git \
        $commit
    cd $HOME/clone/the_silver_searcher
    _configure_make_install
}
setup_autossh() {
    if [ "$FORCE" != 'yes' ] && which autossh > /dev/null >&2; then
        return
    fi
    _wget_tar http://www.harding.motd.ca/autossh/autossh-1.4e.tgz
    local out=$WGET_OUTPUT_DIR
    (
    cd $out
    _configure_make_install
    )
}
setup_fzf() {
    if [ "$FORCE" != 'yes' ] && [ -d $HOME/.fzf ]; then
        return
    fi
    _install libncurses5-dev || true
    _install_yum ncurses-devel || true
    _install ruby
    # curses is part of ruby for < 2.1.0?
    _sudo gem install curses || true
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
    mv $HOME/.fzf/install $HOME/.fzf/install.fzf
    mv $HOME/.fzf/uninstall $HOME/.fzf/uninstall.fzf
    $HOME/.fzf/install.fzf --key-bindings --no-completion --update-rc
    (
        cd $HOME/.fzf
	# No longer applies.
        # git apply $DOT_HOME/patches/fzf.patch
    )
}
_wget() {
    local url="$1"
    local base="$(basename "$url")"
    if [ ! -e "$base" ]; then
        wget "$url"
    fi
}
WGET_OUTPUT_DIR=
_wget_tar() {
    local url="$1"
    shift 1

    local path="$HOME/clone/$(basename $url)"
    if [ ! -e "$path" ]; then
        wget "$url" -O "$path"
    fi
    local first_dir=$(tar tf $path | perl -lape 's/(^[^\/]+)(\/.*)?/$1/' | sort --unique | head -n 1)
    WGET_OUTPUT_DIR="$(dirname $path)/$first_dir" 
    if [ ! -e $WGET_OUTPUT_DIR ]; then
        (
        cd $HOME/clone
        tar xf "$path"
        )
    fi
}
CONFIG_FLAGS=()
_configure() {
    if [ ! -e ./configure ]; then
        if [ -e ./autogen.sh ]; then
            ./autogen.sh
        elif [ -e ./configure.ac ]; then
            autoreconf
        fi
    fi
    ./configure "${CONFIG_FLAGS[@]}" --prefix=$INSTALL_DIR
}
_configure_make_install()
{
    _configure
    CONFIG_FLAGS=()
    make -j$NCPU
    make install
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
    ./configure \
        --prefix=$HOME/local \
        --with-xpm=no \
        --with-jpeg=no \
        --with-gif=no \
        --with-tiff=no \
        --with-png=no \

    make -j$NCPU
    make install
}
setup_spacemacs() {
    if [ "$FORCE" != 'yes' ] && [ -e ~/.emacs.d/spacemacs.mk ]; then
        return
    fi
    git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
}
setup_tree() {
    mkdir -p $HOME/bin \
        $INSTALL_DIR \

}
LINK_FILES_IGNORE_RE='\.(pyc)$'
_link_files() {
    local to_dir="$1"
    local from_dir="$2"
    shift 2

    mkdir -p $to_dir
    for f in $from_dir/*; do
        if grep --perl-regexp --quiet "$LINK_FILES_IGNORE_RE" <<<"$(basename $f)"; then
            continue
        fi
        if [[ "$(basename $f)" =~ ".(pyc)$" ]]; then
            continue
        fi
        if [ ! -f $f ]; then
            continue
        fi
        link_file=$to_dir/$(basename $f)
        if [ -e $link_file ] && [ ! -L $link_file ]; then
            echo "WARNING: non-symbolic link exists @ $link_file; skipping"
            continue
        fi
        ln -f -s -T $f $link_file
    done
}
setup_bin() {
    _link_files $HOME/bin $DOT_HOME/bin
    _link_files $HOME/bin $DOT_HOME/src/python/scripts
}
do_setup() {
    local setup_func="$1"
    shift 1

    if ! $setup_func "$@"; then
        local ret="$?"
        echo "ERROR: $setup_func failed with $ret" >&2
        if [ "$SKIP_FAILURES" = 'no' ]; then
            exit $ret
        fi
    fi
}
setup_dot_common() {
    ln -s -f -T $DOT_HOME/src/sh/common.sh $HOME/.dot_common.sh
}

setup_ipython() {
    _link_files $HOME/.ipython/profile_default/startup $DOT_HOME/.ipython/profile_default/startup
}
GDB_PRETTY_PRINTERS=$HOME/clone/gdb_printers__python
setup_gdb() {
    if [ "$FORCE" != 'yes' ] && [ -e $GDB_PRETTY_PRINTERS ]; then
        return
    fi
    svn co -r r250458 svn://gcc.gnu.org/svn/gcc/trunk/libstdc++-v3/python $GDB_PRETTY_PRINTERS
}
setup_entr() {
    if [ "$FORCE" != 'yes' ] && [ "$(_has_exec entr)" = 'yes' ]; then
        return
    fi
    local commit="master"
    _clone $HOME/clone/entr \
        https://github.com/clibs/entr.git \
        $commit
    cd $HOME/clone/entr
    (
    # Custom configure script, uses environment variables.
    export PREFIX=$INSTALL_DIR
    ./configure 
    make -j$NCPU
    make install
    )
}
setup_xclip() {
    if [ "$FORCE" != 'yes' ] && [ "$(_has_exec xclip)" = 'yes' ]; then
        return
    fi
    local commit="master"
    local srcdir=$HOME/clone/xclip
    _clone $srcdir \
        https://github.com/astrand/xclip.git \
        $commit
    cd $srcdir
    _configure_make_install
}
setup_all() {
    do_setup setup_tree
    do_setup setup_dot_common
    do_setup setup_packages
    do_setup setup_bin
    do_setup setup_zsh
    do_setup setup_ipython
    do_setup setup_fzf
    do_setup setup_dotfiles
    do_setup setup_gdb
    if [ "$SETUP_VIM" = 'yes' ]; then
        do_setup setup_ycm_before
        do_setup setup_vim
        do_setup setup_vim_after
        do_setup setup_ycm_after
    fi
    if [ "$SETUP_NEEDS_BUILDING" = 'yes' ]; then
        do_setup setup_tmux
        do_setup setup_emacs
        do_setup setup_spacemacs
        do_setup setup_autossh
        do_setup setup_ag
        do_setup setup_entr
        do_setup setup_xclip
    fi
}

_setup_emacs_all() {
    do_setup setup_emacs
    do_setup setup_spacemacs
}

_setup_vim_all() {
    do_setup setup_ycm_before
    do_setup setup_vim
    do_setup setup_ycm_after
    do_setup setup_vim_after
}

(
    if [ $# -lt 1 ]; then
        setup_all
    else
        "$@"
    fi
)
