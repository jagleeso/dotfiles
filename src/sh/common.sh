#!/usr/bin/env bash
DOT_HOME="$HOME/clone/dotfiles"
set -e
source "$DOT_HOME/src/sh/exports.sh"

COL_BLACK='\033[0;30m'
COL_RED='\033[0;31m'
COL_GREEN='\033[0;32m'
COL_BROWN_ORANGE='\033[0;33m'
COL_BLUE='\033[0;34m'
COL_PURPLE='\033[0;35m'
COL_CYAN='\033[0;36m'
COL_LIGHT_GRAY='\033[0;37m'
COL_DARK_GRAY='\033[1;30m'
COL_LIGHT_RED='\033[1;31m'
COL_LIGHT_GREEN='\033[1;32m'
COL_YELLOW='\033[1;33m'
COL_LIGHT_BLUE='\033[1;34m'
COL_LIGHT_PURPLE='\033[1;35m'
COL_LIGHT_CYAN='\033[1;36m'
COL_WHITE='\033[1;37m'

#REMOTE_XEN1_NODE=xen1
#REMOTE_AMD_NODE=amd
#REMOTE_ML_NODE=ml
#REMOTE_CLUSTER1_NODE=cluster1
#REMOTE_LOGAN_NODE=logan

# VERBOSE="-v"
VERBOSE=
TUNNEL_FLAGS="$VERBOSE -f -N"


ONE_OF_EXACT=no
_one_of() {
    local x="$1"
    shift 1

    match() {
        local y="$1"
        shift 1
        if [ "$ONE_OF_EXACT" = 'yes' ]; then
            [ "$y" = "$x" ]
        else
            echo "$x" | grep --quiet --perl-regexp "$y"
        fi
    }

    for y in "$@"; do
        if match "$y"; then
            return 0
        fi
    done
    return 1
}

_yes_or_no() {
#    if "$@"; then
    if "$@" > /dev/null 2>&1; then
        echo yes
    else
        echo no
    fi
}
_ssid() {
    iwgetid -r
}
_is_wifi_lowbandwidth() {
    local ssid="$(_ssid)"
    _one_of "$ssid" "${WIFI_LOW_BANDWIDTH_SSIDS[@]}"
}
IS_WIFI_LOW_BANDWIDTH="$(_yes_or_no _is_wifi_lowbandwidth)"

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

