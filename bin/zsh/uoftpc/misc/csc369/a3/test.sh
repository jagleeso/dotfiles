#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(realpath "$(dirname "$0")")"
IMG=$SCRIPT_DIR/img
FILES=$IMG/files
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
errcode=
do_error_test() {
    set -e
    local name="$1"
    local img="$2"
    local actual_modify_cmds="$3"
    shift 2

    name="error-$name"
    tmp=$(mktemp -d test-$name-XXX)
    mkdir $tmp/img
    cp -r $IMG/. $tmp/img
    local tdir=$(realpath $tmp)
    mkdir -p $tmp/mnt
    cd $tmp

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

    # ACTUAL
    # modify state using regular operations
    # mount img using fuse
    # "check", output to file

    copyimg $img
    local DISK=$(realpath $imgcopy)
    source $SCRIPT_DIR/wrappers.sh
    local MOUNT=$tdir/mnt
    (
        cd mnt
        if [ "$GDB" == "yes" ]; then
            set_gdb
        fi
        set +e
        eval "$actual_modify_cmds"
        log_errcode $tdir/errfile.txt $?
        set -e
        if [ "$GDB" == "yes" ]; then
            unset_gdb
        fi
    )
    # people don't print newlines, goodtimes
    echo

    if [ "$(get_errcode $tdir/errfile.txt)" == "0" ]; then
        test_header_checkme $name
        echo "EXPECTED ERROR CODE BUT SAW 0"
    else
        test_header_success $name
    fi

}
log_errcode() {
    local errfile="$1"
    local errcode="$2"
    shift 2
    echo "Error code = $errcode" > $errfile
}
get_errcode() {
    local errfile="$1"
    shift 1
    cat $errfile | perl -lane 'if (/Error code = (\d+)/) { print $1; }'
}
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

        eval echo "$expect_modify_cmds"
        eval "$expect_modify_cmds"
        eval echo "$expect_check_cmds"
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
    source $SCRIPT_DIR/wrappers.sh
    local MOUNT=$tdir/mnt
    if [ -f $tdir/actual.txt ]; then
        rm $tdir/actual.txt
    fi
    (
        cd mnt
        if [ "$GDB" == "yes" ]; then
            set_gdb
        fi
        set +e

        eval echo "$actual_modify_cmds" 
        eval "$actual_modify_cmds" 2>&1 | tee --append $tdir/actual.txt
        log_errcode $tdir/errfile.txt $?
        set -e
        if [ "$GDB" == "yes" ]; then
            unset_gdb
        fi
    )

    local imagecorrupt=0
    if ! mountimg $imgcopy > $tdir/mountimg.txt 2>&1; then
        imagecorrupt=1
    else
        (
            # TODO: check for errors and handle
            set +e
            e2fsck -f -n $imgcopy > $tdir/e2fsck.txt 2>&1
            log_errcode $tdir/e2fsck_errfile.txt $?
            cd mnt
            if [ "$GDB" == "yes" ]; then
                set_gdb
                eval "$actual_check_cmds" >> $tdir/actual.txt 2>&1 
                unset_gdb
            else
                eval echo "$actual_check_cmds" 
                eval "$actual_check_cmds" >> $tdir/actual.txt 2>&1 
            fi
            # find -type f | xargs -r -n 1 ls -i > $tdir/inodes.txt
            ls -l -i > $tdir/inodes.txt
            set -e
        )
        umount
        rm $imgcopy
    fi

    cd $A3

    are_diff() {
        ! diff -q -b $tdir/expect.txt $tdir/actual.txt > /dev/null
    }
    prog_err() {
        [ "$(get_errcode $tdir/errfile.txt)" != "0" ]
    }
    fsck_err() {
        [ "$(get_errcode $tdir/e2fsck_errfile.txt)" != "0" ]
    }
    image_corrupt() {
        [ "$imagecorrupt" == "1" ]
    }
    cat_file() {
        local f="$1"
        echo -e "=> \e[1;36m$f\e[0m"
        cat $f | while read line; do
            echo "    $line"
        done
        echo
    }

    if image_corrupt || are_diff || prog_err || fsck_err; then
        test_header_checkme $name
        if image_corrupt; then
            cat_file $tdir/mountimg.txt
        else
            if prog_err; then
                cat_file $tdir/errfile.txt
            fi
            if fsck_err; then
                cat_file $tdir/e2fsck_errfile.txt
                cat_file $tdir/e2fsck.txt
            fi
            # vimdiff $tdir/expect.txt $tdir/actual.txt
            if are_diff; then
                cat_file $tdir/expect.txt 
                cat_file $tdir/actual.txt
            fi
        fi
    else
        test_header_success $name
    fi
    echo

    # echo rm -rf $tdir
}

