#!/bin/bash
#
# [MODE=full|minimal|minimal-no-vim|update]
# [DEBUG=yes] 
# [SKIP_FAILURES=yes] 
# setup.sh
#

set -e
if [ "$DEBUG" = 'yes' ] && [ "$DEBUG_SHELL" = '' ]; then
    DEBUG_SHELL='yes'
fi
if [ "$DEBUG" = 'yes' ] && [ "$DEBUG_SHELL" = 'yes' ]; then
    set -x
fi

if [ "$MODE" = "" ]; then
    MODE='full'
fi
if [ "$SKIP_FAILURES" = "" ]; then
    # If setup_* fails, continue on.
    SKIP_FAILURES='no'
fi

is_ubuntu_on_windows() {
    grep -q Microsoft /proc/version
}
_yes_or_no() {
    if "$@" > /dev/null 2>&1; then
        echo yes
    else
        echo no
    fi
}

HAS_SUDO=""

# vim setup.
SETUP_VIM='yes'
# Anything that needs sudo, like installing packages.
SETUP_SUDO='yes'
# Anything that needs ./configure
SETUP_NEEDS_BUILDING='yes'
# Anything that needs apt, pip, etc
SETUP_NEEDS_INSTALLING='yes'
# If we're running ubuntu on windows, setup stuff..
SETUP_WINDOWS="$(_yes_or_no is_ubuntu_on_windows)"

WINDOWS_DRIVE='c'
# /mnt/c/Users/<username>
WSL_WINDOWS_HOME=
_set_windows_home() {
    if [ ! -d /mnt/$WINDOWS_DRIVE/Users ]; then
        echo "ERROR: couldn't guess WINDOWS_DRIVE (it's not $WINDOWS_DRIVE)"
        exit 1
    fi
    __windows_home_folders() {
        find /mnt/$WINDOWS_DRIVE/Users -mindepth 1 -maxdepth 1 -type d | \
            grep --perl-regexp -v '/(Public|Default)$'
    }
    local num_home_folders=$(__windows_home_folders | wc --lines)
    if [ $num_home_folders -gt 1 ]; then
        echo "ERROR: couldn't guess windows home folders; choices are:"
        __windows_home_folders
        exit 1
    fi
    [ $num_home_folders -eq 1 ]
    WSL_WINDOWS_HOME="$(__windows_home_folders)"
}
if is_ubuntu_on_windows; then
    _set_windows_home
fi
# /home/<username>/windows -> /mnt/c/Users/<username>
WINDOWS_HOME=
if is_ubuntu_on_windows; then
    WINDOWS_HOME=$HOME/windows
fi

_set_if_not() {
    local varname="$1"
    local value="$2"
    shift 2
    if [ "$(eval echo \$$varname)" != '' ]; then
        eval $varname=\$value
    fi
}

#
# Determine what to do based on "$MODE"
#

if [ "$MODE" = 'minimal-no-vim' ] || [ "$MODE" = 'update' ]; then
    _set_if_not SETUP_VIM 'no'
fi
if [ "$MODE" = 'minimal-no-vim' ] || [ "$MODE" = 'update' ]; then
    _set_if_not SETUP_SUDO 'no'
    _set_if_not HAS_SUDO 'no'
fi
if [ "$MODE" != 'minimal' ] || [ "$MODE" = 'minimal-no-vim' ] || [ "$MODE" = 'update' ]; then
    _set_if_not SETUP_NEEDS_BUILDING 'no'
    _set_if_not SETUP_NEEDS_INSTALLING 'no'
fi

echo
echo "> MODE = $MODE"
echo "> SETUP_VIM = $SETUP_VIM"
echo "> SETUP_SUDO = $SETUP_SUDO"
echo "> SETUP_NEEDS_BUILDING = $SETUP_NEEDS_BUILDING"
echo "> SETUP_NEEDS_INSTALLING = $SETUP_NEEDS_INSTALLING"
echo "> SETUP_WINDOWS = $SETUP_WINDOWS"
echo

