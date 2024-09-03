# First install :

`archinstall`

Chose pipewire, awesome+gnome, nvidia proprietary

## Connect wifi

1. `iwctl`
2. `station list` will give a list of all the stations aka simila6to ifconfig in debian
3. `station wlan0 get-networks` i.e search for the network using the wlan0
4. look for the wifi ssd that resembles yours. 
5. `station wlan0 connect SSID_NAME`
6. it will ask for a password or passphrase 
7. CTRL+C 

```
pacman-key --init
pacman-key --populate archlinux
sudo pacman -Syu
sudo pacman -S nemo nemo-fileroller polkit polkit-gnome kicad gnome-terminal redshift rhythmbox firefox bash-completion --needed base-devel git playerctl wireplumber numlockx less
sudo pacman -R nautilus
```

## Reverse A/Q

    sudo vim /usr/share/X11/xkb/symbols/fr

Edit "oss" section.

## Git / SSH

```
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_rsa
```

# Laptop

sudo pacman -S acpi

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

### Wifi

```
nmcli con show
nmtui
```

### Bluetooth

```
sudo systemctl enable --now bluetooth.service
env XDG_CURRENT_DESKTOP=GNOME gnome-control-center
```

## TODO 
https://github.com/lcpz/awesome-copycats : chose themes[7]
`sudo pacman -S zsh`
ohmyz.sh/#install