test_header_success() {
    local name="$1"
    shift 1
    echo -e "\e[1;32m[SUCCESS] $name\e[0m ================="
}
test_header_checkme() {
    local name="$1"
    shift 1
    echo -e "\e[1;34m[CHECKME] $name\e[0m ================="
}

e_ls() {
    echo .
    echo ..
    ls -1 "$@" | sort
}
e_ln() {
    local src="$1"
    local dst="$2"
    shift 2
    ln "$src" "$dst" 2>/dev/null || true
    [ -f "$dst" ]
}
e_cp() {
    local src="$1"
    local dst="$2"
    shift 2
    bytes() {
        wc $1 -c | awk '{print $1}' 
    }
    # for some reason this fails (first time file is zeroed, second time file gets filled):
    # cp /home/james/clone/again/dotfiles/bin/zsh/uoftpc/misc/csc369/a3/img/files/smallfile afile 
    cp "$src" "$dst"
    if [ "$(bytes $src)" == "$(bytes $dst)" ]; then
        return
    fi
    # echo HELLO1
    # wc "$src"
    # wc "$dst"
    # echo THERE1
    cp "$src" "$dst"
    if [ "$(bytes $src)" != "$(bytes $dst)" ]; then
        exit 1
    fi
    # echo HELLO2
    # wc "$src"
    # wc "$dst"
    # echo THERE2
    # if [ -d "$dst" ]; then
    #     cp "$src" "$dst"
    # else
    #     # for some reason this fails (first time file is zeroed, second time file gets filled):
    #     # cp /home/james/clone/again/dotfiles/bin/zsh/uoftpc/misc/csc369/a3/img/files/smallfile afile 
    #     cat "$src" > "$dst"
    # fi
}

unmount_fuse() {
    for f in $(df -h 2>/dev/null | grep fuse | perl -lane 'print $F[-1]'); do
        echo fusermount -u -z $f
        fusermount -u -z $f
    done
}
cleanup() {
    unmount_fuse
    rm -rf test-*-* || true
}

test_ls() {

    dotest \
        onefile onefile.img \
        "" "e_ls" \
        "" '$EXT2_LS $DISK /' \

    dotest \
        twolevel twolevel.img \
        "" "e_ls level1/level2" \
        "" '$EXT2_LS $DISK /level1/level2' \

    dotest \
        bigdir bigdir.img \
        "" "e_ls 234" \
        "" '$EXT2_LS $DISK /234' \

}

test_ln() {

    dotest \
        onefile onefile.img \
        "ln afile linkfile || true; echo 'write from linkfile' >> linkfile" "cat afile" \
        \
        '
        $EXT2_LN $DISK /afile /linkfile; 
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
        '$EXT2_MKDIR $DISK /pots; $EXT2_MKDIR $DISK /pots/pans' '$EXT2_LS $DISK /pots' \

    dotest \
        onefile onefile.img \
        "mkdir pots; mkdir spoons; mkdir pots/pans" "e_ls" \
        '
        $EXT2_MKDIR $DISK /pots;
        $EXT2_MKDIR $DISK /spoons;
        $EXT2_MKDIR $DISK /pots/pans
        ' 
        '$EXT2_LS $DISK /' \

}

test_cp() {

    dotest \
        onefile onefile.img \
        'e_cp afile bfile' 'cat bfile' \
        '$EXT2_CP $DISK /afile /bfile;' 'cat bfile' \

}

test_rm() {

    dotest \
        onefile onefile.img \
        'rm afile' 'e_ls' \
        '$EXT2_RM $DISK /afile;' 'e_ls' \

}

# Daniel's suggestions:

