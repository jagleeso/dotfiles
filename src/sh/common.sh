#!/usr/bin/env bash
DOT_HOME="$HOME/clone/dotfiles"
set -e
source "$DOT_HOME/src/sh/exports.sh"

#REMOTE_XEN1_NODE=xen1
#REMOTE_AMD_NODE=amd
#REMOTE_ML_NODE=ml
#REMOTE_CLUSTER1_NODE=cluster1
#REMOTE_LOGAN_NODE=logan

# VERBOSE="-v"
VERBOSE=
TUNNEL_FLAGS="$VERBOSE -f -N"

## Local tunneling ports that have been allocated.
#AMD_GDB_PORT=1235
#AMD_SSH_PORT=8686
#ML_GDB_PORT=1237
#ML_SSH_PORT=8989
#ML_JUPYTER_PORT=5757
#XEN1_GDBGUI_PORT=8888
#XEN1_SSH_PORT=8787
#XEN1_GDB_PORT=1234
#XEN1_GDB_MATHUNITTESTS_PORT=1236
#CLUSTER1_SSH_PORT=8181
#LOGAN_SSH_PORT=8282
#LOGAN_GDB_PORT=1238
#LOGAN_SNAKEVIZ_PORT=6226
#LOGAN_TENSORBOARD_PORT=6116

if [ "$DEBUG" = 'yes' ] && [ "$DEBUG_SHELL" != 'no' ]; then
    set -x
fi

quote_re() {
    sed 's|/|\\/|g'<<<"$1"
}

# kill windows without a title
kwin() {
    wmctrl -l | ruby -ane '
    hex = $F[0];
    name = $F[3..$F.size].join("");
    is_empty = name == "";
    # puts "hex = #{ hex }, name = #{ name }, is_empty = #{ is_empty }";
    if is_empty then
        puts hex
    end
    ' | while read window; do
        wmctrl -i -c $window
    done
}

intrm_is_tunneling_to_dst() {
    local remote_node="$1"
    local remote_intrm_port="$2"
    shift 2
    local intrm_node="$(_get_intrm_node $remote_node)"
    # Make sure this is running:
    # ssh $TUNNEL_FLAGS -L 8787:localhost:22 james@10.70.2.2
    ssh $intrm_node "ps aux | grep -v grep | grep -q 'ssh.*-L.*$remote_intrm_port'"
}

remote_home()
{
    local remote_node="$1"
    shift 1

    local remote_username="$(ssh_config.py --user --host=$remote_node)"
    echo "/home/$remote_username"
}

_get_intrm_node() {
    local remote_node="$1"
    shift
    ssh_config.py --proxy-command --host=$remote_node | \
        perl -lape 's/ssh -q (\w+) nc.*/$1/'
}
# File to output commands to for setting up tunnels elsewhere.
# FAILED_TUNNEL_CMDS=
tunnel_to_intrm() {
    local local_port="$1"
    local remote_intrm_port="$2"
    local remote_dst_port="$3"
    local remote_node="$4"
    shift 4
    # NOTE: this assumes a tunnel is already setup on syslab.
    local remote_username="$(ssh_config.py --user --host=$remote_node)"
    local remote_identity_file="$(ssh_config.py --identity-file --host=$remote_node)"
    local intrm_node="$(_get_intrm_node $remote_node)"
    if ! intrm_is_tunneling_to_dst $remote_node $remote_intrm_port; then
        echo "ERROR: You need to login to $intrm_node and tunnel from $intrm_node to $remote_node:"
        echo "  $ ssh $intrm_node"
        tunnel_cmd="ssh $TUNNEL_FLAGS -L $remote_intrm_port:localhost:$remote_dst_port $remote_username@$remote_node -i $remote_identity_file"
        echo "  $ $tunnel_cmd"
        if [ "$FAILED_TUNNEL_CMDS" != "" ]; then
            echo "$tunnel_cmd" >> "$FAILED_TUNNEL_CMDS"
        fi
        exit 1
    fi
    # Try using autossh locally to keep connection alive.
    autossh $TUNNEL_FLAGS \
        -L $local_port:localhost:$remote_intrm_port $intrm_node
}

RSYNC_DEBUG_FLAGS=
if [ "$DEBUG" = 'yes' ]; then
#    RSYNC_DEBUG_FLAGS="-n"
    true
fi
_rsync() {
    rsync $RSYNC_DEBUG_FLAGS "$@"
}

_rsync_remote_dir() {
    local local_path="$2"
    local remote_node="$2"
    local remote_root="$3"
    local dir="$4"
    shift 4

    mkdir -p $local_path/$dir
    if [ "$RSYNC_DEBUG_FLAGS" = "-n" ]; then
        echo "WARNING: _rsync is disabled" 1>&2
    fi
    _rsync -L -avz $remote_node:$remote_root/$dir/ $local_path/$dir/
}