_has_sudo() {
    if [ "$HAS_SUDO" = '' ]; then
        HAS_SUDO="$(_yes_or_no /usr/bin/sudo -v)"
    fi
    echo $HAS_SUDO
}
_has_exec() {
    _yes_or_no which "$@"
}
_has_lib() {
    local lib="$1"
    shift 1
    on_ld_path() {
        ldconfig -p \
            | grep --quiet "$lib"
    }
    in_local_path() {
        ls $INSTALL_DIR/lib \
            | grep --quiet "$lib"
    }
    __has_lib() {
        on_ld_path || in_local_path
    }
    _yes_or_no __has_lib
}

INSTALL_DIR=$HOME/local
DOT_HOME=$HOME/clone/dotfiles

# Hopefully the most stable one.
VIM_TAG="v8.0.0000"
# VIM_TAG="master"
# VIM_PY2_CONFIG_DIR=/usr/lib64/python2.7/config
# VIM_PY3_CONFIG_DIR=/usr/lib64/python3.5/config

_first_exists() {
    # First argument that exists, otherwise do nothing
    # (doesn't fail).
    local path="$1"
    shift 1
    for path in "$@"; do 
        if [ -e "$path" ]; then
            echo "$path"
            return
        fi
    done
}
_find_python_config_dir() {
    local pymajor_version="$1"
    shift 1
    ( find /usr -type d | \
        grep --perl-regexp "python${pymajor_version}.*/config.*" | \
        perl -lane 'if (/config[^\/]*$/) { print; }' | \
        grep -v dist-packages ) \
        || true
}
# _python_config_dir() {
#     # "$VIM_PY3_CONFIG_DIR"
#     # "$VIM_PY2_CONFIG_DIR"
#     # $VIM_PYTHON_DIR/bin/python3-config
#     # $VIM_PYTHON_DIR/bin/python-config
#     _first_exists \
#         "$(_find_python_config_dir 3)" \
#         "$(_find_python_config_dir 2)"
# }
# PY_CONFIG_DIR=$(_python_config_dir)

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
HAS_PIP="$(_has_exec pip)"

