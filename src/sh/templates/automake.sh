#!/bin/bash
# Template script for re-running a script (./make.sh) whenever
# files in the project change.
#
# Changes are detected using "entr" cmdline utility.
#
# project_files()
#   All the files in the project we should monitor changes to.
# rebuild()
#   Calls ./make.sh whenever one of the above files changes.
#   Tee's results to ./automake.txt
set -e
# set -x
NCPU=$(grep -c ^processor /proc/cpuinfo)
SCRIPT=$(realpath "$0")
ROOT=$(realpath $(dirname $0))
cd $ROOT

COL_BLACK='\033[0;30m'
COL_RED='\033[0;31m'
COL_GREEN='\033[0;32m'
COL_BROWN_ORANGE='\033[0;33m'
COL_BLUE='\033[0;34m'
COL_PURPLE='\033[0;35m'
COL_CYAN='\033[0;36m'
COL_LIGHT_GRAY='\033[0;37m'
COL_DARK_GRAY='\033[1;30m'
COL_LIGHT_RED='\033[1;31m'
COL_LIGHT_GREEN='\033[1;32m'
COL_YELLOW='\033[1;33m'
COL_LIGHT_BLUE='\033[1;34m'
COL_LIGHT_PURPLE='\033[1;35m'
COL_LIGHT_CYAN='\033[1;36m'
COL_WHITE='\033[1;37m'

COL_NONE='\033[0m' # No Color

main() {
    project_files | entr bash -c "$SCRIPT rebuild" 
}

project_files() {
    find -type f | \
        grep --perl-regexp '.*\.(py|tex|cls|bib|pdf|png)$'
#        grep -v --perl-regexp '^./(bindings|Examples|cmake-build-debug)'
    echo "$ROOT/make.sh"
}
rebuild() {
    set +e
    ./make.sh 2>&1 | tee $ROOT/automake.txt
    local ret="${PIPESTATUS[0]}"
    set -e

    _tee() {
        tee --append $ROOT/automake.txt
    }

    local stat=
    if [ "$ret" = '0' ]; then
        stat="${COL_GREEN}BUILT${COL_NONE}"
    else
        stat="${COL_RED}FAILED${COL_NONE}"
    fi

    echo -e "$stat: $(date) ====================================================" | _tee
    echo | _tee
    return $ret
}

(
    if [ $# -lt 1 ]; then
        main "$@"
    else
        "$@"
    fi
)
