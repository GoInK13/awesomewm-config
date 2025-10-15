#!/bin/sh

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}
run_dark() {
    if ! pgrep -f "$1"; then
        GTK_THEME=Adwaita:dark "$@" &
    fi
}
sleep 1
#run_dark "rhythmbox"
run "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
run "numlockx"
run "dropbox"
run "unclutter"
if ! pgrep -f "kitty --class ncmpcpp"; then
   kitty --class ncmpcpp -e ncmpcpp &
fi
setxkbmap fr oss -option caps:escape
xset r rate 300 25