HAS_LIB_EVENT="$(_has_lib libevent.so)"

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
    sudo yum groupinstall -y "$@"
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
    if [ "$HAS_PIP" = 'no' ]; then
        return
    fi
    if [ "$(_has_sudo)" = 'no' ]; then
        pip install "$@"
    else
        sudo pip install "$@"
    fi
}
_ln() {
    local target="$1"
    local link="$2"
    shift 2
    if [ -e "$target" ]; then
        if [ -L "$link" ]; then
            rm "$link"
        fi
        ln -s -T "$target" "$link"
    fi
}
setup_windows_symlinks() {
    # Move ~/clone to windows directory, so we can access it from windows.
    # Still symlink to it from ~/clone though.
    _ln $WSL_WINDOWS_HOME $WINDOWS_HOME
    _move_and_link_home_dir() {
        # (1) Move:    $HOME/$dir -> /mnt/c/Users/<username>
        # (2) Symlink: $HOME/$dir -> /mnt/c/Users/<username>/$dir
        #
        # Some directory inside the $HOME directory
        # (.e.g. $HOME/.ssh)
        local dir="$1"
        shift 1
        if [ ! -L $HOME/$dir ] && [ ! -e $WINDOWS_HOME/$dir ]; then
            mv $HOME/$dir $WINDOWS_HOME
        fi
        _ln $WINDOWS_HOME/$dir $HOME/$dir
    }
    _move_and_link_home_dir clone
    # Doesn't work, permissions issues once on the windows partition.
    # Need to copy .ssh over to linux partition.
#    _move_and_link_home_dir .ssh
}
setup_windows_packages() {
#    _install_apt gnome-terminal
    true
}
setup_windows_bashrc() {
    lines=$(cat <<EOF
if [ -e ~/.bashrc.windows ]; then
    source ~/.bashrc.windows
fi
EOF
)

    append_if_not_exists \
        --in-place ~/.bashrc \
        --pattern 'source ~/.bashrc.windows' \
        "$lines"
}
setup_windows_dotfiles() {
    # Copy over any $DOT_HOME/.* files AS-IS.
    # (since they DON'T work properly on windows as sym-linked files).
    local as_is_files=( \
      .ideavimrc \
    )
    for f in "${as_is_files[@]}"; do
        if [ -e $WINDOWS_HOME/$f ] && [ -L $WINDOWS_HOME/$f ]; then
            # Remove any sym-links if they exist.
            rm $WINDOWS_HOME/$f
        fi
        # Overwrite anything that already exists.
        #
        # WARNING: that means don't make changes to these files on windows.
        cp $DOT_HOME/$f $WINDOWS_HOME/$f
    done
}
setup_tmux() {
    if [ "$FORCE" != 'yes' ] && [ -f $HOME/local/bin/tmux ]; then
        return
    fi

    setup_libevent

    # local commit="$(_git_latest_tag)"
    local commit="2.5"
    local dir=$HOME/clone/tmux
    _clone $dir \
        https://github.com/tmux/tmux.git \
        $commit
    (
    cd $dir
    _configure_make_install
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
}
setup_zsh_syntax_highlighting() {
    if [ "$FORCE" != 'yes' ] && [ -d $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting ]; then
        return
    fi
    local commit="master"
    _clone \
        $HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting \
        https://github.com/zsh-users/zsh-syntax-highlighting.git \
        $commit
}
setup_zsh() {
    setup_oh_my_zsh

    setup_zsh_syntax_highlighting
    _link_files $HOME/.zsh/completion $DOT_HOME/.zsh/completion
    _link_files $HOME/.oh-my-zsh/themes $DOT_HOME/.oh-my-zsh/themes
}
REINSTALLED_VIM=no
VIM_PYTHON_DIR=$HOME/vim-python
setup_vim_python() {
    # TODO: I can't figure out how to do install a "config" directory.
    #
    # Need python-dev to build vim with python support.
    # If we cannot install it with a package manager, 
    # just build python from source just for vim's use.
    if [ "$FORCE" != 'yes' ] &&  \
       [ "$(_python_config_dir)" != '' ] && \
       [ -e "$(_python_config_dir)" ]; then
        return
    fi

    echo "ERROR: not implemented"
    exit 1

    local dir=$HOME/clone/vim-python
    CLONE_TAG_PATTERN="3.6.3"
    _clone $dir \
        https://github.com/python/cpython.git \
        $commit
    (
    INSTALL_DIR="$VIM_PYTHON_DIR"
    cd $dir
    _configure_make_install
    )
}
setup_vim() {
    if [ "$FORCE" != 'yes' ] && [ -f $HOME/local/bin/vim ]; then
        return
    fi

    REINSTALLED_VIM=yes
    mkdir -p $HOME/local
    mkdir -p $HOME/clone
    _clone $HOME/clone/vim \
        https://github.com/vim/vim.git \
        $VIM_TAG

    _install_yum ncurses-lib ncurses-devel || true
    _install_yum libgnome-devel perl-devel python-devel \
        ruby-devel rubygems perl-ExtUtils-Embed
    _install_yum_group "Development Tools"

    _install \
        libncurses5-dev \
        libgnome2-dev libgnomeui-dev \
        libgtk2.0-dev libatk1.0-dev libbonoboui2-dev \
        libcairo2-dev libx11-dev libxpm-dev libxt-dev python-dev \
        python3-dev ruby-dev lua5.1 lua5.1-dev libperl-dev git || true

    HAS_PYTHON3="$(_has_exec python3)"
    # if ! ( _python_config_dir | _fail_if_empty ); then
    PYTHON_OPTS=()
    local py_config_dir=
    local py_header=
    _has_python_header() {
        local pymajor_version="$1"
        shift 1
        ( find /usr/include -type f | \
            grep --perl-regexp "python${pymajor_version}.*/Python.h$" 
        )
    }
    if [ $HAS_PYTHON3 = 'yes' ] && _has_python_header 3 > /dev/null; then
        py_config_dir="$(_find_python_config_dir 3)"
        py_header="$(_has_python_header 3)"
        PYTHON_OPTS=( \
            "--with-python3-config-dir=$py_config_dir" \
            "--enable-python3interp=yes" \
        )
    elif _has_python_header 2 > /dev/null; then
        py_config_dir="$(_find_python_config_dir 2)"
        py_header="$(_has_python_header 2)"
        PYTHON_OPTS=( \
            "--with-python-config-dir=$py_config_dir" \
            "--enable-pythoninterp=yes" \
        )
    fi
    if [ "$py_config_dir" = '' ] || [ "$py_header" = '' ]; then
        echo "ERROR: cannot find python config directory or Python.h; vim need python support (install python-dev?)"
        exit 1
    fi

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
        make distclean
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
        if [ -e $VIM_PYTHON_DIR ]; then
            CONFIG_CFLAGS=( \
                "-I$VIM_PYTHON_DIR/include" \
            )
            CONFIG_LDFLAGS=( \
                "-Wl,-rpath,$VIM_PYTHON_DIR/lib -L$VIM_PYTHON_DIR/lib" \
            )
        fi
        
        CONFIG_FLAGS=( \
            --with-features=huge \
            --enable-multibyte \
            "${PYTHON_OPTS[@]}" \
            --enable-cscope \
            "${EXTRA_OPS[@]}"
        )
        _configure_make_install
    )
}
setup_ycm_before() {
    _install build-essential || true
    _install python-dev python3-dev || true
    _install cmake
    _install_yum python-devel || true
    _install_yum python34-devel || true
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
    local apt_or_yum_packages=( \
        xsel \
        subversion \
        xauth xterm \
        silversearcher-ag \
        htop zsh tree clang xclip ctags cscope \
        autossh \
        python-pip \
        entr \
    )
#        libevent
    local apt_packages=( \
        libevent-dev \
        build-essential autotools-dev autoconf \
        libssl-dev \
    )
    local yum_packages=( \
        epel-release \
        the_silver_searcher \
        util-linux-user \
        libevent-devel libevent \
        libssl-devel \
    )
    _install "${apt_or_yum_packages[@]}"
    _install_apt "${apt_packages[@]}"
    _install_yum "${yum_packages[@]}"
}
setup_pip() {
    local pip_packages=( \
        colorama watchdog \
        paramiko \
        ipython \
        ipdb \
        psutil \
    )
    _install_pip "${pip_packages[@]}"
}
git_latest_tag() {
    # Assuming git tags that look like numbers.
    git tag | sort --human | tail -n 1
}
_fail_if_empty() {
    local script=$(cat <<EOF
from __future__ import print_function
import sys
import re
import os
import argparse

parser = argparse.ArgumentParser("output stdin, and fail if stdin contains nothing")
args = parser.parse_args()

cin = sys.stdin
cout = sys.stdout

saw_line = False
for line in cin:
    saw_line = True
    line = line.rstrip()
    cout.write(line)
    cout.write("\n")
ret_code = 0 if saw_line else 1
sys.exit(ret_code)
EOF
)
    python -c "$script" "$@"
}
_git_latest_tag_like() {
    local pattern="$1"
    shift 1
    (
    # Fail if any process (grep) fails.
    set -o pipefail
    git tag | \
        grep --perl-regexp "$pattern" | \
        tail -n 1
    )
}
CLONE_TAG_PATTERN=
_clone() {
    local path="$1"
    local repo="$2"
    shift 2
    local commit=
    if [ $# -ge 1 ]; then
        commit="$1"
        shift 1
    elif [ "$CLONE_TAG_PATTERN" != '' ]; then
        commit="$(
            cd $dir
            _git_latest_tag_like "$CLONE_TAG_PATTERN"
        )"
    fi
    if [ ! -e "$path" ]; then
        git clone --recursive $repo $path
    fi
    (
    cd $path
    git checkout $commit
    git submodule update --init
    )
    CLONE_TAG_PATTERN=
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
CONFIG_LDFLAGS=(-Wl,-rpath,$INSTALL_DIR/lib -L$INSTALL_DIR/lib)
CONFIG_CFLAGS=(-I$INSTALL_DIR/include)
CONFIG_CXXFLAGS=(-I$INSTALL_DIR/include)
_maybe() {
    set +x
    # Maybe run the command.
    # If DEBUG, just print it, else run it.
    if _DEBUG; then
        echo "$ $@"
        if _DEBUG_SHELL; then
            set -x
        fi
        return
    fi
    if _DEBUG_SHELL; then
        set -x
    fi
    "$@"
}
_configure() {
    if [ ! -e ./configure ]; then
        if [ -e ./autogen.sh ]; then
            ./autogen.sh
        elif [ -e ./configure.ac ]; then
            autoreconf
        fi
    fi
    _maybe ./configure "${CONFIG_FLAGS[@]}" --prefix=$INSTALL_DIR
}
_configure_make_install()
{
    (
    export LDFLAGS="$LDFLAGS ${CONFIG_LDFLAGS[@]}"
    export CXXFLAGS="$CXXFLAGS ${CONFIG_CXXFLAGS[@]}"
    export CFLAGS="$CFLAGS ${CONFIG_CFLAGS[@]}"
    _configure
    _maybe make -j$NCPU
    _maybe make install
    )
    CONFIG_FLAGS=()
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
    _do _link_files $HOME/bin $DOT_HOME/bin
    _do _link_files $HOME/bin $DOT_HOME/src/python/scripts
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
setup_libevent() {
    if [ "$FORCE" != 'yes' ] && [ $HAS_LIB_EVENT = 'yes' ]; then
        return
    fi
    local commit="master"
    local dir=$HOME/clone/libevent
    _clone $dir \
        https://github.com/libevent/libevent.git \
        $commit
    (
    cd $dir
    _configure_make_install
    )
}
setup_fonts() {
    _ln $HOME/.fonts $DOT_HOME/.fonts
    fc-cache
}
setup_all() {
    if [ "$SETUP_WINDOWS" = 'yes' ]; then
        do_setup setup_windows_symlinks
        do_setup setup_windows_packages
        do_setup setup_windows_bashrc
        do_setup setup_windows_dotfiles
    fi
    do_setup setup_tree
    do_setup setup_dot_common
    do_setup setup_packages
    if [ "$SETUP_NEEDS_INSTALLING" = 'yes' ]; then
        do_setup setup_pip
    fi
    do_setup setup_bin
    do_setup setup_fonts
    do_setup setup_zsh
    do_setup setup_ipython
    do_setup setup_fzf
    do_setup setup_dotfiles
    do_setup setup_gdb
    if [ "$SETUP_VIM" = 'yes' ]; then
        do_setup setup_ycm_before
        # do_setup setup_vim_python
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

decho() {
    set +x
    if ! _DEBUG; then
        return
    fi
    echo "DEBUG :: $@"
    if _DEBUG_SHELL; then
        set -x
    fi
}
_DEBUG() {
    [ "$DEBUG" = 'yes' ]
}
_DEBUG_SHELL() {
    [ "$DEBUG_SHELL" = 'yes' ]
}
_do() {
    if _DEBUG; then
        echo "$@"
        "$@"
    else
        "$@"
    fi
}
append_if_not_exists() {
    local script=$(cat <<EOF
import sys
import re
import os
import argparse

parser = argparse.ArgumentParser("append a line if it doesn't exist")
parser.add_argument("lines", nargs="+")
parser.add_argument("--pattern", required=True,
    help="if no line matches --pattern, append lines to the bottom of stdin")
parser.add_argument("--in-place",
    help="modify file in-place")
args = parser.parse_args()

in_stream = sys.stdin
out_stream = sys.stdout
lines = []
if args.in_place is not None:
    if not os.path.exists(args.in_place):
        parser.error("File --in-place = \"{0}\" doesn't exist".format(args.in_place))
    in_stream = open(args.in_place)
lines = [line.rstrip() for line in in_stream]
if args.in_place is not None:
    in_stream.close()
    out_stream = open(args.in_place, 'w')

matches_pattern = any(re.search(args.pattern, l) for l in lines)

if not matches_pattern:
    lines.extend(args.lines)

for l in lines:
    out_stream.write(l)
    out_stream.write("\n")
if args.in_place is not None:
    out_stream.close()
EOF
)
    python -c "$script" "$@"
}

(
    if [ $# -lt 1 ]; then
        setup_all
    else
        "$@"
    fi
)
