#!/usr/bin/env bash
set -e
_diff_starter() {
    f="$1"
    shift 1
    vimdiff $EV/starter/a2/$f $f
}
_diff_soln() {
    f="$1"
    shift 1
    vimdiff $EV/soln/$f $f
}
_diff_impl() {
    f="$1"
    shift 1
    vimdiff $EV/starter/a2/$f $EV/soln/$f
}