CN=$HOME/clone/CNTK
_do_sync_cntk_gdb() {
    local remote_node="$1"
    local remote_cntk_root="$2"
    local remote_user="$3"

    shift 3

    local local_sysroot_path=$CN/sysroot/$remote_node
    local local_cntk_path=$local_sysroot_path/$remote_cntk_root

    _rsync_cntk_dir() {
        local dir="$1"
        shift 1

        _rsync_remote_dir $local_cntk_path $remote_node $remote_cntk_root $dir
    }

    # NOTE:
    # Always make sure you go into GDB and type "info sharedlibrary"
    # and sync over all those .so files.
    # For some reason, it appears GDB won't read symbols from your
    # binary even if its missed those.
    _sync_gdb_files_ml() {
        GDB_FILES=( \
            /lib64/ld-linux-x86-64.so.2 \
            /pkgs/cuda-8.0/lib64/libcudart.so.8.0 \
            /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1 \
            /home/$remote_user/clone/RDMA-GPU/install/CNTKCustomMKL/3/x64/parallel/libiomp5.so \
            /lib/x86_64-linux-gnu/libpthread.so.0 \
            /home/$remote_user/clone/CNTK/build/debug/bin/../lib/libCntk.Math-2.1d.so \
            /home/$remote_user/clone/CNTK/build/debug/bin/../lib/libCntk.PerformanceProfiler-2.1d.so \
            /home/$remote_user/clone/CNTK/build/debug/bin/../lib/libmultiverso.so \
            /lib/x86_64-linux-gnu/libdl.so.2 \
            /home/$remote_user/clone/RDMA-GPU/install/lib/libmpi_cxx.so.1 \
            /home/$remote_user/clone/RDMA-GPU/install/lib/libmpi.so.12 \
            /usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
            /lib/x86_64-linux-gnu/libm.so.6 \
            /lib/x86_64-linux-gnu/libgcc_s.so.1 \
            /lib/x86_64-linux-gnu/libc.so.6 \
            /lib/x86_64-linux-gnu/librt.so.1 \
            /pkgs/cuda-8.0/lib64/libcublas.so.8.0 \
            /pkgs/cuda-8.0/lib64/libcurand.so.8.0 \
            /pkgs/cuda-8.0/lib64/libcusparse.so.8.0 \
            /home/$remote_user/clone/cudnn/cuda/lib64/libcudnn.so.5 \
            /home/$remote_user/clone/RDMA-GPU/install/CNTKCustomMKL/3/x64/parallel/libmkl_cntk_p.so \
            /home/$remote_user/clone/RDMA-GPU/install/lib/libopen-pal.so.13 \
            /home/$remote_user/clone/RDMA-GPU/install/lib/libopen-rte.so.12 \
            /usr/lib/x86_64-linux-gnu/libnuma.so.1 \
            /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 \
            /lib/x86_64-linux-gnu/libutil.so.1 \
            /lib/x86_64-linux-gnu/libz.so.1 \
            /usr/lib/x86_64-linux-gnu/libcuda.so.1 \
            /usr/lib/x86_64-linux-gnu/libnvidia-fatbinaryloader.so.375.39 \
            /home/$remote_user/clone/CNTK/build/debug/bin/../lib/Cntk.Deserializers.TextFormat-2.1d.so \
        )

        local files_from="$(mktemp)"
        for f in "${GDB_FILES[@]}"; do
            echo "$f" >> $files_from
        done

        _rsync_files_from $files_from $remote_node $local_sysroot_path
        rm $files_from
    }

    _sync_files() {
        _rsync_cntk_dir build/debug/bin
        _rsync_cntk_dir build/debug/lib
        if [ "$remote_node" = 'ml' ]; then
            _sync_gdb_files_ml
        fi
    }
    _sync_files &
    _kill_remote_gdb $remote_node &
    wait
}
_kill_remote_gdb() {
    local remote_node="$1"
    shift 1
    ssh $remote_node 'bash -c "killall --quiet gdbserver || true"'
}
do_sync_cntk_gdb_xen1() {
    _do_sync_cntk_gdb xen1 $CN james
}
do_sync_cntk_gdb_ml() {
    _do_sync_cntk_gdb ml /home/jgleeson/clone/CNTK jgleeson
}
do_sync_cntk_gdb_logan() {
    _do_sync_cntk_gdb logan /home/james/clone/CNTK james
}

_rsync_files_from() {
    local files_from="$1"
    local remote_node="$2"
    local local_path="$3"
    shift 3
    _rsync -L -avz --files-from=$files_from $remote_node:/ $local_path/
}

