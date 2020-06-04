_maybe_set_go_path() {
    local direc="$1"
    shift 1
    if [ "$GOPATH" != "" ]; then
        return
    fi
    if [ -d $direc ] && [ -e $direc/bin/go ]; then
        # echo "> Add GOPATH=$direc"
        export GOPATH=$direc
        export GOROOT=$direc
        export PATH="$PATH:$GOPATH/bin"
    fi
}
_maybe_set_go_path $HOME/clone/go
