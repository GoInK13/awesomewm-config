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

## TODO 
https://github.com/lcpz/awesome-copycats : chose themes[7]
`sudo pacman -S zsh`
ohmyz.sh/#install
