#!/usr/bin/env bash
cd $(dirname $0)
./summary.R | sed 's/^\s*//; s/\s\+/ /g; s/\s*:\s*/:/g' \
    | awk 'BEGIN { FS=":"; OFS="\t" } {print $1, $2}'