# Step 1 - can metadata/directories be read?  
test_metadata() {

    ls_test() {
        local f="$1"
        shift 1
        dotest \
            metadata-ls-$f $f.img \
            "" "e_ls" \
            "" '$EXT2_LS $DISK /' \

    }

    ls_test emptydisk
    ls_test onefile
    ls_test onedirectory
    # multiple blocks
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
            "" '$EXT2_LS $DISK '"$path"'' \

    }
    path_test level1 /level1
    path_test level2 /level1/level2
    path_test level1_parent /level1/../
    path_test level2_parent /level1/level2/..

}

# Step 3 - Can we make simple modifications:
test_modsimple() {

    # Each should:
    #   (1) add a directory entry to / (which should fit in the first block) and update the size
    #   (2) allocate a new data block and populate it with . and .., or smallfile, or the link, respectively
    #   (3) allocate a new inode, populate it, and point it to the data block
    #   (4) keep our bitmaps & block groups up to date


    # ext2_mkdir emptydisk.img dir1
    dotest \
        modsimple-mkdir emptydisk.img \
        'mkdir dir1' 'e_ls' \
        '$EXT2_MKDIR $DISK /dir1' 'e_ls' \

    # ext2_cp emptydisk.img smallfile / 
    dotest \
        modsimple-cp emptydisk.img \
        'e_cp $FILES/smallfile smallfile' 'e_ls; echo; cat smallfile' \
        '$EXT2_CP $DISK $FILES/smallfile /' 'e_ls; echo; cat smallfile'
    #or ext2_cp emptydisk.img smallfile /smallfile
    dotest \
        modsimple-cp-targetfullpath emptydisk.img \
        'e_cp $FILES/smallfile smallfile' 'e_ls; echo; cat smallfile' \
        '$EXT2_CP $DISK $FILES/smallfile /smallfile' 'e_ls; echo; cat smallfile' \

    # ext2_ln onefile.img /afile /newfile 
    dotest \
        modsimple-ln onefile.img \
        'e_ln afile newfile' 'e_ls; echo; cat newfile' \
        '$EXT2_LN $DISK /afile /newfile' 'e_ls; echo; cat newfile'
    #or ext2_ln onefile.img /newfile /afile
    dotest \
        modsimple-ln-backwards-args onefile.img \
        'e_ln afile newfile' 'e_ls; echo; cat newfile' \
        '$EXT2_LN $DISK /newfile /afile' 'e_ls; echo; cat newfile' \

    # rm should:
    #  (1) remove the directory entry
    #  (2) nuke the inode for afile
    #  (3) update bitmaps/group 

    # ext2_rm onefile.img /afile
    dotest \
        modsimple-rm onefile.img \
        'rm afile' 'e_ls' \
        '$EXT2_RM $DISK /afile' 'e_ls' \

}

test_blocks() {

    # set -x
    # Step 4 - multi-block & indirect

    # ext2_cp onefile.img smallfile /afile #overwrite existing file
    # 1 direct block
    # dotest \
    #     blocks-cp-overwrite-directblock onefile.img \
    #     'e_cp $FILES/smallfile smallfile' 'e_ls; echo; cat afile' \
    #     '$EXT2_CP $DISK $FILES/smallfile /smallfile' 'e_ls; echo; cat smallfile' \

    dotest \
        blocks-cp-overwrite-directblock-to-dir onefile.img \
        'e_cp $FILES/smallfile smallfile' 'e_ls; echo; cat smallfile' \
        '$EXT2_CP $DISK $FILES/smallfile /' 'e_ls; echo; cat smallfile' \

    __do_cptest() {
        local name="$1"
        local file="$2"
        local to="$3"
        local wc_file="$4"
        shift 4
        dotest \
            blocks-cp-$name emptydisk.img \
            'e_cp '"$file"' '"$wc_file"'' 'e_ls; echo; wc '"$wc_file"'' \
            '$EXT2_CP $DISK '"$file"' '"$to"'' 'e_ls; echo; wc '"$wc_file"'' \

    }
    do_cptest_tofile() {
        local name="$1"
        local file="$2"
        shift 2
        __do_cptest $name-tofile $file /afile afile
    }
    do_cptest_todir() {
        local name="$1"
        local file="$2"
        shift 2
        __do_cptest $name-todir $file / $(basename $file)
    }

    # A3 only needs to handle single **indirection**

    # TODO: make largefile4 have an indirect block
    # ext2_cp emptydisk.img largefile4 /
    do_cptest_tofile directblocks $FILES/3_direct_blocks
    do_cptest_tofile singly $FILES/1_singly_indirect_block

    # TODO: make largefile4 have an indirect block
    # ext2_cp emptydisk.img largefile4 /
    # do_cptest_todir directblocks $FILES/1_singly_indirect_block
    # do_cptest_todir singly $FILES/1_singly_indirect_block
    
    # # TODO: make largefile12 have an doubly indirect block
    # # ext2_cp emptydisk.img largefile12 /
    # do_cptest doubly $FILES/1_doubly_indirect_block

    # # TODO: make largefile13 have an triply indirect block
    # # ext2_cp emptydisk.img largefile13 /
    # do_cptest triply $FILES/1_triply_indirect_block

    # The last test case should allocate an indirect block, with a pointer to the last block 
    # of the file.  fusemount is a good way to test whether the entire file made it. e2fsck -n 
    # before fusemount to make sure they didn't blow anything up. 

}

