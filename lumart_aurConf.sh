cd /tmp
gpg --recv-key 465022E743D71E39
git clone https://aur.archlinux.org/aurman.git
cd aurman
makepkg -si
cd ~

aurman -S spotify
aurman -S whatsapp-nativefier-dark

