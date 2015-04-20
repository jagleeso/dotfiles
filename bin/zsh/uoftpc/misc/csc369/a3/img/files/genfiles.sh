#!/usr/bin/env bash
cd $(dirname $0)
mkfile() {
    local n="$1"
    local file="$2"
    shift 2
    dd if=/dev/zero of=$file bs=$n count=1
}

mkfile $((12*1024+1)) 1_singly_indirect_block
mkfile $((12*1024+256*1024+1)) 1_doubly_indirect_block
mkfile $((12*1024+256*1024+256*256*1024+1)) 1_triply_indirect_block
mkfile $((3*1024)) 3_direct_blocks
