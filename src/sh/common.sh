#!/usr/bin/env bash
# laptop -> ____ -> xen1
# INTERMEDIATE_NODE="syslab"
INTERMEDIATE_NODE="apps"

REMOTE_XEN1_IP=10.70.2.2
REMOTE_AMD_IP=165.204.53.15
# VERBOSE="-v"
VERBOSE=
TUNNEL_FLAGS="$VERBOSE -f -N"

if [ "$DEBUG" = 'yes' ]; then
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
    local remote_dst_ip="$4"
    shift 4
    # NOTE: this assumes a tunnel is already setup on syslab.
    if ! intrm_is_tunneling_to_dst $remote_intrm_port; then
        echo "ERROR: You need to login to $INTERMEDIATE_NODE and tunnel from $INTERMEDIATE_NODE to xen1:"
        echo "  $ ssh $INTERMEDIATE_NODE"
        echo "  $ ssh $TUNNEL_FLAGS -L $remote_intrm_port:localhost:$remote_dst_port james@$remote_dst_ip"
        exit 1
    fi
    # Try using autossh locally to keep connection alive.
    autossh $TUNNEL_FLAGS \
        -L $local_port:localhost:$remote_intrm_port $INTERMEDIATE_NODE
}

CN=$HOME/clone/CNTK
do_sync_cntk_gdb() {
    _rsync_cntk_dir() {
        local dir="$1"
        shift 1
        mkdir -p $CN/sysroot/$dir/
        rsync -L -avz xen1:$CN/$dir/ $CN/sysroot/$CN/$dir/
    }
    _sync_files() {
        _rsync_cntk_dir build/release/bin
        _rsync_cntk_dir build/release/lib
    }
    _sync_files &
    ssh xen1 'bash -c "killall --quiet gdbserver || true"' &
    wait
}

RD=$HOME/clone/RDMA-GPU
do_sync_benchmark_gdb() {
    _rsync_dir() {
        local dir="$1"
        shift 1
        mkdir -p $RD/sysroot/$RD/$dir/
        rsync -L -avz xen1:$RD/$dir/ $RD/sysroot/$RD/$dir/
    }
    _rsync_files_from() {
        local files_from="$1"
        shift 1
        rsync -L -avz --files-from=$files_from xen1:/ $RD/sysroot/
    }

    _sync_files() {
        local files_from="$1"
        shift 1
        _rsync_dir build
        _rsync_dir install/bin
        _rsync_files_from "$files_from"
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

    # NOTE:
    # Always make sure you go into GDB and type "info sharedlibrary"
    # and sync over all those .so files.
    # For some reason, it appears GDB won't read symbols from your
    # binary even if its missed those.
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

    _sync_files "$files_from" &
    ssh xen1 'bash -c "killall --quiet gdbserver || true"' &
    wait
    rm $files_from
}

sync_cntk_gdb_full() {
    _rsync_from() {
        files_from="$1"
        shift 1
        if [ ! -e "$files_from" ]; then
            return
        fi
        rsync -L -avz --files-from=$files_from xen1:/ $CN/sysroot/  
    }
    _rsync_bin() {
        local dir=/home/james/clone/CNTK/build/release/bin
        rsync -L -avz xen1:$dir/ $CN/sysroot/$dir/  
    }
    _rsync_from /home/james/clone/CNTK/Tutorials/HelloWorld-LogisticRegression/test_gdb_files.txt
    _rsync_from /home/james/clone/CNTK/Tutorials/HelloWorld-LogisticRegression/gdb_files.txt
    _rsync_bin
}

if [ "$RUN_COMMON" == "yes" ]; then
    "$@"
fi
