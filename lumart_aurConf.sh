#!/bin/bash
# Script encargado de isntalar las dependencias de repositorios AUR
git clone https://aur.archlinux.org/snapd.git
cd snapd
makepkg -si
sudo systemctl enable --now snapd.socket
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ~
sudo snap install spotify
sudo snap install whatsdesk
yay -S chromium-widevine
yay -S google-chrome