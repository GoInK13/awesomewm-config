#!/bin/sh

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}
sleep 1
run "rhythmbox"
run "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
run "numlockx"
run "dropbox"
setxkbmap fr oss -option caps:escape
run "unclutter"