RD=$HOME/clone/RDMA-GPU
_do_sync_benchmark_gdb() {
    local remote_node="$1"
    local remote_root="$2"
    shift 2

    local local_sysroot_path=$RD/sysroot/$remote_node
    local local_path=$local_sysroot_path/$remote_root

    _rsync_benchmark_dir() {
        local dir="$1"
        shift 1

        _rsync_remote_dir $local_path $remote_node $remote_root $dir
    }

    # loading symbols from...
#    /home/james/clone/RDMA-GPU/install/bin/gpu_benchmark
#    /lib64/.debug/ld-2.24.so.debug
#    /lib64/.debug/libc-2.24.so.debug
#    /lib64/.debug/libdl-2.24.so.debug
#    /lib64/.debug/libgcc_s-6.4.1-20170727.so.1.debug
#    /lib64/.debug/libm-2.26.so.debug
#    /lib64/.debug/libpthread-2.24.so.debug
#    /lib64/.debug/librt-2.24.so.debug
#    /lib64/.debug/libstdc++.so.6.0.22.debug
#    /lib64/ld-2.24.so.debug
#    /lib64/ld-linux-x86-64.so.2
#    /lib64/libc-2.24.so.debug
#    /lib64/libc.so.6
#    /lib64/libcuda.so.1
#    /lib64/libdl-2.24.so.debug
#    /lib64/libdl.so.2
#    /lib64/libgcc_s-6.4.1-20170727.so.1.debug
#    /lib64/libgcc_s.so.1
#    /lib64/libm-2.24.so.debug
#    /lib64/libm.so.6
#    /lib64/libnvidia-fatbinaryloader.so.367.57
#    /lib64/libpthread-2.24.so.debug
#    /lib64/libpthread.so.0
#    /lib64/librt-2.24.so.debug
#    /lib64/librt.so.1
#    /lib64/libstdc++.so.6
#    /lib64/libstdc++.so.6.0.22.debug
#    /usr/local/cuda/lib64/libcudart.so.8.0

    _sync_ml_files() {
        GDB_FILES=( \
            /lib64/ld-linux-x86-64.so.2 \
            /lib/x86_64-linux-gnu/libpthread.so.0 \
            /lib/x86_64-linux-gnu/libdl.so.2 \
            /lib/x86_64-linux-gnu/librt.so.1 \
            /home/jgleeson/clone/RDMA-GPU/install/lib/libboost_unit_test_framework.so.1.60.0 \
            /usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
            /lib/x86_64-linux-gnu/libm.so.6 \
            /lib/x86_64-linux-gnu/libgcc_s.so.1 \
            /lib/x86_64-linux-gnu/libc.so.6 \
            /usr/lib/x86_64-linux-gnu/libcuda.so.1 \
            /usr/lib/x86_64-linux-gnu/libnvidia-fatbinaryloader.so.375.39 \
            )
        local files_from="$(mktemp)"
        for f in "${GDB_FILES[@]}"; do
            echo "$f" >> $files_from
        done
        _rsync_files_from $files_from $remote_node $local_sysroot_path
        rm $files_from
    }

    # NOTE:
    # Always make sure you go into GDB and type "info sharedlibrary"
    # and sync over all those .so files.
    # For some reason, it appears GDB won't read symbols from your
    # binary even if its missed those.
    _sync_xen1_files() {
        GDB_FILES=( \
            /lib64/libcuda.so.1 \
            /usr/local/cuda/lib64/libcudart.so.8.0 \
            /lib64/libpthread.so.0 \
            /lib64/libdl.so.2 \
            /lib64/librt.so.1 \
            /lib64/libstdc++.so.6 \
            /lib64/libm.so.6 \
            /lib64/libgcc_s.so.1 \
            /lib64/libc.so.6 \
            /lib64/libnvidia-fatbinaryloader.so.367.57 \
            /lib64/ld-linux-x86-64.so.2 \
            )
        local files_from="$(mktemp)"
        for f in "${GDB_FILES[@]}"; do
            echo "$f" >> $files_from
        done
        _rsync_files_from $files_from $remote_node $local_sysroot_path
        rm $files_from
    }

    _sync_files() {
        _rsync_benchmark_dir build
        _rsync_benchmark_dir install/bin
        if [ "$remote_node" = 'ml' ]; then
            _sync_ml_files
        elif [ "$remote_node" = 'xen1' ]; then
            _sync_xen1_files
        fi
    }
    _sync_files &
    _kill_remote_gdb $remote_node &
    wait
}
do_sync_benchmark_gdb_xen1() {
    _do_sync_benchmark_gdb xen1 $RD
}
do_sync_benchmark_gdb_ml() {
    _do_sync_benchmark_gdb ml /home/jgleeson/clone/RDMA-GPU
}

do_sync_benchmark_expr() {
    _rsync() {
        _rsync -avz "$@"
    }
    _rsync xen1:$RD/experiment/out/ $RD/experiment/out/
    _rsync ml:/home/jgleeson/clone/RDMA-GPU/experiment/out/ $RD/experiment/out/
}


