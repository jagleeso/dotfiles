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

if [ "$RUN_COMMON" == "yes" ]; then
    "$@"
fi
