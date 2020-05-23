#!/bin/bash
# Script encargado de instalar las dependencias de la interfaz Awesome WM
sudo pacman-mirrors -g
sudo pacman -Syyu
sudo pacman -S musescore code alacritty opera awesome discord chromium obs-studio steam ranger git xfce4-screenshooter npm dragon 
sudo pacman -S peek lxappearance xdg-utils ffmpegthumbnailer wildmidi cmus mpv

git config --global user.name "LumartCh"

sudo npm install -g alacritty-theme-switch

sudo pip install Xlib
sudo pip install ueberzug

lxappearance
