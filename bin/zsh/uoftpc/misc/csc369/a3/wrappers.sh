##
## Wrappers for ext2_func $DISK ... (in case someone has weird conventions for arguments)
##
abspath() {
    # in case someone does weird thing with abspath formats:
    # - not/absolute
    # - ./needs/a/dot
    local path="$1"

    # # - ./needs/a/dot
    # echo ".$path"

    # corrrect
    echo "$path"

}
mkdirpath() {
    # in case someone does weird thing with abspath formats:
    # - ./end/in/slash/
    local path="$1"

    # # - ./end/in/slash/
    # echo ".$path/"

    # corrrect
    echo "$path"

}
rmpath() {
    # in case someone does weird thing with abspath formats:
    # - ./end/in/slash/
    local path="$1"

    # # - ./end/in/slash/
    # echo ".$path"

    # corrrect
    echo "$path"

}
lnpath() {
    # in case someone does weird thing with abspath formats:
    # - ./end/in/slash/
    local path="$1"

    # # - ./end/in/slash/
    # echo ".$path/"

    # corrrect
    echo "$path"

}
my_ext2_ls() {
    local img="$1"
    local dir="$2"
    shift 2
    _r $A3/ext2_ls $img $(abspath $dir) "$@" | sort
}
EXT2_LS=my_ext2_ls

my_ext2_cp() {
    local img="$1"
    local src="$2"
    local dst="$3"
    shift 3
    _r $A3/ext2_cp $img $src $(abspath $dst) "$@"
}
EXT2_CP=my_ext2_cp

my_ext2_rm() {
    local img="$1"
    local dir="$2"
    shift 2
    _r $A3/ext2_rm $img $(rmpath $dir) "$@"
}
EXT2_RM=my_ext2_rm

my_ext2_mkdir() {
    local img="$1"
    local dir="$2"
    shift 2
    _r $A3/ext2_mkdir $img $(mkdirpath $dir) "$@"
}
EXT2_MKDIR=my_ext2_mkdir

my_ext2_ln() {
    local img="$1"
    local target="$2"
    local new="$3"
    shift 3
    _r $A3/ext2_ln $img $(lnpath $target) $(lnpath $new) "$@"
}
EXT2_LN=my_ext2_ln

##
## Misc test functions
##

contents() {
    local f="$1"
    shift 1
    wc "$f"
    echo
    echo First 100 characters:
    head -c 100 "$f"
    echo
}


# image mounting functions refer to imgcopy global variable.

# Copy disk image, set it to imgcopy
copyimg() {
    local img="$1"
    shift 1
    imgcopy=$(mktemp $tdir/img/$img.XXX)
    cp $tdir/img/$img $imgcopy
}
mountimg() {
    local img="$1"
    shift 1
    # make sure we're operating on an img copy not the original.
    echo "$imgcopy" | grep '\.img\.\w\w\w$'
    fuseext2 -o rw+ $img $tdir/mnt 
}
mountnewimg() {
    local img="$1"
    shift 1
    copyimg $img
    mountimg $imgcopy
}
umount() {
    local tries=5
    local i=0
    while [ $i -lt $tries ]; do
        if [ -z "$(fuse_mounts)" ] || fusermount -u $tdir/mnt -z > /dev/null 2>&1; then
            return 0
        fi
        sleep 1
        let i=$((i+1))
    done
    return 1
}
