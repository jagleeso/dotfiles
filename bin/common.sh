#!/usr/bin/env bash
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
    local remote_syslab_port="$2"
    local remote_xen1_port="$3"
    shift 3
    ssh -v \
        -L$local_port:localhost:$remote_syslab_port syslab -t ssh -v \
        -L$remote_syslab_port:localhost:$remote_xen1_port \
        james@10.70.2.2
}

tunnel_only_to_syslab() {
    local local_port="$1"
    local remote_syslab_port="$2"
    local remote_xen1_port="$3"
    shift 3
    # NOTE: this assumes a tunnel is already setup on syslab.
    syslab_is_tunneling_to_xen1() {
        # Make sure this is running:
        # ssh -v -L 8787:localhost:22 james@10.70.2.2
        ssh syslab "ps aux | grep -v grep | grep -q 'ssh.*-L.*$remote_syslab_port'"
    }
    if ! syslab_is_tunneling_to_xen1; then
        echo "ERROR: You need to login to syslab and tunnel from syslab to xen1:"
        echo "  $ ssh syslab"
        echo "  $ ssh -v -L $remote_syslab_port:localhost:$remote_xen1_port james@10.70.2.2"
        exit 1
    fi
    # Try using autossh locally to keep connection alive.
    autossh -v \
        -L $local_port:localhost:$remote_syslab_port syslab
}

if [ "$RUN_COMMON" == "yes" ]; then
    "$@"
fi
