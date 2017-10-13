#!/bin/sh

for helptype in command variable module property policy ; do
    if cmake --help-$helptype "$@" > /dev/null; then
        cmake --help-$helptype "$@" | less
        break
    fi
done