sync_cntk_gdb_full() {
    _rsync_from() {
        files_from="$1"
        shift 1
        if [ ! -e "$files_from" ]; then
            return
        fi
        _rsync -L -avz --files-from=$files_from xen1:/ $CN/sysroot/
    }
    _rsync_bin() {
        local dir=/home/james/clone/CNTK/build/release/bin
        _rsync -L -avz xen1:$dir/ $CN/sysroot/$dir/
    }
    _rsync_from /home/james/clone/CNTK/Tutorials/HelloWorld-LogisticRegression/test_gdb_files.txt
    _rsync_from /home/james/clone/CNTK/Tutorials/HelloWorld-LogisticRegression/gdb_files.txt
    _rsync_bin
}

do_cntk_test_log() {
    # latest TestDriver logfile.
    (
    shopt -s globstar
    ls -rt /tmp/cntk-test-*/**/output.txt | tail -n 1
    )
}

is_ubuntu_on_windows() {
    grep -q Microsoft /proc/version
}
WINDOWS_HOME="C:/Users/James"

do_cntk_remote_compile() {
    local remote_node="$1"
    shift 1

    local local_cntk=
    local args=()
    if is_ubuntu_on_windows; then
        local_cntk="$WINDOWS_HOME/clone/CNTK"
        args=("${args[@]}" --wsl-windows-path)
    else
        local_cntk="$HOME/clone/CNTK"
    fi

    filter_out() {
        # Filter out:
        #Warning: No xauth data; using fake authentication data for X11 forwarding.
        #Welcome to Ubuntu 16.04.3 LTS (GNU/Linux 4.10.0-38-generic x86_64)
        #
        #* Documentation:  https://help.ubuntu.com
        #* Management:     https://landscape.canonical.com
        #* Support:        https://ubuntu.com/advantage
        #
        #29 packages can be updated.
        #0 updates are security updates.
        #
        #*** System restart required ***
        grep -v --perl-regexp 'Documentation:.*ubuntu|Management:.*canonical|Support:.*ubuntu|Welcome to Ubuntu|packages can be updated|update are security|System restart required'
    }
    local restart_cmd="true"
    if [ "$RESTART" = 'yes' ]; then
        # Re-start emacs debugger.
        restart_cmd="killall gdb_cntk || true"
    fi
    local build_remote_sh="$(cat <<EOF
set -e
cd ~/clone/CNTK
./make.sh $@
$restart_cmd
EOF
#./make.sh "$@"
)"

    (
    cd $HOME/clone/CNTK
    ( ssh $remote_node 2>&1 ) <<<"$build_remote_sh" | \
        replace_paths.py \
            --local "$local_cntk" \
            --remote "$(remote_home $remote_node)/clone/CNTK" \
            --full-path \
            "${args[@]}" | \
            filter_out
    )
}

_is_mounted() {
    local mount_point="$1"
    shift 1
    cat /proc/mounts | grep -q --fixed-strings "$mount_point"
}
do_kill_gdbserver() {
    local remote_node="$1"
    shift 1
    ssh $remote_node bash <<EOF
    killall gdbserver || true
    sleep 0.5
EOF
}

_set_if_not() {
    local varname="$1"
    local value="$2"
    shift 2
    if [ "$(eval echo \$$varname)" != '' ]; then
        eval $varname=\$value
    fi
}

is_dir_empty() {
    local dirpath="$1"
    shift 1
    if [ ! -e "$dirpath" ] || [ ! -d "$dirpath" ]; then
        echo "ERROR: dirpath=$dirpath must be a dir in is_dir_empty"
        exit 1
    fi
    (
    shopt -s nullglob dotglob     # To include hidden files
    local files=("$dirpath"/*)
    [ "${#files[@]}" -eq 0 ]
    )
}

is_remote_home_mounted() {
    local remote_node="$1"
    shift 1
    df -h | grep "$remote_node:" --quiet
}

is_remote_home_mountpoint() {
    local remote_node="$1"
    shift 1
    df -h | grep "$remote_node:" | perl -lane '{print $F[5]}'
}

mount_remote_home() {
    # Does this:
    #   $ mkdir -p ~/logan
    #   $ sshfs logan: ~/logan

    local remote_node="$1"
    shift 1

    local mount_dir="$HOME/$remote_node"
    mkdir -p "$mount_dir"
    if is_remote_home_mounted; then
        return
    fi
    if ! is_dir_empty "$mount_dir"; then
        echo "ERROR: failed to mount remote home directory $remote_node:~ since local mount directory folder $mount_dir was not an empty dir"
        exit 1
    fi

    sshfs $remote_node: "$mount_dir"
}

if [ "$RUN_COMMON" == "yes" ]; then
    "$@"
fi
