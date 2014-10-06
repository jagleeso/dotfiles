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
    while true; do
        if adb devices | grep --quiet 'device$'; then
            adb devices
            break
        fi
        sleep 1
    done
}
