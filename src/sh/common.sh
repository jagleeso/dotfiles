#!/usr/bin/env bash
# laptop -> ____ -> xen1
# INTERMEDIATE_NODE="syslab"
INTERMEDIATE_NODE="apps"

REMOTE_XEN1_NODE=xen1
REMOTE_AMD_NODE=amd
REMOTE_ML_NODE=ml
# VERBOSE="-v"
VERBOSE=
TUNNEL_FLAGS="$VERBOSE -f -N"

# Local tunneling ports that have been allocated.
AMD_GDB_PORT=1235
AMD_SSH_PORT=8686
ML_GDB_PORT=1237
ML_SSH_PORT=8989
ML_JUPYTER_PORT=5757
XEN1_GDBGUI_PORT=8888
XEN1_SSH_PORT=8787
XEN1_GDB_PORT=1234
XEN1_GDB_MATHUNITTESTS_PORT=1236

DOT_HOME="$HOME/clone/dotfiles"

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

tunnel_everything() {
    local local_port="$1"
    local remote_intrm_port="$2"
    local remote_dst_port="$3"
    local remote_dst_ip="$4"
    shift 4
    ssh $TUNNEL_FLAGS \
        -L$local_port:localhost:$remote_intrm_port $INTERMEDIATE_NODE -t ssh $TUNNEL_FLAGS \
        -L$remote_intrm_port:localhost:$remote_dst_port \
        james@$remote_dst_ip
}

intrm_is_tunneling_to_dst() {
    local remote_intrm_port="$1"
    shift 1
    # Make sure this is running:
    # ssh $TUNNEL_FLAGS -L 8787:localhost:22 james@10.70.2.2
    ssh $INTERMEDIATE_NODE "ps aux | grep -v grep | grep -q 'ssh.*-L.*$remote_intrm_port'"
}

tunnel_to_intrm() {
    local local_port="$1"
    local remote_intrm_port="$2"
    local remote_dst_port="$3"
    local remote_node="$4"
    shift 4
    # NOTE: this assumes a tunnel is already setup on syslab.
    local remote_username="$(ssh_config.py --user --host=$remote_node)"
    local remote_identity_file="$(ssh_config.py --identity-file --host=$remote_node)"
    if ! intrm_is_tunneling_to_dst $remote_intrm_port; then
        echo "ERROR: You need to login to $INTERMEDIATE_NODE and tunnel from $INTERMEDIATE_NODE to $remote_node:"
        echo "  $ ssh $INTERMEDIATE_NODE"
        echo "  $ ssh $TUNNEL_FLAGS -L $remote_intrm_port:localhost:$remote_dst_port $remote_username@$remote_node -i $remote_identity_file"
        exit 1
    fi
    # Try using autossh locally to keep connection alive.
    autossh $TUNNEL_FLAGS \
        -L $local_port:localhost:$remote_intrm_port $INTERMEDIATE_NODE
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
    
    shift 2

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
            /home/jgleeson/clone/RDMA-GPU/install/CNTKCustomMKL/3/x64/parallel/libiomp5.so \
            /lib/x86_64-linux-gnu/libpthread.so.0 \
            /home/jgleeson/clone/CNTK/build/debug/bin/../lib/libCntk.Math-2.1d.so \
            /home/jgleeson/clone/CNTK/build/debug/bin/../lib/libCntk.PerformanceProfiler-2.1d.so \
            /home/jgleeson/clone/CNTK/build/debug/bin/../lib/libmultiverso.so \
            /lib/x86_64-linux-gnu/libdl.so.2 \
            /home/jgleeson/clone/RDMA-GPU/install/lib/libmpi_cxx.so.1 \
            /home/jgleeson/clone/RDMA-GPU/install/lib/libmpi.so.12 \
            /usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
            /lib/x86_64-linux-gnu/libm.so.6 \
            /lib/x86_64-linux-gnu/libgcc_s.so.1 \
            /lib/x86_64-linux-gnu/libc.so.6 \
            /lib/x86_64-linux-gnu/librt.so.1 \
            /pkgs/cuda-8.0/lib64/libcublas.so.8.0 \
            /pkgs/cuda-8.0/lib64/libcurand.so.8.0 \
            /pkgs/cuda-8.0/lib64/libcusparse.so.8.0 \
            /home/jgleeson/clone/cudnn/cuda/lib64/libcudnn.so.5 \
            /home/jgleeson/clone/RDMA-GPU/install/CNTKCustomMKL/3/x64/parallel/libmkl_cntk_p.so \
            /home/jgleeson/clone/RDMA-GPU/install/lib/libopen-pal.so.13 \
            /home/jgleeson/clone/RDMA-GPU/install/lib/libopen-rte.so.12 \
            /usr/lib/x86_64-linux-gnu/libnuma.so.1 \
            /usr/lib/x86_64-linux-gnu/libpciaccess.so.0 \
            /lib/x86_64-linux-gnu/libutil.so.1 \
            /lib/x86_64-linux-gnu/libz.so.1 \
            /usr/lib/x86_64-linux-gnu/libcuda.so.1 \
            /usr/lib/x86_64-linux-gnu/libnvidia-fatbinaryloader.so.375.39 \
            /home/jgleeson/clone/CNTK/build/debug/bin/../lib/Cntk.Deserializers.TextFormat-2.1d.so \
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
    _do_sync_cntk_gdb xen1 $CN
}
do_sync_cntk_gdb_ml() {
    _do_sync_cntk_gdb ml /home/jgleeson/clone/CNTK
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

do_cntk_remote_compile() {
    local remote_node="$1"
    shift 1
    echo "HELLO WORLD, CONNECT!"
#    ssh $remote_node <<EOF
#    set -e
#    cd ~/clone/CNTK
#    ./make.sh
#EOF
}

do_kill_gdbserver() {
    local remote_node="$1"
    shift 1
    ssh $remote_node bash <<EOF
    killall gdbserver || true
    sleep 0.5
EOF
}

if [ "$RUN_COMMON" == "yes" ]; then
    "$@"
fi
