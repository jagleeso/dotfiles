#!/usr/bin/env bash

set -e

# set -x
# testimg_ls() {
#     local img="$1"
#     ./ext2_ls $img
# }
# for img in ~/a3-marking/img/*.img; do
#     testimg $img
# done

IMG=~/a3-marking/img
A3=$PWD
gdb=""
_r() {
    $gdb "$@"
}
set_gdb() {
    gdb="gdb --args"
}
unset_gdb() {
    gdb=""
}

imgcopy=
dotest() {
    set -e
    local name="$1"
    local img="$2"
    local expect_modify_cmds="$3"
    local expect_check_cmds="$4"
    local actual_modify_cmds="$5"
    local actual_check_cmds="$6"
    shift 6

    tmp=$(mktemp -d test-$name-XXX)
    mkdir $tmp/img
    cp $IMG/*.img $tmp/img
    local tdir=$(realpath $tmp)
    mkdir -p $tmp/mnt
    cd $tmp

    copyimg() {
        local img="$1"
        shift 1
        imgcopy=$(mktemp $tdir/img/$img.XXX)
        cp $tdir/img/$img $imgcopy
    }
    mountimg() {
        local img="$1"
        shift 1
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
            if fusermount -u $tdir/mnt -z > /dev/null 2>&1; then
                return 0
            # else
            #     echo "FAILED WITH: $?"
            fi
            sleep 1
            let i=$((i+1))
        done
        return 1
    }

    # EXPECT
    # modify state using their scripts
    # mount img using fuse
    # "check", output to file

    mountnewimg $img
    (
        cd mnt
        eval "$expect_modify_cmds"
        eval "$expect_check_cmds" > $tdir/expect.txt
    )
    umount
    rm $imgcopy

    # ACTUAL
    # modify state using regular operations
    # mount img using fuse
    # "check", output to file

    copyimg $img
    local DISK=$(realpath $imgcopy)
    local MOUNT=$tdir/mnt
    do_mount() {
        mountimg $imgcopy
    }
    do_umount() {
        umount
    }
    (
        cd mnt
        if [ "$GDB" == "yes" ]; then
            set_gdb
        fi
        set +e
        eval "$actual_modify_cmds"
        set -e
        if [ "$GDB" == "yes" ]; then
            unset_gdb
        fi
    )

    mountimg $imgcopy
    (
        e2fsck -n $imgcopy > $tdir/e2fsck.txt 2>&1 || true
        set +e
        if [ "$GDB" == "yes" ]; then
            set_gdb
            eval "$actual_check_cmds" | tee $tdir/actual.txt
            unset_gdb
        else
            eval "$actual_check_cmds" > $tdir/actual.txt
        fi
        set -e
    )
    umount
    rm $imgcopy

    cd $A3

    echo "$name ================="
    if ! diff -q $tdir/expect.txt $tdir/actual.txt; then
        # vimdiff $tdir/expect.txt $tdir/actual.txt
        for f in $tdir/expect.txt $tdir/actual.txt; do
            echo "=> $f"
            cat $f
            echo
        done
    else
        echo OUTPUT MATCHES
    fi
    echo "e2fsck.txt -----------------"
    cat $tdir/e2fsck.txt
    echo
    echo
    echo

    # echo rm -rf $tdir
}

e_ls() {
    echo .
    echo ..
    ls -1 "$@"
}

unmount_fuse() {
    df -h | grep fuse | perl -lane 'print $F[-1]' | xargs -n 1 fusermount -u || true
}
cleanup() {
    unmount_fuse
    rm -rf test-*-* || true
}

test_ls() {

    dotest \
        onefile onefile.img \
        "" "e_ls" \
        "" '_r $A3/ext2_ls $DISK /' \

    dotest \
        twolevel twolevel.img \
        "" "e_ls level1/level2" \
        "" '_r $A3/ext2_ls $DISK /level1/level2' \

    dotest \
        bigdir bigdir.img \
        "" "e_ls 234" \
        "" '_r $A3/ext2_ls $DISK /234' \

}

test_ln() {

    dotest \
        onefile onefile.img \
        "ln afile linkfile || true; echo 'write from linkfile' >> linkfile" "cat afile" \
        \
        '
        _r $A3/ext2_ln $DISK /afile /linkfile; 
        do_mount; 
        cd $MOUNT;
        echo "write from linkfile" >> linkfile; 
        do_umount;
        ' \
        "cat afile" \

}

test_mkdir() {

    dotest \
        onefile onefile.img \
        "mkdir pots; mkdir pots/pans" "e_ls pots" \
        '_r $A3/ext2_mkdir $DISK /pots; _r $A3/ext2_mkdir $DISK /pots/pans' '_r $A3/ext2_ls $DISK /pots' \

    dotest \
        onefile onefile.img \
        "mkdir pots; mkdir spoons; mkdir pots/pans" "e_ls" \
        '
        _r $A3/ext2_mkdir $DISK /pots;
        _r $A3/ext2_mkdir $DISK /spoons;
        _r $A3/ext2_mkdir $DISK /pots/pans
        ' 
        '_r $A3/ext2_ls $DISK /' \

}

test_cp() {

    dotest \
        onefile onefile.img \
        'cp afile bfile' 'cat bfile' \
        '_r $A3/ext2_cp $DISK /afile /bfile;' 'cat bfile' \

}

test_rm() {

    dotest \
        onefile onefile.img \
        'rm afile' 'e_ls' \
        '_r $A3/ext2_rm $DISK /afile;' 'e_ls' \

}

# Daniel's suggestions:

# Step 1 - can metadata/directories be read?  
test_metadata() {

    ls_test() {
        local f="$1"
        shift 1
        dotest \
            metadata-$f $f.img \
            "" "e_ls" \
            "" '_r $A3/ext2_ls $DISK /' \

    }
    # set -x

    ls_test emptydisk
    ls_test onefile
    ls_test onedirectory
    ls_test twoblockdir
    # ls_test bigdir

}

rel() {
    local path="$1"
    shift 1
    echo $path | perl -lape 's|^/||'
}

test_paths() {

    path_test() {
        local f="$1"
        local path="$2"
        shift 2
        dotest \
            paths-$f twolevel.img \
            "" "e_ls $(rel $path)" \
            "" '_r $A3/ext2_ls $DISK '"$path"'' \

    }
    path_test level1 /level1
    path_test level2 /level1/level2
    path_test level1_parent /level1/../
    path_test level2_parent /level1/level2/..
}

if [ "$RUN" != "yes" ]; then
    make
    cleanup
fi
# if [ "$GDB" == "yes" ]; then
#     gdb="gdb --args"
# fi
"$@"