tunnel_direct() {
    local local_port="$1"
#    local remote_intrm_port="$2"
    local remote_dst_port="$2"
    local remote_node="$3"
    shift 3
    # NOTE: this assumes a tunnel is already setup on syslab.
    local remote_username="$(ssh_config.py --user --host=$remote_node)"
    local remote_identity_file="$(ssh_config.py --identity-file --host=$remote_node)"
    # Try using autossh locally to keep connection alive.
#    autossh $TUNNEL_FLAGS \ -L $local_port:localhost:$remote_intrm_port $intrm_node
    autossh $TUNNEL_FLAGS -L $local_port:localhost:$remote_dst_port $remote_username@$remote_node -i $remote_identity_file
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

## info sharedlibrary:
#/lib/x86_64-linux-gnu/libpthread.so.0
#/lib/x86_64-linux-gnu/libc.so.6
#/lib/x86_64-linux-gnu/libdl.so.2
#/lib/x86_64-linux-gnu/libutil.so.1
#/lib/x86_64-linux-gnu/libexpat.so.1
#/lib/x86_64-linux-gnu/libz.so.1
#/lib/x86_64-linux-gnu/libm.so.6
#/lib64/ld-linux-x86-64.so.2
#/usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so
#/usr/lib/python3.5/lib-dynload/_opcode.cpython-35m-x86_64-linux-gnu.so
#/usr/local/lib/python3.5/dist-packages/numpy/core/multiarray.cpython-35m-x86_64-linux-gnu.so
#/usr/local/lib/python3.5/dist-packages/numpy/core/../.libs/libopenblasp-r0-39a31c03.2.18.so
#/usr/local/lib/python3.5/dist-packages/numpy/core/../.libs/libgfortran-ed201abd.so.3.0.0
#/usr/local/lib/python3.5/dist-packages/numpy/core/umath.cpython-35m-x86_64-linux-gnu.so
#/usr/lib/python3.5/lib-dynload/_bz2.cpython-35m-x86_64-linux-gnu.so
#/lib/x86_64-linux-gnu/libbz2.so.1.0
#/usr/lib/python3.5/lib-dynload/_lzma.cpython-35m-x86_64-linux-gnu.so
#/lib/x86_64-linux-gnu/liblzma.so.5
#/usr/lib/python3.5/lib-dynload/_hashlib.cpython-35m-x86_64-linux-gnu.so
#/lib/x86_64-linux-gnu/libcrypto.so.1.0.0
#/usr/local/lib/python3.5/dist-packages/numpy/linalg/lapack_lite.cpython-35m-x86_64-linux-gnu.so
#/usr/local/lib/python3.5/dist-packages/numpy/linalg/_umath_linalg.cpython-35m-x86_64-linux-gnu.so
#/usr/lib/python3.5/lib-dynload/_decimal.cpython-35m-x86_64-linux-gnu.so
#/usr/lib/x86_64-linux-gnu/libmpdec.so.2
#/usr/local/lib/python3.5/dist-packages/numpy/fft/fftpack_lite.cpython-35m-x86_64-linux-gnu.so
#/usr/local/lib/python3.5/dist-packages/numpy/random/mtrand.cpython-35m-x86_64-linux-gnu.so
#/home/james/clone/mxnet/python/mxnet/../../lib/libmxnet.so
#/usr/local/cuda/lib64/libcudart.so.8.0
#/usr/local/cuda/lib64/libcublas.so.8.0
#/usr/local/cuda/lib64/libcurand.so.8.0
#/usr/local/cuda/lib64/libcusolver.so.8.0
#/usr/lib/libopenblas.so.0
#/lib/x86_64-linux-gnu/librt.so.1
#/usr/lib/x86_64-linux-gnu/libopencv_core.so.2.4
#/usr/lib/x86_64-linux-gnu/libopencv_highgui.so.2.4
#/usr/lib/x86_64-linux-gnu/libopencv_imgproc.so.2.4
#/usr/lib/x86_64-linux-gnu/libjemalloc.so.1
#/usr/local/cuda/lib64/libcufft.so.8.0
#/usr/lib/x86_64-linux-gnu/libcuda.so.1
#/usr/local/cuda/lib64/libnvrtc.so.8.0
#/usr/lib/x86_64-linux-gnu/libstdc++.so.6
#/usr/lib/x86_64-linux-gnu/libgomp.so.1
#/lib/x86_64-linux-gnu/libgcc_s.so.1
#/usr/lib/x86_64-linux-gnu/libgfortran.so.3
#/usr/lib/x86_64-linux-gnu/libGL.so.1
#/usr/lib/x86_64-linux-gnu/libtbb.so.2
#/usr/lib/x86_64-linux-gnu/libjpeg.so.8
#/lib/x86_64-linux-gnu/libpng12.so.0
#/usr/lib/x86_64-linux-gnu/libtiff.so.5
#/usr/lib/x86_64-linux-gnu/libjasper.so.1
#/usr/lib/x86_64-linux-gnu/libIlmImf-2_2.so.22
#/usr/lib/x86_64-linux-gnu/libHalf.so.12
#/usr/lib/x86_64-linux-gnu/libgtk-x11-2.0.so.0
#/usr/lib/x86_64-linux-gnu/libgdk-x11-2.0.so.0
#/usr/lib/x86_64-linux-gnu/libgobject-2.0.so.0
#/lib/x86_64-linux-gnu/libglib-2.0.so.0
#/usr/lib/x86_64-linux-gnu/libgtkglext-x11-1.0.so.0
#/usr/lib/x86_64-linux-gnu/libgdkglext-x11-1.0.so.0
#/usr/lib/x86_64-linux-gnu/libdc1394.so.22
#/usr/lib/x86_64-linux-gnu/libv4l1.so.0
#/usr/lib/x86_64-linux-gnu/libavcodec-ffmpeg.so.56
#/usr/lib/x86_64-linux-gnu/libavformat-ffmpeg.so.56
#/usr/lib/x86_64-linux-gnu/libavutil-ffmpeg.so.54
#/usr/lib/x86_64-linux-gnu/libswscale-ffmpeg.so.3
#/usr/lib/x86_64-linux-gnu/libnvidia-fatbinaryloader.so.384.111
#/usr/lib/x86_64-linux-gnu/libquadmath.so.0
#/usr/lib/x86_64-linux-gnu/libGLX.so.0
#/usr/lib/x86_64-linux-gnu/libGLdispatch.so.0
#/usr/lib/x86_64-linux-gnu/libjbig.so.0
#/usr/lib/x86_64-linux-gnu/libIex-2_2.so.12
#/usr/lib/x86_64-linux-gnu/libIlmThread-2_2.so.12
#/usr/lib/x86_64-linux-gnu/libgmodule-2.0.so.0
#/usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0
#/usr/lib/x86_64-linux-gnu/libX11.so.6
#/usr/lib/x86_64-linux-gnu/libXfixes.so.3
#/usr/lib/x86_64-linux-gnu/libatk-1.0.so.0
#/usr/lib/x86_64-linux-gnu/libcairo.so.2
#/usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0
#/usr/lib/x86_64-linux-gnu/libgio-2.0.so.0
#/usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0
#/usr/lib/x86_64-linux-gnu/libpango-1.0.so.0
#/usr/lib/x86_64-linux-gnu/libfontconfig.so.1
#/usr/lib/x86_64-linux-gnu/libXrender.so.1
#/usr/lib/x86_64-linux-gnu/libXinerama.so.1
#/usr/lib/x86_64-linux-gnu/libXi.so.6
#/usr/lib/x86_64-linux-gnu/libXrandr.so.2
#/usr/lib/x86_64-linux-gnu/libXcursor.so.1
#/usr/lib/x86_64-linux-gnu/libXcomposite.so.1
#/usr/lib/x86_64-linux-gnu/libXdamage.so.1
#/usr/lib/x86_64-linux-gnu/libXext.so.6
#/usr/lib/x86_64-linux-gnu/libffi.so.6
#/lib/x86_64-linux-gnu/libpcre.so.3
#/usr/lib/x86_64-linux-gnu/libGLU.so.1
#/usr/lib/x86_64-linux-gnu/libXmu.so.6
#/usr/lib/x86_64-linux-gnu/libpangox-1.0.so.0
#/usr/lib/x86_64-linux-gnu/libraw1394.so.11
#/lib/x86_64-linux-gnu/libusb-1.0.so.0
#/usr/lib/x86_64-linux-gnu/libv4l2.so.0
#/usr/lib/x86_64-linux-gnu/libswresample-ffmpeg.so.1
#/usr/lib/x86_64-linux-gnu/libva.so.1
#/usr/lib/x86_64-linux-gnu/libzvbi.so.0
#/usr/lib/x86_64-linux-gnu/libxvidcore.so.4
#/usr/lib/x86_64-linux-gnu/libx265.so.79
#/usr/lib/x86_64-linux-gnu/libx264.so.148
#/usr/lib/x86_64-linux-gnu/libwebp.so.5
#/usr/lib/x86_64-linux-gnu/libwavpack.so.1
#/usr/lib/x86_64-linux-gnu/libvpx.so.3
#/usr/lib/x86_64-linux-gnu/libvorbisenc.so.2
#/usr/lib/x86_64-linux-gnu/libvorbis.so.0
#/usr/lib/x86_64-linux-gnu/libtwolame.so.0
#/usr/lib/x86_64-linux-gnu/libtheoraenc.so.1
#/usr/lib/x86_64-linux-gnu/libtheoradec.so.1
#/usr/lib/x86_64-linux-gnu/libspeex.so.1
#/usr/lib/x86_64-linux-gnu/libsnappy.so.1
#/usr/lib/x86_64-linux-gnu/libshine.so.3
#/usr/lib/x86_64-linux-gnu/libschroedinger-1.0.so.0
#/usr/lib/x86_64-linux-gnu/libopus.so.0
#/usr/lib/x86_64-linux-gnu/libopenjpeg.so.5
#/usr/lib/x86_64-linux-gnu/libmp3lame.so.0
#/usr/lib/x86_64-linux-gnu/libgsm.so.1
#/usr/lib/x86_64-linux-gnu/libcrystalhd.so.3
#/usr/lib/x86_64-linux-gnu/libssh-gcrypt.so.4
#/usr/lib/x86_64-linux-gnu/librtmp.so.1
#/usr/lib/x86_64-linux-gnu/libmodplug.so.1
#/usr/lib/x86_64-linux-gnu/libgme.so.0
#/usr/lib/x86_64-linux-gnu/libbluray.so.1
#/usr/lib/x86_64-linux-gnu/libgnutls.so.30
#/usr/lib/x86_64-linux-gnu/libfreetype.so.6
#/usr/lib/x86_64-linux-gnu/libxcb.so.1
#/usr/lib/x86_64-linux-gnu/libpixman-1.so.0
#/usr/lib/x86_64-linux-gnu/libxcb-shm.so.0
#/usr/lib/x86_64-linux-gnu/libxcb-render.so.0
#/lib/x86_64-linux-gnu/libselinux.so.1
#/lib/x86_64-linux-gnu/libresolv.so.2
#/usr/lib/x86_64-linux-gnu/libharfbuzz.so.0
#/usr/lib/x86_64-linux-gnu/libthai.so.0
#/usr/lib/x86_64-linux-gnu/libXt.so.6
#/lib/x86_64-linux-gnu/libudev.so.1
#/usr/lib/x86_64-linux-gnu/libv4lconvert.so.0
#/usr/lib/x86_64-linux-gnu/libsoxr.so.0
#/usr/lib/x86_64-linux-gnu/libnuma.so.1
#/usr/lib/x86_64-linux-gnu/libogg.so.0
#/usr/lib/x86_64-linux-gnu/liborc-0.4.so.0
#/lib/x86_64-linux-gnu/libgcrypt.so.20
#/usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2
#/usr/lib/x86_64-linux-gnu/libhogweed.so.4
#/usr/lib/x86_64-linux-gnu/libnettle.so.6
#/usr/lib/x86_64-linux-gnu/libgmp.so.10
#/usr/lib/x86_64-linux-gnu/libxml2.so.2
#/usr/lib/x86_64-linux-gnu/libp11-kit.so.0
#/usr/lib/x86_64-linux-gnu/libidn.so.11
#/usr/lib/x86_64-linux-gnu/libtasn1.so.6
#/usr/lib/x86_64-linux-gnu/libXau.so.6
#/usr/lib/x86_64-linux-gnu/libXdmcp.so.6
#/usr/lib/x86_64-linux-gnu/libgraphite2.so.3
#/usr/lib/x86_64-linux-gnu/libdatrie.so.1
#/usr/lib/x86_64-linux-gnu/libSM.so.6
#/usr/lib/x86_64-linux-gnu/libICE.so.6
#/lib/x86_64-linux-gnu/libgpg-error.so.0
#/usr/lib/x86_64-linux-gnu/libkrb5.so.3
#/usr/lib/x86_64-linux-gnu/libk5crypto.so.3
#/lib/x86_64-linux-gnu/libcom_err.so.2
#/usr/lib/x86_64-linux-gnu/libkrb5support.so.0
#/usr/lib/x86_64-linux-gnu/libicuuc.so.55
#/lib/x86_64-linux-gnu/libuuid.so.1
#/lib/x86_64-linux-gnu/libkeyutils.so.1
#/usr/lib/x86_64-linux-gnu/libicudata.so.55
#/usr/lib/python3.5/lib-dynload/_json.cpython-35m-x86_64-linux-gnu.so
#/usr/lib/python3.5/lib-dynload/_ssl.cpython-35m-x86_64-linux-gnu.so
#/lib/x86_64-linux-gnu/libssl.so.1.0.0
#/usr/lib/python3.5/lib-dynload/_multiprocessing.cpython-35m-x86_64-linux-gnu.so
#/usr/lib/python3.5/lib-dynload/termios.cpython-35m-x86_64-linux-gnu.so
#/usr/lib/python3.5/lib-dynload/resource.cpython-35m-x86_64-linux-gnu.so
#/usr/lib/python3.5/lib-dynload/_sqlite3.cpython-35m-x86_64-linux-gnu.so
#/usr/lib/x86_64-linux-gnu/libsqlite3.so.0
#/usr/lib/python3.5/lib-dynload/_lsprof.cpython-35m-x86_64-linux-gnu.so
#/usr/lib/python3.5/lib-dynload/readline.cpython-35m-x86_64-linux-gnu.so
#/lib/x86_64-linux-gnu/libreadline.so.6
#/lib/x86_64-linux-gnu/libtinfo.so.5

MX=$HOME/clone/mxnet
_do_sync_mxnet_gdb() {
    local remote_node="$1"
    local remote_root="$2"
    local remote_user="$3"

    shift 3

    local local_sysroot_path=$MX/sysroot/$remote_node
    local local_path=$local_sysroot_path/$remote_root

    _rsync_dir() {
        local dir="$1"
        shift 1

        _rsync_remote_dir $local_path $remote_node $remote_root $dir
    }

    # NOTE:
    # Always make sure you go into GDB and type "info sharedlibrary"
    # and sync over all those .so files.
    # For some reason, it appears GDB won't read symbols from your
    # binary even if its missed those.
    _sync_gdb_files() {
        # info sharedlibrary:
        GDB_FILES=( \
        /lib/x86_64-linux-gnu/libpthread.so.0 \
        /lib/x86_64-linux-gnu/libc.so.6 \
        /lib/x86_64-linux-gnu/libdl.so.2 \
        /lib/x86_64-linux-gnu/libutil.so.1 \
        /lib/x86_64-linux-gnu/libexpat.so.1 \
        /lib/x86_64-linux-gnu/libz.so.1 \
        /lib/x86_64-linux-gnu/libm.so.6 \
        /lib64/ld-linux-x86-64.so.2 \
        /usr/lib/python3.5/lib-dynload/_ctypes.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/python3.5/lib-dynload/_opcode.cpython-35m-x86_64-linux-gnu.so \
        /usr/local/lib/python3.5/dist-packages/numpy/core/multiarray.cpython-35m-x86_64-linux-gnu.so \
        /usr/local/lib/python3.5/dist-packages/numpy/core/../.libs/libopenblasp-r0-39a31c03.2.18.so \
        /usr/local/lib/python3.5/dist-packages/numpy/core/../.libs/libgfortran-ed201abd.so.3.0.0 \
        /usr/local/lib/python3.5/dist-packages/numpy/core/umath.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/python3.5/lib-dynload/_bz2.cpython-35m-x86_64-linux-gnu.so \
        /lib/x86_64-linux-gnu/libbz2.so.1.0 \
        /usr/lib/python3.5/lib-dynload/_lzma.cpython-35m-x86_64-linux-gnu.so \
        /lib/x86_64-linux-gnu/liblzma.so.5 \
        /usr/lib/python3.5/lib-dynload/_hashlib.cpython-35m-x86_64-linux-gnu.so \
        /lib/x86_64-linux-gnu/libcrypto.so.1.0.0 \
        /usr/local/lib/python3.5/dist-packages/numpy/linalg/lapack_lite.cpython-35m-x86_64-linux-gnu.so \
        /usr/local/lib/python3.5/dist-packages/numpy/linalg/_umath_linalg.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/python3.5/lib-dynload/_decimal.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/x86_64-linux-gnu/libmpdec.so.2 \
        /usr/local/lib/python3.5/dist-packages/numpy/fft/fftpack_lite.cpython-35m-x86_64-linux-gnu.so \
        /usr/local/lib/python3.5/dist-packages/numpy/random/mtrand.cpython-35m-x86_64-linux-gnu.so \
        /home/$remote_user/clone/mxnet/python/mxnet/../../lib/libmxnet.so \
        /usr/local/cuda/lib64/libcudart.so.8.0 \
        /usr/local/cuda/lib64/libcublas.so.8.0 \
        /usr/local/cuda/lib64/libcurand.so.8.0 \
        /usr/local/cuda/lib64/libcusolver.so.8.0 \
        /usr/lib/libopenblas.so.0 \
        /lib/x86_64-linux-gnu/librt.so.1 \
        /usr/lib/x86_64-linux-gnu/libopencv_core.so.2.4 \
        /usr/lib/x86_64-linux-gnu/libopencv_highgui.so.2.4 \
        /usr/lib/x86_64-linux-gnu/libopencv_imgproc.so.2.4 \
        /usr/lib/x86_64-linux-gnu/libjemalloc.so.1 \
        /usr/local/cuda/lib64/libcufft.so.8.0 \
        /usr/lib/x86_64-linux-gnu/libcuda.so.1 \
        /usr/local/cuda/lib64/libnvrtc.so.8.0 \
        /usr/lib/x86_64-linux-gnu/libstdc++.so.6 \
        /usr/lib/x86_64-linux-gnu/libgomp.so.1 \
        /lib/x86_64-linux-gnu/libgcc_s.so.1 \
        /usr/lib/x86_64-linux-gnu/libgfortran.so.3 \
        /usr/lib/x86_64-linux-gnu/libGL.so.1 \
        /usr/lib/x86_64-linux-gnu/libtbb.so.2 \
        /usr/lib/x86_64-linux-gnu/libjpeg.so.8 \
        /lib/x86_64-linux-gnu/libpng12.so.0 \
        /usr/lib/x86_64-linux-gnu/libtiff.so.5 \
        /usr/lib/x86_64-linux-gnu/libjasper.so.1 \
        /usr/lib/x86_64-linux-gnu/libIlmImf-2_2.so.22 \
        /usr/lib/x86_64-linux-gnu/libHalf.so.12 \
        /usr/lib/x86_64-linux-gnu/libgtk-x11-2.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libgdk-x11-2.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libgobject-2.0.so.0 \
        /lib/x86_64-linux-gnu/libglib-2.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libgtkglext-x11-1.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libgdkglext-x11-1.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libdc1394.so.22 \
        /usr/lib/x86_64-linux-gnu/libv4l1.so.0 \
        /usr/lib/x86_64-linux-gnu/libavcodec-ffmpeg.so.56 \
        /usr/lib/x86_64-linux-gnu/libavformat-ffmpeg.so.56 \
        /usr/lib/x86_64-linux-gnu/libavutil-ffmpeg.so.54 \
        /usr/lib/x86_64-linux-gnu/libswscale-ffmpeg.so.3 \
        /usr/lib/x86_64-linux-gnu/libnvidia-fatbinaryloader.so.384.111 \
        /usr/lib/x86_64-linux-gnu/libquadmath.so.0 \
        /usr/lib/x86_64-linux-gnu/libGLX.so.0 \
        /usr/lib/x86_64-linux-gnu/libGLdispatch.so.0 \
        /usr/lib/x86_64-linux-gnu/libjbig.so.0 \
        /usr/lib/x86_64-linux-gnu/libIex-2_2.so.12 \
        /usr/lib/x86_64-linux-gnu/libIlmThread-2_2.so.12 \
        /usr/lib/x86_64-linux-gnu/libgmodule-2.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libpangocairo-1.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libX11.so.6 \
        /usr/lib/x86_64-linux-gnu/libXfixes.so.3 \
        /usr/lib/x86_64-linux-gnu/libatk-1.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libcairo.so.2 \
        /usr/lib/x86_64-linux-gnu/libgdk_pixbuf-2.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libgio-2.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libpangoft2-1.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libpango-1.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libfontconfig.so.1 \
        /usr/lib/x86_64-linux-gnu/libXrender.so.1 \
        /usr/lib/x86_64-linux-gnu/libXinerama.so.1 \
        /usr/lib/x86_64-linux-gnu/libXi.so.6 \
        /usr/lib/x86_64-linux-gnu/libXrandr.so.2 \
        /usr/lib/x86_64-linux-gnu/libXcursor.so.1 \
        /usr/lib/x86_64-linux-gnu/libXcomposite.so.1 \
        /usr/lib/x86_64-linux-gnu/libXdamage.so.1 \
        /usr/lib/x86_64-linux-gnu/libXext.so.6 \
        /usr/lib/x86_64-linux-gnu/libffi.so.6 \
        /lib/x86_64-linux-gnu/libpcre.so.3 \
        /usr/lib/x86_64-linux-gnu/libGLU.so.1 \
        /usr/lib/x86_64-linux-gnu/libXmu.so.6 \
        /usr/lib/x86_64-linux-gnu/libpangox-1.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libraw1394.so.11 \
        /lib/x86_64-linux-gnu/libusb-1.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libv4l2.so.0 \
        /usr/lib/x86_64-linux-gnu/libswresample-ffmpeg.so.1 \
        /usr/lib/x86_64-linux-gnu/libva.so.1 \
        /usr/lib/x86_64-linux-gnu/libzvbi.so.0 \
        /usr/lib/x86_64-linux-gnu/libxvidcore.so.4 \
        /usr/lib/x86_64-linux-gnu/libx265.so.79 \
        /usr/lib/x86_64-linux-gnu/libx264.so.148 \
        /usr/lib/x86_64-linux-gnu/libwebp.so.5 \
        /usr/lib/x86_64-linux-gnu/libwavpack.so.1 \
        /usr/lib/x86_64-linux-gnu/libvpx.so.3 \
        /usr/lib/x86_64-linux-gnu/libvorbisenc.so.2 \
        /usr/lib/x86_64-linux-gnu/libvorbis.so.0 \
        /usr/lib/x86_64-linux-gnu/libtwolame.so.0 \
        /usr/lib/x86_64-linux-gnu/libtheoraenc.so.1 \
        /usr/lib/x86_64-linux-gnu/libtheoradec.so.1 \
        /usr/lib/x86_64-linux-gnu/libspeex.so.1 \
        /usr/lib/x86_64-linux-gnu/libsnappy.so.1 \
        /usr/lib/x86_64-linux-gnu/libshine.so.3 \
        /usr/lib/x86_64-linux-gnu/libschroedinger-1.0.so.0 \
        /usr/lib/x86_64-linux-gnu/libopus.so.0 \
        /usr/lib/x86_64-linux-gnu/libopenjpeg.so.5 \
        /usr/lib/x86_64-linux-gnu/libmp3lame.so.0 \
        /usr/lib/x86_64-linux-gnu/libgsm.so.1 \
        /usr/lib/x86_64-linux-gnu/libcrystalhd.so.3 \
        /usr/lib/x86_64-linux-gnu/libssh-gcrypt.so.4 \
        /usr/lib/x86_64-linux-gnu/librtmp.so.1 \
        /usr/lib/x86_64-linux-gnu/libmodplug.so.1 \
        /usr/lib/x86_64-linux-gnu/libgme.so.0 \
        /usr/lib/x86_64-linux-gnu/libbluray.so.1 \
        /usr/lib/x86_64-linux-gnu/libgnutls.so.30 \
        /usr/lib/x86_64-linux-gnu/libfreetype.so.6 \
        /usr/lib/x86_64-linux-gnu/libxcb.so.1 \
        /usr/lib/x86_64-linux-gnu/libpixman-1.so.0 \
        /usr/lib/x86_64-linux-gnu/libxcb-shm.so.0 \
        /usr/lib/x86_64-linux-gnu/libxcb-render.so.0 \
        /lib/x86_64-linux-gnu/libselinux.so.1 \
        /lib/x86_64-linux-gnu/libresolv.so.2 \
        /usr/lib/x86_64-linux-gnu/libharfbuzz.so.0 \
        /usr/lib/x86_64-linux-gnu/libthai.so.0 \
        /usr/lib/x86_64-linux-gnu/libXt.so.6 \
        /lib/x86_64-linux-gnu/libudev.so.1 \
        /usr/lib/x86_64-linux-gnu/libv4lconvert.so.0 \
        /usr/lib/x86_64-linux-gnu/libsoxr.so.0 \
        /usr/lib/x86_64-linux-gnu/libnuma.so.1 \
        /usr/lib/x86_64-linux-gnu/libogg.so.0 \
        /usr/lib/x86_64-linux-gnu/liborc-0.4.so.0 \
        /lib/x86_64-linux-gnu/libgcrypt.so.20 \
        /usr/lib/x86_64-linux-gnu/libgssapi_krb5.so.2 \
        /usr/lib/x86_64-linux-gnu/libhogweed.so.4 \
        /usr/lib/x86_64-linux-gnu/libnettle.so.6 \
        /usr/lib/x86_64-linux-gnu/libgmp.so.10 \
        /usr/lib/x86_64-linux-gnu/libxml2.so.2 \
        /usr/lib/x86_64-linux-gnu/libp11-kit.so.0 \
        /usr/lib/x86_64-linux-gnu/libidn.so.11 \
        /usr/lib/x86_64-linux-gnu/libtasn1.so.6 \
        /usr/lib/x86_64-linux-gnu/libXau.so.6 \
        /usr/lib/x86_64-linux-gnu/libXdmcp.so.6 \
        /usr/lib/x86_64-linux-gnu/libgraphite2.so.3 \
        /usr/lib/x86_64-linux-gnu/libdatrie.so.1 \
        /usr/lib/x86_64-linux-gnu/libSM.so.6 \
        /usr/lib/x86_64-linux-gnu/libICE.so.6 \
        /lib/x86_64-linux-gnu/libgpg-error.so.0 \
        /usr/lib/x86_64-linux-gnu/libkrb5.so.3 \
        /usr/lib/x86_64-linux-gnu/libk5crypto.so.3 \
        /lib/x86_64-linux-gnu/libcom_err.so.2 \
        /usr/lib/x86_64-linux-gnu/libkrb5support.so.0 \
        /usr/lib/x86_64-linux-gnu/libicuuc.so.55 \
        /lib/x86_64-linux-gnu/libuuid.so.1 \
        /lib/x86_64-linux-gnu/libkeyutils.so.1 \
        /usr/lib/x86_64-linux-gnu/libicudata.so.55 \
        /usr/lib/python3.5/lib-dynload/_json.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/python3.5/lib-dynload/_ssl.cpython-35m-x86_64-linux-gnu.so \
        /lib/x86_64-linux-gnu/libssl.so.1.0.0 \
        /usr/lib/python3.5/lib-dynload/_multiprocessing.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/python3.5/lib-dynload/termios.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/python3.5/lib-dynload/resource.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/python3.5/lib-dynload/_sqlite3.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/x86_64-linux-gnu/libsqlite3.so.0 \
        /usr/lib/python3.5/lib-dynload/_lsprof.cpython-35m-x86_64-linux-gnu.so \
        /usr/lib/python3.5/lib-dynload/readline.cpython-35m-x86_64-linux-gnu.so \
        /lib/x86_64-linux-gnu/libreadline.so.6 \
        /lib/x86_64-linux-gnu/libtinfo.so.5 \
        )

        mkdir -p \
            $local_path/python/mxnet

        local files_from="$(mktemp)"
        for f in "${GDB_FILES[@]}"; do
            echo "$f" >> $files_from
        done

        mkdir -p $local_sysroot_path
        _rsync_files_from $files_from $remote_node $local_sysroot_path
        rm $files_from
    }

    _sync_files() {
#        _rsync_dir lib
        _sync_gdb_files
    }
    if [ "$IS_WIFI_LOW_BANDWIDTH" != 'yes' ]; then
        _sync_files &
    fi
    _kill_remote_gdb $remote_node &
    wait
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
do_sync_mxnet_gdb_logan() {
    _do_sync_mxnet_gdb logan /home/james/clone/mxnet james
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

do_remote_compile() {
    local remote_node="$1"
    shift 1

    local args=()

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
    if [ "$RESTART_GDB" = 'yes' ]; then
        # Re-start emacs debugger.
        restart_cmd="killall $RESTART_GDB_SH_SCRIPT || true"
    fi
    local build_remote_sh="$(cat <<EOF
set -e
cd $REMOTE_HOME
./make.sh $@
$restart_cmd
EOF
)"
    set +e
    (
    ( ssh $remote_node 2>&1 ) <<<"$build_remote_sh" | \
        replace_paths.py \
            --local "$LOCAL_HOME" \
            --remote "$REMOTE_HOME" \
            --full-path \
            "${args[@]}" | \
            filter_out
    )
    local ret=$?
    set -e
    if [ "$ret" = '0' ]; then
        echo_green "BUILD SUCCESS"
    else
        echo_green "BUILD FAILED; status = $ret"
    fi
    return "$ret"
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

echo_green() {
    local msg="$1"
    shift 1
    echo -e "${COL_GREEN}${msg}${COL_NONE}"
}
echo_red() {
    local msg="$1"
    shift 1
    echo -e "${COL_RED}${msg}${COL_NONE}"
}

kill_gdbserver() {
    killall gdbserver || true
    sleep 0.5
}
_run_emacs() {
    local cntk_gdb_source_file="$1"
    shift 1
    kill_gdbserver
    if [ "$CNTK_DIR" = "" ]; then
        CNTK_DIR="$CN"
    fi
    (
    cd $CNTK_DIR
    CNTK_GDB_SOURCE_FILE=$cntk_gdb_source_file \
    CNTK_DEBUG=yes \
        emacs -nw
    )
}
run_emacs_cntk() {
    _run_emacs gdb.break
}
run_emacs_cntk_unittest() {
    _run_emacs gdb.unittest.break
}

run_emacs_cntk_unittest_local() {
    _run_emacs gdb.unittest.local.break
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

# ret=0 if $direc is a mountpoint for something.
is_dir_mount_point() {
    local direc="$1"
    shift 1
    df -h --output=target | tail -n+2 | grep "$direc"
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
    if is_remote_home_mounted "$remote_node"; then
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
