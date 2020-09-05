#!/bin/sh

# === Pre install setup ===

if type xbps-install >/dev/null 2>&1; then
  distro="void"
  pkgfile="https://raw.githubusercontent.com/ObsoleteAlbatross/dbs/master/pkgs-void.csv"
  installpkg() { xbps-install -y "$1" > /dev/null 2>&1 ;}
else
  distro="arch"
  pkgfile="https://raw.githubusercontent.com/ObsoleteAlbatross/dbs/master/pkgs-arch.csv"
  installpkg() { pacman --noconfirm -S "$1" > /dev/null 2>&1 ;}
fi

# === Helpers ===
throw() {
  printf "ERROR THROWN:\\n%s\\n" "$1"
  exit
}

installyay() {
  # install yay if it doesn't exist
  [ -f "/usr/bin/yay" ] || {
    echo "Installing 'yay' (aur helper)"
    cd "/home/$name/src"
    sudo -u "$name" git clone "https://aur.archlinux.org/yay.git" > /dev/null 2>&1
    cd yay
    sudo -u "$name" makepkg --noconfirm -si > /dev/null 2>&1
  }
}


installpkgwrap() {
  echo "Installing '$1' ($n of $total)"
  installpkg "$1"
}

installcsv() {
  echo "Installing through package manager"
  curl -Ls "$pkgfile" | sed '/^#/d' > /tmp/pkgs.csv
  total=$(wc -l < /tmp/pkgs.csv)
  while IFS=, read -r tag program; do
  	n=$((n+1))
  	case "$tag" in
      *) installpkgwrap "$program" ;;
    esac
  done < /tmp/pkgs.csv
}

installdots() {
  # install 'yadm'
  sudo -u "$name" git clone "https://github.com/TheLocehiliosan/yadm.git" "/home/$name/src/yadm" > /dev/null 2>&1
  [ -d "/home/$name/.local/bin" ] || mkdir -p "/home/$name/.local/bin"
  ln -s "/home/$name/src/yadm/yadm" "/home/$name/.local/bin"

  # use yadm to install dots
  sudo -u "$name" "/home/$name/.local/bin/yadm" clone "https://github.com/ObsoleteAlbatross/dotfiles"
}

# === The meat ===
# Pre checks
echo -e "Please make sure the following\n1) Run this as root\n2)Internet connection\n3)Packages are updated"
echo "Are you sure you want to proceed?"
read input
[ input="yes" ] || throw "User exited"
echo "Choose a user to install for (dotfiles user specific, pkgs system wide)"
read user
id "$name" > /dev/null 2>&1 || throw "$name is an invalid user"

cd "/home/$name"

# If arch, get yay (aur helper)
[ "$distro"="arch" ] && installyay

# Install from distro pkg csv
installcsv

# Install dotfiles
installdots

# Remove pesky beep
rmmod pcspkr
echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf

# Setup zsh
echo "Installing zsh"
chsh -s /bin/zsh $name >/dev/null 2>&1
sudo -u "$name" mkdir -p "/home/$name/.cache/"
sudo -u "$name" touch "/home/$name/.cache/shell_history"
mkdir -p "/home/$name/.config/zsh/plugins"
sudo -u "$name" git clone "https://github.com/zdharma/fast-syntax-highlighting" "/home/$name/.config/zsh/plugins/fsh" > /dev/null 2>&1
sudo -u "$name" git clone "https://github.com/zsh-users/zsh-completions.git" "/home/$name/.config/zsh/plugins/zsh-completions" > /dev/null 2>&1
rm -f "/home/$name/.zcompdump"
compinit

# Setup nvim
if command -v nvim >/dev/null 2>&1; then
  echo "Bootstraping nvim"
  sudo -u "$name" nvim '+PlugUpdate' '+PlugClean!' '+PlugUpdate' '+qall'
fi

# Install universal ctags
echo "Installing universal ctags"
sudo -u "$name" git clone "https://github.com/universal-ctags/ctags" "/home/$name/src/ctags" > /dev/null 2>&1
cd "/home/$name/src/ctags"
sudo -u "$name" /home/$name/src/ctags/autogen.sh
sudo -u "$name" /home/$name/src/ctags/configure --prefix="/home/$name/.local/bin"
sudo -u "$name" make
sudo -u "$name" make install

# Install st
echo "Installing st"
sudo -u "$name" git clone "https://github.com/LukeSmithxyz/st" "/home/$name/src/st" > /dev/null 2>&1
cd "/home/$name/src/st"
make install
ln -s "/home/$name/src/st/st" "/home/$name/.local/bin/sh"

echo "Done!"
