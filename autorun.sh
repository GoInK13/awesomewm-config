#!/bin/sh

run() {
    if ! pgrep -f "$*"; then
        "$@" &
    fi
}
run_dark() {
    if ! pgrep -f "$*"; then
        GTK_THEME=Adwaita:dark "$@" &
    fi
}
sleep 1
#run_dark "rhythmbox"
run /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
run numlockx
run dropbox
run unclutter
if ! pgrep -f "kitty --class ncmpcpp"; then
   kitty --class ncmpcpp -e ncmpcpp &
fi
HOUR=$(date +%H)
DAY_OF_WEEK=$(date +%u)
if [ "$DAY_OF_WEEK" -ge 1 ] && [ "$DAY_OF_WEEK" -le 5 ]; then
  if [ "$HOUR" -ge 8 ] && [ "$HOUR" -le 18 ]; then
    run /usr/lib/firefox/firefox -P Discord
    sleep 1
    run /usr/lib/firefox/firefox -P default-release
    run /home/pierrot/Documents/Cosma/softs/Vesktop-1.6.5.AppImage
  fi
fi
setxkbmap -I/etc/X11/xkb -print fr oss_pierrot -option caps:escape | xkbcomp -w 0 -I/etc/X11/xkb - "$DISPLAY"
xset r rate 300 25
