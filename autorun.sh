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
run "unclutter"
setxkbmap fr oss -option caps:escape
xset r rate 300 25
