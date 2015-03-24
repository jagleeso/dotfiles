view_errors() {
    local file="$1"
    shift 1

    vim "$file" -c 'vimgrep /kernel BUG at.*!$/ % | exec "normal www" | split | normal gF'
    # vim "$file" -c 'vimgrep /\c\(err\|reboot\|bug\|Kernel panic\)/ % | copen'
}

view_with_pattern() {
    local file="$1"
    local pattern="$2"
    shift 2
    vim "$file" -c "vimgrep /$pattern/ % | copen"
}

cat_and_view_errs() {
    local remote="$1"
    local local="$2"
    adb_sh cat "$remote" > "$local"
    view_errors "$local"
}


_test_sudo() {
    local adb_sudo="$1"
    local result="$($adb_sudo echo hi | tr -d '\r\n')"
    [ "$result" = "hi" ]
}
adb_sudo() {
    if _test_sudo adb_sudo_aosp; then
        adb_sudo_aosp "$@"
    elif _test_sudo adb_sudo_supersu; then
        adb_sudo_supersu "$@"
    fi
    # adb_sudo_aosp "$@"
    # adb_sudo_supersu "$@"
}
adb_sudo_supersu() {
    # works with the su command installed by SuperSu
    adb shell 'su -c "'"$@"'"'
}
adb_sudo_aosp() {
    # works with the su command bundled in the AOSP (system/extras/su/su.c)
    # (installed when building via "lunch full_mako-userdebug")
    adb shell 'su 0 sh -c "'"$@"'"'
}

adb_sh() {
    adb_sudo "$@"
}

wait_for_bootloader() {
    while true; do
        if fastboot devices | grep --quiet 'fastboot$'; then
            fastboot devices
            break
        fi
        sleep 1
    done
}

wait_for_boot() {
    local f=$(mktemp)
    while true; do
        if adb devices | grep --quiet 'device$'; then
            adb devices
            local remote=/data/local/tmp/$(basename $f)
            while ! adb push $f $remote > /dev/null; do
                sleep 1
            done
            adb shell rm $remote
            break
        fi
        sleep 1
    done
    rm $f
}

tail_piped_file() {
    local file="$1"
    local outfile="$2"
    shift 1

    while true; do
        adb_sudo "cat $file" > $outfile
        wait_for_boot
        sleep 1
    done

}

on_each_boot() {
    while true; do
        wait_for_boot
        "$@"
        adb shell # wait for reboot
        sleep 1
    done
}

on_boot() {
    wait_for_boot
    "$@"
}

adb_kill() {
    set -e
    local process="$1"
    shift 1

    local pids=$(adb shell ps \
            | grep "$process" \
            | perl -lane 'print $F[1]')
    if [ ! -z "$pids" ]; then
        echo "kill $pids"
        adb_sudo "kill $@ $pids"
    fi
}

adb_start() {
    local app_name="$1"
    adb shell am start -n $app_name/$app_name.MainActivity
}

keep_cpu_on() {
    local keep_cpu_on_apk="$EXPR/scripts/java/KeepCpuOn/bin/KeepCpuOn.apk"
    local keep_cpu_on_app_name="com.example.keepcpuon2"
    adb install -r $keep_cpu_on_apk
    adb_kill "$keep_cpu_on_app_name"
    adb shell am start -n $keep_cpu_on_app_name/$keep_cpu_on_app_name.MainActivity
}

kill_gui() {
    adb_sudo setprop vold.decrypt trigger_shutdown_framework
}

stop_gui() {
    kill_gui
}
start_gui() {
    adb_sudo setprop vold.decrypt trigger_restart_framework
}

get_pids() {
    local name="$1"
    shift 1
    adb_sudo top -n 1 | grep "$name" | \
        perl -lane 'if (not(@F[3] eq "Z")) { print @F[0]; }'
    echo
}

atrace() {
    local name="$1"
    shift 1
    crun adb_sudo /data/local/tmp/strace -p $(get_pids "$name")
}

agdbserver() {
    set -e
    local name="$1"
    shift 1
    local pid="$(get_pids "$name")"
    if [ -z "$pid" ]; then
        "ERROR: no process named $name"
        exit 1
    fi
    echo "Run gdbclient in a sec..."
    adb forward tcp:5039 tcp:5039
    echo adb_sudo gdbserver :5039 --attach $pid
    adb_sudo gdbserver :5039 --attach $pid
}

agdbclient() {
    set -e
    local name="$1"
    shift 1
    bash -c "
cd $AOSP
echo $AOSP
source build/envsetup.sh
lunch full_mako-userdebug
# export GDB_CMD='ddd --debugger $(which arm-linux-gdb)'
# export GDB_CMD='cgdb -d $(which arm-linux-gdb)'
# export GDB_CMD='gdb -d $(which arm-linux-gdb)'
# export GDB_CMD='$(which arm-linux-gdb)'
gdbclient $name
"
}
