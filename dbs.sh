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
    mkdir -p "/home/$user/src"
    cd "/home/$user/src"
    sudo -u "$name" git clone --depth 1 "https://aur.archlinux.org/yay.git"
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
  sudo -u "$name" git clone --depth 1 "https://github.com/TheLocehiliosan/yadm.git" "/home/$user/src/yadm"
  [ -d "/home/$user/.local/bin" ] || mkdir -p "/home/$user/.local/bin"
  ln -s "/home/$user/src/yadm/yadm" "/home/$user/.local/bin"

  # use yadm to install dots
  yadm clone "https://github.com/ObsoleteAlbatross/dotfiles"
}

# === The meat ===
# Pre checks
echo -e "Please make sure the following\n1) Run this as root\n2)Internet connection\n3)Packages are updated"
echo "Are you sure you want to proceed?"
read input
[ input="yes" ] || throw "User exited"
echo "Choose a user to install for (dotfiles user specific, pkgs system wide)"
read user
id "$user" > /dev/null 2>&1 || throw "$user is an invalid user"

cd "/home/$user"

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
chsh -s /bin/zsh $name >/dev/null 2>&1
sudo -u "$name" mkdir -p "/home/$name/.cache/"
sudo -u "$name" touch "/home/$name/.cache/shell_history"
mkdir -p "/home/$user/.config/zsh/plugins"
sudo -u "$name" git clone --depth 1 "https://github.com/zdharma/fast-syntax-highlighting" "/home/$user/.config/zsh/plugins/fsh"
sudo -u "$name" git clone --depth 1 "https://github.com/zsh-users/zsh-completions.git" "/home/$user/.config/zsh/plugins/zsh-completions"
rm -f "/home/$user/.zcompdump"
compinit

# Setup vim
if command -v nvim >/dev/null 2>&1; then
  echo "Bootstraping nvim"
  nvim '+PlugUpdate' '+PlugClean!' '+PlugUpdate' '+qall'
fi

# Install universal ctags
sudo -u "$name" git clone --depth 1 "https://github.com/universal-ctags/ctags" "/home/$user/src"
cd "/home/$user/src/ctags"
sudo -u "$name" /home/$user/src/ctags/autogen.sh
sudo -u "$name" /home/$user/src/ctags/configure --prefix="/home/$user/.local/bin"
sudo -u "$name" make
sudo -u "$name" make install

# Install st
sudo -u "$name" git clone --depth 1 "https://github.com/LukeSmithxyz/st" "/home/$user/src"
cd "/home/$user/src/st"
make install
ln -s "/home/$user/src/st/st" "/home/$user/.local/bin/sh"

echo "Done!"
