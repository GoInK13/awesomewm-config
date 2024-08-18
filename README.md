# First install :

`archinstall`

Chose pipewire, awesome+gnome, nvidia proprietary

sudo pacman -Syu
sudo pacman -S nemo nemo-fileroller polkit polkit-gnome kicad gnome-terminal redshift rhythmbox firefox bash-completion --needed base-devel git playerctl wireplumber numlockx
sudo pacman -R nautilus

# Laptop

    cat /etc/X11/xorg.conf.d/30-touchpad.conf
    
```
Section "InputClass"
    Identifier "touchpad"
    Driver "libinput"
    MatchIsTouchpad "on"
    Option "Tapping" "on"
    Option "TappingButtonMap" "lmr"
EndSection
```

    setxkbmap fr oss -option caps:escape
Or (better ): 
    sudo localectl set-x11-keymap fr oss "" "caps:escape"
Will get :

    cat /etc/X11/xorg.conf.d/00-keyboard.conf
    
```
# Written by systemd-localed(8), read by systemd-localed and Xorg. It's
# probably wise not to edit this file manually. Use localectl(1) to
# update this file.
Section "InputClass"
        Identifier "system-keyboard"
        MatchIsKeyboard "on"
        Option "XkbLayout" "fr"
        Option "XkbModel"   "pc105"
        Option "XkbVariant" "oss"
        Option "XkbOptions" "caps:escape"
EndSection
```

## TODO 
https://github.com/lcpz/awesome-copycats : chose themes[7]
`sudo pacman -S zsh`
ohmyz.sh/#install