test_direntry() {

    # Step 5 - trickier direntry manipulation
    # 
    # ext2_mkdir fullblockdir.img** /longenoughdirectorynametooverflowtheexistingblock
    # ext2_rm fullblockdir.img /8-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    # ext2_rm hardlink.img /level1/bfile

    # The latter should remove the /level1/bfile direntry but not the inode (linked from /bfile-ln)

    # ext2_mkdir fullblockdir.img** /longenoughdirectorynametooverflowtheexistingblock
    big() {
        local j="$1"
        shift 1
        for i in {1..150}; do 
            echo -n $j
        done
    }
    overflowdir="$(big 6)"
    dotest \
        trickydirentry-mkdir-overflowblock fullblockdir.img \
        'mkdir '"$overflowdir"'' 'e_ls' \
        '$EXT2_MKDIR $DISK /'"$overflowdir"'' 'e_ls' \

    # ext2_rm fullblockdir.img /8-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
    dotest \
        trickydirentry-rm fullblockdir.img \
        'rm '"$(big 1)"'' 'e_ls' \
        '$EXT2_RM $DISK /'"$(big 1)"'' 'e_ls' \

    # ext2_rm hardlink.img /level1/bfile
    dotest \
        trickydirentry-rm-link hardlink.img \
        'rm level1/bfile' 'e_ls level1' \
        '$EXT2_RM $DISK /level1/bfile' 'e_ls level1' \

}

test_errors() {

    # Step 5 - error codes - they should have some

    # ext2_ls emptydisk.img /bogus/
    do_error_test ls-nosuchdir emptydisk.img \
        '$EXT2_LS $IMG/emptydisk.img /bogus/'
    # ext2_cp emptydisk.img notafile /
    do_error_test cp-nosuchfile emptydisk.img \
        '$EXT2_CP $IMG/emptydisk.img notafile /'
    # ext2_cp twolevel.img smallfile /level1/level3/
    do_error_test cp-nosuchdir twolevel.img \
        '$EXT2_CP $IMG/twolevel.img smallfile /level1/level3/'
    # ext2_rm twolevel.img /level1
    do_error_test rm-nonemptydir twolevel.img \
        '$EXT2_RM $IMG/twolevel.img /level1'
    # ext2_ln onefile.img /notafile /stillnotafile
    do_error_test ln-nosuchfiles onefile.img \
        '$EXT2_LN $IMG/onefile.img /notafile /stillnotafile'
    # ext2_mkdir onefile.img /afile
    do_error_test mkdir-fileexists onefile.img \
        '$EXT2_MKDIR $IMG/onefile.img /afile'
    # ext2_mkdir emptydisk.img ..
    do_error_test mkdir-parent emptydisk.img \
        '$EXT2_MKDIR $IMG/emptydisk.img ..'

}

# Daniel's tests:
# test_metadata
#   ext2_ls
#   Basic: Reads metadata
#   Diretry that spans 2 blocks (reading)

# test_paths
#   Path traversal beyond the root directory

# test_modsimple
#   mkdir
#   Removing an item from a directory (rm)
#   ext_ln

# test_blocks
#   Copying a file x 2

# test_direntry
#  Diretry that spans 2 blocks (creation)

# test_errors
#  mkdir

# set -x
if [ "$RUN" != "yes" ]; then
    make
    ctags -R
    cleanup
fi
# if [ "$GDB" == "yes" ]; then
#     gdb="gdb --args"
# fi
"$@"
